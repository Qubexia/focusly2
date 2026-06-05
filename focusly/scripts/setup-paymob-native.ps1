# Installs Paymob native SDK binaries required by the paymob Flutter plugin (v1.2.0).
# Android: Paymob-SDK 1.8.1 AAR
# iOS:     PaymobSDK 1.3.3 xcframework
#
# Usage:
#   .\scripts\setup-paymob-native.ps1
#   .\scripts\setup-paymob-native.ps1 -OpenDownloads
#   .\scripts\setup-paymob-native.ps1 -AndroidSource "C:\Downloads\PaymobAndroidSDK1.8.1"
#   .\scripts\setup-paymob-native.ps1 -IosSource "C:\Downloads\PaymobSDK 1.3.3"

param(
    [string]$AndroidSource = "",
    [string]$IosSource = "",
    [switch]$OpenDownloads,
    [switch]$SkipBuildCheck
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$AndroidAarTarget = Join-Path $Root "android\libs\com\paymob\sdk\Paymob-SDK\1.8.1\Paymob-SDK-1.8.1.aar"
$IosFrameworkTarget = Join-Path $Root "ios\Frameworks\PaymobSDK.xcframework"

$AndroidSharePoint = "https://paymob-my.sharepoint.com/:f:/p/ahmedsobhy/EjQrdOdzUzhIqlQmcsE9Hg0BOVjJYOu2BMGRClGVEa9dJA?e=hfFnnI"
$IosSharePoint = "https://paymob-my.sharepoint.com/:f:/p/mahmoudyoussef/El9q1ULaxcBFkQurwvXkZQEBY9S-6dwhWL9xXQgjEnGPBQ?e=0sKgCf"

function Ensure-MavenMetadata {
    $exampleLibs = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev\paymob-1.2.0\example\android\libs"
    if (-not (Test-Path $exampleLibs)) {
        Write-Host "Run 'flutter pub get' first so the paymob package is in pub cache." -ForegroundColor Yellow
        return
    }
    $dst = Join-Path $Root "android\libs"
    New-Item -ItemType Directory -Force -Path (Split-Path $AndroidAarTarget) | Out-Null
    Copy-Item (Join-Path $exampleLibs "com\paymob\sdk\Paymob-SDK\1.8.1\Paymob-SDK-1.8.1.pom") (Split-Path $AndroidAarTarget) -Force
    Copy-Item (Join-Path $exampleLibs "com\paymob\sdk\Paymob-SDK\maven-metadata.xml") (Join-Path $dst "com\paymob\sdk\Paymob-SDK\") -Force
}

function Find-FileRecursive {
    param([string]$RootPath, [string[]]$Names)
    if (-not (Test-Path $RootPath)) { return $null }
    foreach ($name in $Names) {
        $hit = Get-ChildItem -Path $RootPath -Recurse -Filter $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Install-AndroidAar {
    param([string]$SourcePath)
    $aar = if (Test-Path $SourcePath -PathType Leaf) { $SourcePath } else { Find-FileRecursive $SourcePath @("Paymob-SDK-1.8.1.aar", "*.aar") }
    if (-not $aar) { throw "Could not find Paymob-SDK-1.8.1.aar under: $SourcePath" }
    New-Item -ItemType Directory -Force -Path (Split-Path $AndroidAarTarget) | Out-Null
    Copy-Item $aar $AndroidAarTarget -Force
    Write-Host "Android AAR installed -> $AndroidAarTarget" -ForegroundColor Green
}

function Install-IosFramework {
    param([string]$SourcePath)
    $framework = if (Test-Path $SourcePath -PathType Container -and (Split-Path $SourcePath -Leaf) -eq "PaymobSDK.xcframework") {
        $SourcePath
    } else {
        $found = Find-FileRecursive $SourcePath @("PaymobSDK.xcframework")
        if ($found) { $found } else { $null }
    }
    if (-not $framework) { throw "Could not find PaymobSDK.xcframework under: $SourcePath" }
    New-Item -ItemType Directory -Force -Path (Split-Path $IosFrameworkTarget) | Out-Null
    if (Test-Path $IosFrameworkTarget) { Remove-Item -Recurse -Force $IosFrameworkTarget }
    Copy-Item -Recurse $framework $IosFrameworkTarget
    Write-Host "iOS xcframework installed -> $IosFrameworkTarget" -ForegroundColor Green
}

function Prompt-ForSource {
    param([string]$Label, [string[]]$Hints)
    Write-Host ""
    Write-Host "$Label" -ForegroundColor Cyan
    foreach ($h in $Hints) { Write-Host "  - $h" }
    $path = Read-Host "Paste folder path (or Enter to skip)"
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    return $path.Trim('"')
}

Ensure-MavenMetadata

$needAndroid = -not (Test-Path $AndroidAarTarget)
$needIos = -not (Test-Path $IosFrameworkTarget)

if (-not $needAndroid -and -not $needIos) {
    Write-Host "Paymob native SDKs already installed." -ForegroundColor Green
} else {
    if ($OpenDownloads -or ($needAndroid -and -not $AndroidSource) -or ($needIos -and -not $IosSource)) {
        Write-Host "Opening Paymob SharePoint download folders in your browser..." -ForegroundColor Yellow
        if ($needAndroid) { Start-Process $AndroidSharePoint }
        if ($needIos) { Start-Process $IosSharePoint }
        Write-Host ""
        Write-Host "Download and extract:" -ForegroundColor Yellow
        Write-Host "  Android -> PaymobAndroidSDK1.8.1 (contains Paymob-SDK-1.8.1.aar)"
        Write-Host "  iOS     -> PaymobSDK 1.3.3 (contains PaymobSDK.xcframework)"
    }

    if ($needAndroid) {
        if (-not $AndroidSource) {
            $AndroidSource = Prompt-ForSource "Android SDK folder" @(
                "Folder that contains Paymob-SDK-1.8.1.aar",
                "Example: $env:USERPROFILE\Downloads\PaymobAndroidSDK1.8.1"
            )
        }
        if ($AndroidSource) { Install-AndroidAar $AndroidSource }
    }

    if ($needIos) {
        if (-not $IosSource) {
            $IosSource = Prompt-ForSource "iOS SDK folder" @(
                "Folder that contains PaymobSDK.xcframework",
                "Example: $env:USERPROFILE\Downloads\PaymobSDK 1.3.3"
            )
        }
        if ($IosSource) { Install-IosFramework $IosSource }
    }
}

Write-Host ""
Write-Host "Status:" -ForegroundColor Cyan
Write-Host "  Android AAR: $(if (Test-Path $AndroidAarTarget) { 'OK' } else { 'MISSING' })"
Write-Host "  iOS xcframework: $(if (Test-Path $IosFrameworkTarget) { 'OK' } else { 'MISSING' })"

if (-not $SkipBuildCheck -and (Test-Path $AndroidAarTarget)) {
    Write-Host ""
    Write-Host "Running flutter build apk --debug to verify Android..." -ForegroundColor Cyan
    Push-Location $Root
    try {
        flutter build apk --debug
        Write-Host "Android build OK." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

if (-not (Test-Path $AndroidAarTarget) -or -not (Test-Path $IosFrameworkTarget)) {
    Write-Host ""
    Write-Host "Re-run after downloading SDKs:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup-paymob-native.ps1 -AndroidSource `"<folder>`" -IosSource `"<folder>`""
    exit 1
}
