# Focaly Admin Dashboard

React + Vite + shadcn/ui admin panel for the Focaly platform. Talks to the NestJS
backend's `/v1/admin/*` API (admin-only, guarded by `RolesGuard`).

## Features

- **Auth** — email/password login, admin-role enforced, JWT with transparent refresh.
- **Overview** — KPIs (users, premium, DAU/MAU, revenue, AI cost) + signups chart.
- **Users** — search/filter, edit role & plan, ban/unban, delete, manage sessions.
- **Subscriptions & Revenue** — provider/status filters, manual extend/cancel.
- **Analytics** — plan distribution, AI tokens, engagement & subscription breakdowns.
- **Notifications** — broadcast in-app (and optional FCM push) to all/premium/free.
- **Content** — browse subjects, planned items, and AI jobs across all users.

## Setup

```bash
cd focaly-admin
npm install
cp .env.example .env          # set VITE_API_URL (default http://localhost:5000/v1)
npm run dev                   # http://localhost:5173
```

## Creating an admin

The dashboard only lets `role: 'admin'` users in. Promote an existing account from
the backend:

```bash
cd ../focaly-backend
npm run promote-admin -- you@example.com
```

## Scripts

- `npm run dev` — start the Vite dev server.
- `npm run build` — type-check and build for production.
- `npm run preview` — preview the production build.
