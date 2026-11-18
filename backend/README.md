# The Church of Jesus Christ Restoration Ministry (RLDS Church)
## Offline-First Backend API & Stewardship Kitty Portal
**Developed by Delstarford Works**

---

### Overview
This is the production-ready Flask RESTful API backend engineered for the **RLDS Church Restoration Ministry** mobile and web applications. It implements a true **offline-first synchronization architecture** for tithes, offerings, and **Stewardship Kitty loan applications**, complete with role-based access control, M-Pesa Daraja integration, and transactional email dispatch.

It is natively architected for zero-configuration serverless deployment on **[Vercel](https://vercel.com/)** as well as containerized or standard VPS platforms.

---

### Key Capabilities
- **Offline Batch Tithe Sync (`/api/v1/tithes/sync`):** Idempotent transaction logging using client UUIDs to prevent double-charging or duplicate entries.
- **Stewardship Kitty Loan Portal (`/api/v1/loans/*`):** Application queue, repayment tracking, and **exclusive approval workflow reserved for Executive Directors**.
- **Role-Based Access Control (RBAC):**
  - `Normal Member`
  - `Deacon`
  - `Pastor`
  - `Elder`
  - `Executive Director` (Loan approvals & financial controls)
  - `Super Admin` (System administration & role delegation)
- **Safaricom M-Pesa Daraja Integration:** Lipa Na M-Pesa Online STK Push initiation and asynchronous callback handler (with built-in instant simulation mode).
- **Automated Transactional Emails:** Official HTML contribution receipts, loan status decision notices, and administrative alerts.
- **AI Support Chatbot (`/api/v1/chat/message`):** Interactive assistant for church service hours, stewardship policies, and membership registration.

---

### Directory Layout
```
backend/
├── api/
│   └── index.py            # Vercel Serverless Function entrypoint (WSGI app)
├── app/
│   ├── __init__.py         # App factory, DB init, CORS, and blueprint registry
│   ├── config.py           # Configuration manager & database fallback
│   ├── models.py           # SQLAlchemy ORM (Users, Tithes, Loans, Repayments, Notices)
│   ├── routes/
│   │   ├── auth.py         # Member registration, login, profile, role assignment
│   │   ├── tithes.py       # Offline batch sync, history, STK push & callbacks
│   │   ├── loans.py        # Stewardship Kitty application, review, and repayments
│   │   ├── announcements.py# Category-based church bulletins (Youth, Women, Men, etc.)
│   │   ├── chatbot.py      # Support & registration chatbot assistant
│   │   └── health.py       # Health check, metadata & root API documentation
│   └── services/
│       ├── auth_service.py # JWT bearer verification & @roles_required decorators
│       ├── email_service.py# SMTP / Gmail / SendGrid HTML email dispatcher
│       └── mpesa_service.py# Daraja API client & STK Push simulator
├── tests/
│   └── test_api.py         # Comprehensive automated unit test suite
├── .env.example            # Environment variables template
├── requirements.txt        # Serverless Python dependencies
├── vercel.json             # Vercel deployment routing configuration
└── run.py                  # Local development server runner
```

---

### Deploying to Vercel (Step-by-Step)

#### Option 1: Deploy via Vercel CLI
1. Open PowerShell or terminal inside `backend/` (or repository root):
   ```bash
   npm i -g vercel
   vercel
   ```
2. Follow the prompts to log in and select your Vercel team/project.
3. Deploy to production:
   ```bash
   vercel --prod
   ```

#### Option 2: Deploy via GitHub / GitLab / Bitbucket
1. Push this repository to GitHub.
2. In your [Vercel Dashboard](https://vercel.com/new), click **"Add New Project"** and import the repository.
3. **Root Directory Setting:**
   - If deploying the standalone backend, set **Root Directory** to `backend`.
   - If deploying from the repository root, leave it as `./` (the root `vercel.json` and `api/index.py` handle forwarding automatically).
4. Under **Environment Variables**, configure the production variables:
   - `DATABASE_URL`: Your PostgreSQL database connection string (from [Neon](https://neon.tech), [Supabase](https://supabase.com), or [Vercel Postgres]).
   - `SECRET_KEY`: A secure random string.
   - `JWT_SECRET_KEY`: A secure random string (minimum 32 bytes).
   - `MAIL_USERNAME` & `MAIL_PASSWORD`: Your SMTP email credentials (e.g. Gmail App Password).
   - `MPESA_CONSUMER_KEY` & `MPESA_CONSUMER_SECRET`: If using live Safaricom Daraja API (leave empty for simulation mode).
5. Click **Deploy**. Vercel will install dependencies from `requirements.txt` and launch your serverless backend.

---

### Database Setup for Serverless
Vercel functions are stateless and ephemeral. For persistent data:
1. Create a free PostgreSQL database at **[Neon.tech](https://neon.tech)** or **[Supabase.com](https://supabase.com)**.
2. Copy the connection string:
   ```env
   DATABASE_URL=postgresql://user:password@ep-sample-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
3. Add `DATABASE_URL` to your Vercel Project Environment Variables.
4. The backend automatically runs `db.create_all()` and seeds the initial administrator account on first launch.

*Note: In local development, if `DATABASE_URL` is omitted, the app automatically falls back to local SQLite (`rlds_church.db`).*

---

### Default Credentials Seeded on Startup
On initial launch with a new database, a default Super Admin account is provisioned:
- **Email:** `admin@rldschurch.org`
- **Password:** `Restoration2026!`
- **Role:** `Super Admin`
- **Member ID:** `RLDS-ADM-001`

*(You can override these via `INITIAL_ADMIN_EMAIL` and `INITIAL_ADMIN_PASSWORD` in your `.env` file.)*

---

### Running Locally

1. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # Linux/Mac:
   source venv/bin/activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Launch local server:
   ```bash
   python run.py
   ```
   The API will be available at `http://127.0.0.1:5000`.

4. Run automated tests:
   ```bash
   python -m unittest tests/test_api.py
   ```

---

### API Endpoints Reference

#### 1. Authentication (`/api/v1/auth`)
| Method | Endpoint | Description | Role Required |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Register new church member | Public |
| `POST` | `/api/v1/auth/login` | Login and receive JWT bearer token | Public |
| `GET` | `/api/v1/auth/me` | Fetch authenticated member profile | Any logged-in |
| `PUT` | `/api/v1/auth/role` | Promote/change user church roles | `Super Admin` |
| `GET` | `/api/v1/auth/members` | Church membership directory | Any logged-in |

#### 2. Tithes & Offerings (`/api/v1/tithes`)
| Method | Endpoint | Description | Role Required |
|---|---|---|---|
| `POST` | `/api/v1/tithes/sync` | **Flutter Offline Batch Sync** (Idempotent) | Public / Mobile |
| `POST` | `/api/v1/tithes/submit` | Submit single contribution online | Public / Mobile |
| `GET` | `/api/v1/tithes/history` | View giving history | Member / Leadership |
| `POST` | `/api/v1/tithes/mpesa/stkpush` | Initiate Lipa Na M-Pesa STK prompt | Public / Mobile |
| `POST` | `/api/v1/tithes/mpesa/callback` | Daraja asynchronous webhook | Safaricom |

#### 3. Stewardship Kitty Loans (`/api/v1/loans`)
| Method | Endpoint | Description | Role Required |
|---|---|---|---|
| `POST` | `/api/v1/loans/apply` | Apply for Stewardship Kitty loan (offline/online) | Member |
| `GET` | `/api/v1/loans/pending` | **Review queue for pending loans** | `Executive Director`, `Super Admin` |
| `GET` | `/api/v1/loans/my-loans` | View current member's loans & balances | Member |
| `GET` | `/api/v1/loans/<loan_id>` | Loan details and repayment records | Member / Executive |
| `PUT` | `/api/v1/loans/<loan_id>/review` | **Approve or Reject loan** & trigger email | `Executive Director`, `Super Admin` |
| `POST` | `/api/v1/loans/<loan_id>/repay` | Record repayment installment | Member / Executive |

#### 4. Church Notices & Devotionals (`/api/v1/announcements`)
| Method | Endpoint | Description | Role Required |
|---|---|---|---|
| `GET` | `/api/v1/announcements` | Filter notices by category (`Youth`, `Women`, etc.) | Public |
| `POST` | `/api/v1/announcements` | Publish church bulletin or devotional | `Pastor`, `Elder`, `Admin` |

#### 5. Member Support Chatbot (`/api/v1/chat`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/chat/message` | AI guidance for registration, giving, kitty rules & services |

---
**RLDS Church Restoration Ministry &bull; Powered by Delstarford Works**
