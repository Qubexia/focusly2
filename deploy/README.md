# Zakerly Server Deployment (zakerlyai.tech)

## Architecture

| URL | Service |
|-----|---------|
| `https://zakerlyai.tech/` | Admin dashboard (static SPA) |
| `https://zakerlyai.tech/v1/` | NestJS API |
| `https://zakerlyai.tech/docs` | Swagger UI |
| `https://zakerlyai.tech/uploads/` | User uploads (avatars), served by the API from `focaly-backend/storage/` |

## Stack

- **nginx** — reverse proxy + SSL (Let's Encrypt)
- **PM2** — `focaly-api` + `focaly-worker`
- **MongoDB** — local `mongodb://localhost:27017/focaly`
- **Redis** — local `redis://localhost:6379`

## Commands

```bash
# Rebuild & restart after code changes
cd focaly-backend && npm run build && pm2 restart focaly-api focaly-worker
cd focaly-admin && npm run build   # nginx serves dist/ automatically

# Apply nginx changes (needed after editing deploy/nginx/zakerlyai.tech.conf)
cp deploy/nginx/zakerlyai.tech.conf /etc/nginx/sites-available/zakerlyai.tech
nginx -t && systemctl reload nginx

# Verify uploads are reachable (must NOT return text/html)
curl -sI https://zakerlyai.tech/uploads/avatars/ | head -3

# Logs
pm2 logs focaly-api
pm2 logs focaly-worker

# SSL renewal (automatic via certbot timer)
certbot renew --dry-run

# Create admin user
cd focaly-backend && npm run promote-admin -- you@example.com
```

## Config files

- `deploy/nginx/zakerlyai.tech.conf` — nginx site (SSL blocks added by certbot)
- `deploy/ecosystem.config.cjs` — PM2 process definitions
- `focaly-backend/.env` — backend secrets & production settings
- `focaly-admin/.env` — `VITE_API_URL` (baked in at build time)
