# HD Studio Clone — App Spec

**Type:** Functional platform (app builder)
**Complexity:** Medium (4 tables)
**Deploy:** Vercel

---

## Data Model

### Users
| Field | Type |
|-------|------|
| id | uuid PK |
| email | text unique |
| name | text |
| role | enum: admin, user |
| created_at | timestamp |

### Projects
| Field | Type |
|-------|------|
| id | uuid PK |
| name | text |
| description | text |
| status | enum: draft, live, archived |
| app_url | text |
| deploy_target | text |
| owner_id | uuid FK → Users |
| credits_used | integer |
| created_at | timestamp |
| updated_at | timestamp |

### ShowcaseItems
| Field | Type |
|-------|------|
| id | uuid PK |
| title | text |
| description | text |
| image_url | text |
| app_url | text |
| category | text |
| created_at | timestamp |

### PricingPlans
| Field | Type |
|-------|------|
| id | uuid PK |
| name | text |
| price | numeric |
| credits_included | integer |
| features | text[] |
| created_at | timestamp |

---

## Auth
- Provider: Supabase Auth
- Methods: Email/password, Magic link
- Roles: Admin, User

## Features
- CRUD — projects, showcase items, pricing plans
- Dashboard — usage stats, active projects, credits consumed
- Multi-step forms — onboarding flow + project creation wizard
- Search and filter — projects list + showcase gallery
