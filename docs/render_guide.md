# Render PostgreSQL & Web Service Deployment Guide — VIAN ERP

This guide outlines how to deploy the production VIAN ERP architecture:
- **Frontend**: Vercel (Flutter Web SPA)
- **Backend API**: Render Web Service (`vian-erp-api`)
- **Database**: Render Managed PostgreSQL (`vian-erp-db`)
- **File Storage**: Cloudinary
- **AI**: Google Gemini

---

## 1. Render Managed PostgreSQL Database Setup

1. **Create PostgreSQL Database on Render**:
   - Go to [Render Dashboard](https://dashboard.render.com/) -> **New** -> **PostgreSQL**.
   - **Name**: `vian-erp-db`
   - **Database**: `vian_erp_db`
   - **User**: `vian_admin`
   - **Region**: `Singapore` (or match your Web Service region)
   - **PostgreSQL Version**: Current supported stable (e.g., 16)
   - **Plan**: Starter

2. **Retrieve Connection String**:
   - In database **Overview**, copy the **Internal Database URL** (for Render-to-Render communication) or **External Database URL** (for remote migrations/diagnostics).
   - Format: `postgres://user:password@host:port/database`

3. **Schema Initialization & Data Migration**:
   - When the backend starts in production, Sequelize initializes all tables non-destructively via `sequelize.sync({ force: false })` and runs PostgreSQL auto-migrations.
   - To transfer data from SQLite or an existing database to Render PostgreSQL, run:
     ```bash
     TARGET_DATABASE_URL="postgres://..." node backend/migrate_to_postgres.js
     ```

---

## 2. Render Web Service Deployment

1. **Create Web Service on Render**:
   - Go to [Render Dashboard](https://dashboard.render.com/) -> **New** -> **Web Service**.
   - Connect repository: `soundhararajanmuthuvel-hub/vian-erp`.
   - **Name**: `vian-erp-api`
   - **Region**: `Singapore` (matching your PostgreSQL database)
   - **Root Directory**: `backend` (or use Blueprint `render.yaml`)
   - **Environment**: `Node`
   - **Build Command**: `npm ci`
   - **Start Command**: `npm start`
   - **Health Check Path**: `/api/health`

2. **Environment Variables**:
   Under the **Environment** tab on Render, configure:

   | Variable | Value / Notes |
   | :--- | :--- |
   | `NODE_ENV` | `production` |
   | `PORT` | `10000` (Render dynamically injects PORT) |
   | `HOST` | `0.0.0.0` |
   | `DATABASE_URL` | `<Render PostgreSQL Internal Connection String>` |
   | `AUTO_FALLBACK_SQLITE` | `false` |
   | `JWT_SECRET` | `<high-entropy-jwt-secret>` |
   | `JWT_REFRESH_SECRET` | `<high-entropy-jwt-refresh-secret>` |
   | `CLOUDINARY_CLOUD_NAME` | `<your-cloudinary-cloud-name>` |
   | `CLOUDINARY_API_KEY` | `<your-cloudinary-api-key>` |
   | `CLOUDINARY_API_SECRET` | `<your-cloudinary-api-secret>` |
   | `GEMINI_API_KEY` | `<your-google-gemini-api-key>` |
   | `CORS_ORIGINS` | `https://<your-project>.vercel.app,https://vianarchitects.com` |

---

## 3. Vercel Frontend Deployment

1. **Deploy to Vercel**:
   - Connect repository: `soundhararajanmuthuvel-hub/vian-erp`.
   - **Root Directory**: Either `/` (repository root) or `apps/flutter_web`. Both configurations are natively supported via provided `vercel.json` and build scripts.
   - **Build Command**: `bash scripts/build_flutter_web.sh`
   - **Output Directory**: `apps/flutter_web/build/web` (if root) or `build/web` (if `apps/flutter_web`).

2. **Production API Endpoint**:
   - The build script passes:
     ```bash
     --dart-define=API_URL=https://vian-erp-api.onrender.com/api
     --dart-define=ENABLE_DEMO_LOGIN=false
     --dart-define=ENVIRONMENT=production
     ```

---

## 4. Verification & Diagnostics

- **Health Check**:
  ```bash
  curl https://vian-erp-api.onrender.com/api/health
  # Returns: {"status":"ok","database":"connected","environment":"production"}
  ```
- **PostgreSQL Connectivity Test**:
  ```bash
  DATABASE_URL="postgres://..." node backend/test_postgres_connection.js
  ```
- **Comparative Migration Audit**:
  ```bash
  TARGET_DATABASE_URL="postgres://..." node backend/migrate_to_postgres.js
  ```
