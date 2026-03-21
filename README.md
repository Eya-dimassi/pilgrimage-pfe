# pilgrimage-pfe
# SmartHajj — Intelligent Pilgrimage Management Platform

 
---
 
## Overview
 
SmartHajj is a multi-tenant SaaS platform designed to assist Hajj and Umrah travel agencies in managing their pilgrims, guides, and travel groups. The system addresses the operational complexity faced by travel agencies during the pilgrimage season by centralising pilgrim coordination, group organisation, and real-time communication into a single, role-aware application.
 
The platform serves four distinct user roles — Super Administrator, Agency, Guide, and Pilgrim — each accessing a tailored interface suited to their responsibilities. The web interface targets agencies and administrators, while the mobile application (Flutter) is intended for guides and pilgrims in the field.
 
### Motivation
 
Hajj and Umrah coordination currently relies heavily on manual processes, paper documentation, and fragmented communication channels. This project proposes a structured digital alternative that enforces accountability at every level: agencies cannot assign inactive guides, pilgrims cannot be silently removed without audit, and administrators maintain full visibility over agency lifecycle status.
 
---
 
## Tech Stack
 
| Layer | Technology |
|---|---|
| Backend API | Node.js · Express · TypeScript |
| ORM | Prisma |
| Database | PostgreSQL |
| Authentication | JWT (15 min) + Refresh Tokens (30 days) |
| Web Frontend | Vue.js 3 (Composition API) |
| Mobile | Flutter *(Sprints 2–4)* |
| Email | Nodemailer |
| Password Hashing | bcrypt |
 
---
 
## Project Structure
 
```
pilgrimage-pfe/
├── backend/
│   ├── src/
│   │   ├── config/          # Prisma client, env validation
│   │   ├── modules/
│   │   │   ├── auth/        # Login, register, refresh, password reset
│   │   │   ├── admin/       # Agency approval, suspension, rejection
│   │   │   └── agences/
│   │   │       ├── agence.service.ts
│   │   │       ├── agences.router.ts
│   │   │       ├── pelerin/
│   │   │       ├── guide/
│   │   │       └── groupes/
│   │   └── utils/           # Mailer, token utilities
│   └── generated/prisma/    # Prisma client output
└── frontend/
    └── src/
        ├── views/           # DashboardView, AdminView, SetPasswordView
        ├── components/
        │   └── dashboard/   # DashPelerins, DashGuides, DashGroupes, DashSidebar, DashTopbar
        ├── composables/     # useAgenceData, useModal
        ├── services/        # api.js (Axios), auth.service.js
        ├── router/
        └── assets/          # dashboard.css
```
 
---
 
## Setup & Installation
 
### Prerequisites
 
- Node.js >= 18
- PostgreSQL >= 14
- npm 
 
### Backend
 
```bash
cd backend
npm install
 
# Configure environment
cp .env.example .env
# Fill in: DATABASE_URL, JWT_SECRET, REFRESH_TOKEN_SECRET,
#          MAIL_HOST, MAIL_PORT, MAIL_USER, MAIL_PASS, MAIL_FROM,
#          FRONTEND_URL
```
 
Run database migrations and generate Prisma client:
 
```bash
npx prisma migrate dev
npx prisma generate
```
 
Start the development server:
 
```bash
npm run dev
# Server runs on http://localhost:3000
```
 
Seed a Admin account (if a seed script is present):
 
```bash
npx prisma db seed
```
 
### Frontend
 
```bash
cd frontend-web
npm install
 
# Configure environment
cp .env.example .env
# Fill in: VITE_API_URL=http://localhost:3000
```
 
Start the development server:
 
```bash
npm run dev
# App runs on http://localhost:5173
```
 
---
 
## API Endpoints Reference
 
All protected endpoints require a valid JWT in the `Authorization: Bearer <token>` header.
 
### Authentication — `/auth`
 
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/auth/login` | Public | Login, returns access + refresh tokens |
| POST | `/auth/register` | Public | Agency self-registration (status: PENDING) |
| POST | `/auth/refresh` | Public | Rotate refresh token, mint new access token |
| POST | `/auth/logout` | Auth | Invalidate refresh token |
| GET | `/auth/me` | Auth | Get current authenticated user |
| POST | `/auth/forgot-password` | Public | Send password reset email |
| POST | `/auth/set-password` | Public | Set password via token (activation + reset) |
| GET | `/auth/verify-token/:token` | Public | Verify activation token validity |
 
### Admin — `/admin` *(SUPER_ADMIN only)*
 
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/agences` | List all agencies with status |
| PATCH | `/admin/agences/:id/approve` | Approve agency, activate account, send email |
| PATCH | `/admin/agences/:id/reject` | Reject agency |
| PATCH | `/admin/agences/:id/suspend` | Suspend agency, invalidate all sessions |
 
### Agency Profile — `/agence` *(AGENCE only)*
 
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/agence/profile` | Get agency profile |
| PATCH | `/agence/profile` | Update agency profile (name, address, phone, website) |
 
### Pilgrims — `/agence/pelerins` *(AGENCE only)*
 
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/agence/pelerins` | Create pilgrim, send activation email |
| GET | `/agence/pelerins` | List all pilgrims |
| GET | `/agence/pelerins/:id` | Get pilgrim by ID |
| PATCH | `/agence/pelerins/:id` | Update pilgrim |
| DELETE | `/agence/pelerins/:id` | Delete pilgrim |
 
### Guides — `/agence/guides` *(AGENCE only)*
 
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/agence/guides` | Create guide, send activation email |
| GET | `/agence/guides` | List all guides |
| GET | `/agence/guides/available` | List guides not assigned to any group |
| GET | `/agence/guides/:id` | Get guide by ID |
| GET | `/agence/guides/:id/stats` | Get guide statistics |
| PATCH | `/agence/guides/:id` | Update guide |
| DELETE | `/agence/guides/:id` | Delete guide (only if unassigned) |
| POST | `/agence/guides/:id/resend-activation` | Resend activation email |
 
### Groups — `/agence/groupes` *(AGENCE only)*
 
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/agence/groupes` | Create group |
| GET | `/agence/groupes` | List all groups with pilgrims and guide |
| GET | `/agence/groupes/:id` | Get group details |
| PATCH | `/agence/groupes/:id` | Update group |
| DELETE | `/agence/groupes/:id` | Delete group |
| POST | `/agence/groupes/:id/pelerins` | Assign pilgrim to group |
| DELETE | `/agence/groupes/:id/pelerins/:pelerinId` | Remove pilgrim from group |
 
---
