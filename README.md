# pilgrimage-pfe
# Sacred Journey Hub — Intelligent Pilgrimage Management Platform

## Overview
Sacred Journey Hub is a multi-tenant SaaS platform designed to help Hajj and Umrah travel agencies manage pilgrims, guides, and travel groups in one structured system.

The platform supports four user roles:

- Administrator
- Agency
- Guide
- Pilgrim

The web application is used by super administrators and agencies. The mobile application, built with Flutter, is intended for guides and pilgrims in the field.

## Motivation
Hajj and Umrah coordination often depends on manual paperwork, scattered communication, and fragile operational follow-up. This project proposes a more reliable digital workflow where agencies can manage their operations clearly, administrators keep visibility over agency lifecycle status, and users interact through role-specific interfaces.

## Tech Stack

| Layer | Technology |
|---|---|
| Backend API | Node.js, Express, TypeScript |
| ORM | Prisma |
| Database | PostgreSQL |
| Authentication | JWT access token + refresh token |
| Web Frontend | Vue 3 (Composition API) |
| Mobile | Flutter |
| Email | Nodemailer |
| Password Hashing | bcrypt |

## Project Structure

```text
pilgrimage-pfe/
├── backend/
│   ├── src/
│   │   ├── app.ts
│   │   ├── server.ts
│   │   ├── config/
│   │   │   ├── env.ts
│   │   │   └── prisma.ts
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   │   ├── auth.middleware.ts
│   │   │   │   ├── auth.router.ts
│   │   │   │   └── auth.service.ts
│   │   │   ├── admin/
│   │   │   │   ├── admin.router.ts
│   │   │   │   └── admin.service.ts
│   │   │   └── agences/
│   │   │       ├── agences.router.ts
│   │   │       ├── agences.service.ts
│   │   │       ├── guide/
│   │   │       ├── groupes/
│   │   │       └── pelerin/
│   │   └── utils/
│   │       ├── mailer.utils.ts
│   │       └── token.utils.ts
│   └── prisma/
│
├── frontend-web/
│   └── piligrim-web/
│       ├── src/
│       │   ├── assets/
│       │   ├── components/
│       │   ├── composables/
│       │   ├── content/
│       │   ├── features/
│       │   │   ├── admin/
│       │   │   └── agence/
│       │   ├── router/
│       │   ├── services/
│       │   ├── views/
│       │   ├── App.vue
│       │   └── main.js
│
└── mobile/
    └── lib/
```

## Backend Setup

### Prerequisites
- Node.js >= 18
- PostgreSQL >= 14
- npm

### Installation
```bash
cd backend
npm install
```

### Environment
Create a `.env` file in `backend/` and configure at least:

```env
DATABASE_URL=
JWT_SECRET=
REFRESH_TOKEN_SECRET=
MAIL_HOST=
MAIL_PORT=
MAIL_USER=
MAIL_PASS=
MAIL_FROM=
FRONTEND_URL=
```

### Database
```bash
npx prisma migrate dev
npx prisma generate
```

If a seed script is available:

```bash
npx prisma db seed
```

### Run the server
```bash
npm run dev
```

Backend runs on:

```text
http://localhost:3000
```

## Web Frontend Setup

### Installation
```bash
cd frontend-web/piligrim-web
npm install
```

### Environment
Create a `.env` file in `frontend-web/piligrim-web/`:

```env
VITE_API_URL=http://localhost:3000
```

### Run the frontend
```bash
npm run dev
```

Frontend runs on:

```text
http://localhost:5173
```

## Mobile Setup

The Flutter mobile app is located in:

```text
mobile/
```

Typical commands:

```bash
cd mobile
flutter pub get
flutter run
```

## Authentication Flow

The platform uses:

- Access token for authenticated requests
- Refresh token for session renewal
- Password setup flow for account activation and password reset
- Email-based activation for created guides and pilgrims

## API Reference

All protected endpoints require:

```http
Authorization: Bearer <token>
```

### Authentication — `/auth`

| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/auth/login` | Public | Login and return access + refresh tokens |
| POST | `/auth/signup` | Public | Agency self-registration |
| POST | `/auth/refresh` | Public | Refresh access token |
| POST | `/auth/logout` | Authenticated | Logout and invalidate refresh token |
| GET | `/auth/me` | Authenticated | Get current authenticated user |
| POST | `/auth/forgot-password` | Public | Send password reset email |
| POST | `/auth/set-password` | Public | Set password from token |
| POST | `/auth/verify-activation-token` | Public | Verify activation token |

### Admin — `/admin`

| Method | Endpoint | Description |
|---|---|---|
| GET | `/admin/agences` | List agencies |
| GET | `/admin/agences/:id` | Get agency details |
| PATCH | `/admin/agences/:id/approve` | Approve agency |
| PATCH | `/admin/agences/:id/reject` | Reject agency |
| PATCH | `/admin/agences/:id/suspend` | Suspend agency |
| DELETE | `/admin/agences/:id` | Delete agency |

### Agency Profile — `/agence/profile`

| Method | Endpoint | Description |
|---|---|---|
| GET | `/agence/profile` | Get agency profile |
| PATCH | `/agence/profile` | Update agency profile |

### Pilgrims — `/agence/pelerins`

| Method | Endpoint | Description |
|---|---|---|
| POST | `/agence/pelerins` | Create pilgrim |
| GET | `/agence/pelerins` | List pilgrims |
| GET | `/agence/pelerins/:id` | Get pilgrim details |
| PATCH | `/agence/pelerins/:id` | Update pilgrim |
| DELETE | `/agence/pelerins/:id` | Delete pilgrim |

### Guides — `/agence/guides`

| Method | Endpoint | Description |
|---|---|---|
| POST | `/agence/guides` | Create guide |
| GET | `/agence/guides` | List guides |
| GET | `/agence/guides/available` | List available guides |
| GET | `/agence/guides/:id` | Get guide details |
| GET | `/agence/guides/:id/stats` | Get guide statistics |
| PATCH | `/agence/guides/:id` | Update guide |
| DELETE | `/agence/guides/:id` | Delete guide |
| POST | `/agence/guides/:id/resend-activation` | Resend activation email |

### Groups — `/agence/groupes`

| Method | Endpoint | Description |
|---|---|---|
| POST | `/agence/groupes` | Create group |
| GET | `/agence/groupes` | List groups |
| GET | `/agence/groupes/:id` | Get group details |
| PATCH | `/agence/groupes/:id` | Update group |
| DELETE | `/agence/groupes/:id` | Delete group |
| POST | `/agence/groupes/:id/pelerins` | Assign pilgrim to group |
| DELETE | `/agence/groupes/:id/pelerins/:pelerinId` | Remove pilgrim from group |

