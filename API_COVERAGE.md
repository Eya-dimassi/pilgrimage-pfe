# API Coverage Map

This file maps the current backend endpoints to the clients that already use them.

## Backend Surface

### Health

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `GET /health` | Yes | No | No | Optional diagnostics endpoint. |

### Auth

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `POST /auth/login` | Yes | Yes | Yes | Implemented in both clients. |
| `POST /auth/signup` | Yes | Yes | No | Agency registration is web-only for now. |
| `POST /auth/logout` | Yes | Yes | Yes | Implemented in both clients. |
| `POST /auth/refresh` | Yes | Yes | Yes | Web already used it, mobile now uses it in Dio refresh flow. |
| `POST /auth/forgot-password` | Yes | Yes | Yes | Implemented in both clients. |
| `POST /auth/set-password` | Yes | Yes | No | Mobile has no set-password flow yet. |
| `POST /auth/verify-activation-token` | Yes | Yes | No | Mobile has no activation flow yet. |
| `GET /auth/me` | Yes | Yes | Yes | Implemented in both clients. |
| `PATCH /auth/me` | Yes | Yes | Yes | Implemented in both clients. |
| `POST /auth/family-signup` | Yes | No | Yes | Mobile-only at the moment. |
| `GET /auth/family-links` | Yes | No | Yes | Mobile family flow uses it. |
| `POST /auth/family-links` | Yes | No | Yes | Mobile family flow uses it. |

### Admin

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `GET /admin/agences` | Yes | Yes | No | Admin web dashboard. |
| `GET /admin/agences/:id` | Yes | Yes | No | Admin web detail view. |
| `PATCH /admin/agences/:id/approve` | Yes | Yes | No | Admin web action. |
| `PATCH /admin/agences/:id/reject` | Yes | Yes | No | Admin web action. Backend still needs to persist `reason`. |
| `PATCH /admin/agences/:id/suspend` | Yes | Yes | No | Admin web action. |
| `DELETE /admin/agences/:id` | Yes | Yes | No | Admin web action. |

### Agency Profile

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `GET /agence/profile` | Yes | Yes | No | Agency web only. |
| `PATCH /agence/profile` | Yes | Yes | No | Agency web only. |

### Agency Guides

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `POST /agence/guides` | Yes | Yes | No | Agency web only. |
| `GET /agence/guides` | Yes | Yes | No | Agency web only. |
| `GET /agence/guides/available` | Yes | Yes | No | Agency web only. |
| `GET /agence/guides/:id` | Yes | Indirect | No | Backend exists, but web does not currently expose a dedicated service wrapper for it. |
| `GET /agence/guides/:id/stats` | Yes | Yes | No | Agency web only. |
| `POST /agence/guides/:id/resend-activation` | Yes | Yes | No | Agency web only. |
| `PATCH /agence/guides/:id` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/guides/:id` | Yes | Yes | No | Agency web only. |

### Agency Pilgrims

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `POST /agence/pelerins` | Yes | Yes | No | Agency web only. |
| `POST /agence/pelerins/import` | Yes | Yes | No | Agency web only. |
| `GET /agence/pelerins` | Yes | Yes | No | Agency web only. |
| `GET /agence/pelerins/:id` | Yes | Yes | No | Agency web only. |
| `POST /agence/pelerins/:id/resend-activation` | Yes | Yes | No | Agency web only. |
| `PATCH /agence/pelerins/:id` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/pelerins/:id` | Yes | Yes | No | Agency web only. |

### Agency Groups

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `POST /agence/groupes` | Yes | Yes | No | Agency web only. |
| `GET /agence/groupes` | Yes | Yes | No | Agency web only. |
| `GET /agence/groupes/:id` | Yes | No | No | Backend exists, but no current client wrapper found. |
| `PATCH /agence/groupes/:id` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/groupes/:id` | Yes | Yes | No | Agency web only. |
| `POST /agence/groupes/:id/pelerins` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/groupes/:id/pelerins/:pelerinId` | Yes | Yes | No | Agency web only. |

### Agency Planning

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `GET /agence/groupes/:id/plannings` | Yes | Yes | No | Agency web only. |
| `POST /agence/groupes/:id/plannings` | Yes | Yes | No | Agency web only. |
| `POST /agence/groupes/:id/plannings/generate-template` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/groupes/:id/plannings` | Yes | Yes | No | Agency web only. |
| `PATCH /agence/groupes/plannings/:planningId` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/groupes/plannings/:planningId` | Yes | Yes | No | Agency web only. |
| `POST /agence/groupes/plannings/:planningId/evenements` | Yes | Yes | No | Agency web only. |
| `PATCH /agence/groupes/evenements/:eventId` | Yes | Yes | No | Agency web only. |
| `DELETE /agence/groupes/evenements/:eventId` | Yes | Yes | No | Agency web only. |

### Mobile Planning

| Endpoint | Backend | Web | Mobile | Notes |
| --- | --- | --- | --- | --- |
| `GET /mobile/planning/groupes` | Yes | No | Yes | Implemented. |
| `GET /mobile/planning/groupes/:groupeId` | Yes | No | Yes | Implemented. |

## Important Gaps

1. Mobile was missing `POST /auth/refresh` usage in practice. This is now covered by the Dio interceptor.
2. Web does not currently expose a dedicated wrapper for `GET /agence/guides/:id`.
3. No client wrapper was found for `GET /agence/groupes/:id`.
4. `POST /auth/set-password` and `POST /auth/verify-activation-token` are web-only today.
5. `POST /auth/signup` is web-only today.
6. `/agences` routes exist in backend, but current web admin uses `/admin/agences` instead.

## Recommended Next Pass

1. Decide whether `GET /agence/groupes/:id` and `GET /agence/guides/:id` should stay public API or be removed if unused.
2. Bring mobile planning behavior in line with the product rule: guide sees full trip, pilgrim and family see only the active day.
3. Add a small generated or maintained contract layer for shared endpoint names if you want to prevent drift long-term.
