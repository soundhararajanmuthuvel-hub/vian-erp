# Environment Variables Reference - VIAN ERP

This document details the complete set of environment variables required for VIAN ERP in production (Render + Aiven MySQL + Vercel) as well as local development.

---

## 1. Backend Server Variables (Render Web Service)

| Variable | Required | Description | Example / Default |
| :--- | :---: | :--- | :--- |
| `NODE_ENV` | **Yes** | Execution environment mode. Always `production` on Render. | `production` |
| `PORT` | **Yes** | Port Express binds to (dynamically assigned by Render). | `10000` |
| `HOST` | **Yes** | Host address to bind. | `0.0.0.0` |
| `CORS_ORIGINS` | No | Comma-separated list of allowed frontend origins (in addition to `*.vercel.app` and localhost). | `https://vianarchitects.com,https://erp.vianarchitects.in` |

---

## 2. Aiven MySQL Database Configuration

Configurable via a single URL or individual host/port parameters:

| Variable | Required | Description | Example / Default |
| :--- | :---: | :--- | :--- |
| `DATABASE_URL` | Optional* | Full MySQL connection URI with TLS enforcement. | `mysql://avnadmin:pass@mysql-xxx.aivencloud.com:28000/defaultdb?ssl-mode=REQUIRED` |
| `DB_HOST` | Optional* | Aiven MySQL hostname. | `mysql-xxxx.aivencloud.com` |
| `DB_PORT` | Optional* | Aiven MySQL port. | `28000` |
| `DB_NAME` | Optional* | Database name. | `defaultdb` |
| `DB_USER` | Optional* | Database user. | `avnadmin` |
| `DB_PASSWORD` | Optional* | Database user password. | `<secure-password>` |
| `DB_SSL` | **Yes** | Enforce TLS/SSL for database transport. | `true` |
| `DB_SSL_REJECT_UNAUTHORIZED` | No | Reject unauthorized CA certificates (`false` for cloud multi-tenant endpoints without custom CA cert, `true` when custom CA provided). | `false` |
| `AUTO_FALLBACK_SQLITE` | **Yes** | In production, must be set to `false` to avoid falling back to local SQLite on database network errors. | `false` |

*\*Either `DATABASE_URL` or the component variables (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`) must be provided.*

---

## 3. Authentication & Security Secrets

| Variable | Required | Description | Notes |
| :--- | :---: | :--- | :--- |
| `JWT_SECRET` | **Yes** | Secret key used for signing JWT access tokens. | Generate with high entropy (`openssl rand -hex 32`). |
| `JWT_REFRESH_SECRET` | **Yes** | Secret key used for JWT refresh tokens. | Generate with high entropy. |

---

## 4. Cloud File Storage (Cloudinary)

| Variable | Required | Description | Notes |
| :--- | :---: | :--- | :--- |
| `CLOUDINARY_CLOUD_NAME` | **Yes** | Cloudinary cloud account identifier. | Server-side only. |
| `CLOUDINARY_API_KEY` | **Yes** | Cloudinary API access key. | Server-side only. |
| `CLOUDINARY_API_SECRET` | **Yes** | Cloudinary API secret signature. | Server-side only. Never expose to frontend. |

---

## 5. Google Gemini AI Engine

| Variable | Required | Description | Notes |
| :--- | :---: | :--- | :--- |
| `GEMINI_API_KEY` | **Yes** | Google Cloud Gemini API key for civil drawing parsing and BOQ calculation. | Server-side only. |

---

## 6. Email Delivery (SMTP)

| Variable | Required | Description | Example |
| :--- | :---: | :--- | :--- |
| `EMAIL_HOST` | No | SMTP relay server. | `smtp.gmail.com` |
| `EMAIL_PORT` | No | SMTP port. | `587` |
| `EMAIL_USER` | No | Mailbox email. | `office@vianarchitects.in` |
| `EMAIL_PASS` | No | App password / mailbox password. | `xxxx xxxx xxxx xxxx` |

---

## 7. Frontend Compile-Time Variables (Vercel Flutter Web)

Passed via `--dart-define` in `scripts/build_flutter_web.sh`:

| Define Variable | Default | Purpose |
| :--- | :--- | :--- |
| `API_URL` | `https://vian-erp-api.onrender.com/api` | Directs frontend API calls to Render backend. |
| `ENABLE_DEMO_LOGIN` | `false` | Disables demo account UI and mock login bypass in production builds. |
| `ENVIRONMENT` | `production` | Declares runtime environment to application services. |
