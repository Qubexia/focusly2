<#
.SYNOPSIS
  Exposes the local backend over a public HTTPS URL so Paymob's webhook +
  redirect callbacks can reach your machine during development.

.DESCRIPTION
  Uses Cloudflare's free "quick tunnel" (no signup/login required). It:
    1. Downloads cloudflared.exe into ./tools the first time (gitignored).
    2. Opens a tunnel to http://localhost:<Port>.
    3. Writes the assigned public URL into .env as PUBLIC_API_BASE_URL.
    4. Prints the exact callback URLs to paste into the Paymob dashboard.

  The quick-tunnel URL changes every run, so re-run this and re-paste the
  callback URLs into Paymob whenever you restart it. For a stable URL, use a
  named Cloudflare tunnel or an ngrok reserved domain instead.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\paymob-tunnel.ps1

.NOTES
  Start the backend (port 5000) BEFORE running this. Restart the backend AFTER
  it updates .env so the new PUBLIC_API_BASE_URL is loaded. Keep the window
  open — closing it stops the tunnel.
#>
param(
  [int]$Port = 5000
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root 'tools'
$exe = Join-Path $tools 'cloudflared.exe'
$envFile = Join-Path $root '.env'

if (-not (Test-Path $exe)) {
  Write-Host 'cloudflared not found — downloading (~25 MB)...' -ForegroundColor Yellow
  New-Item -ItemType Directory -Force -Path $tools | Out-Null
  Invoke-WebRequest `
    -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' `
    -OutFile $exe
}

Write-Host "Starting Cloudflare tunnel to http://localhost:$Port ..." -ForegroundColor Cyan

$errLog = Join-Path $env:TEMP 'Zakerly-cloudflared.err.log'
$outLog = Join-Path $env:TEMP 'Zakerly-cloudflared.out.log'
foreach ($f in @($errLog, $outLog)) { if (Test-Path $f) { Remove-Item $f -Force } }

$proc = Start-Process -FilePath $exe `
  -ArgumentList @('tunnel', '--no-autoupdate', '--url', "http://localhost:$Port") `
  -RedirectStandardError $errLog -RedirectStandardOutput $outLog -PassThru -NoNewWindow

# cloudflared prints the assigned URL to stderr; poll for it.
$publicUrl = $null
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Seconds 1
  foreach ($f in @($errLog, $outLog)) {
    if (Test-Path $f) {
      $m = Select-String -Path $f -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($m) { $publicUrl = $m.Matches[0].Value; break }
    }
  }
  if ($publicUrl) { break }
}

if (-not $publicUrl) {
  Write-Host 'Could not detect the tunnel URL. Last cloudflared output:' -ForegroundColor Red
  if (Test-Path $errLog) { Get-Content $errLog -Tail 25 }
  if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue }
  exit 1
}

Write-Host "Public URL: $publicUrl" -ForegroundColor Green

# Add or replace PUBLIC_API_BASE_URL in .env (BOM-free, so dotenv parses line 1).
$lines = Get-Content $envFile
if ($lines -match '^PUBLIC_API_BASE_URL=') {
  $lines = $lines -replace '^PUBLIC_API_BASE_URL=.*', "PUBLIC_API_BASE_URL=$publicUrl"
} else {
  $lines += "PUBLIC_API_BASE_URL=$publicUrl"
}
$content = ($lines -join "`n") + "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($envFile, $content, $utf8NoBom)
Write-Host 'Updated PUBLIC_API_BASE_URL in .env' -ForegroundColor Green

Write-Host ''
Write-Host '== Paste these into the Paymob dashboard (Integration -> Callbacks) ==' -ForegroundColor Cyan
Write-Host "  Transaction Processed (webhook): $publicUrl/v1/subscription/paymob/webhook"
Write-Host "  Transaction Response (redirect): $publicUrl/v1/subscription/paymob/redirect"
Write-Host ''
Write-Host 'NEXT: restart the backend so it loads the new PUBLIC_API_BASE_URL.' -ForegroundColor Yellow
Write-Host 'Keep this window open — closing it stops the tunnel.' -ForegroundColor Yellow
Write-Host ''

Wait-Process -Id $proc.Id
