# Render & Aiven Deployment Guide - VIAN ERP Backend

This guide outlines how to deploy the VIAN ERP backend on **Render** (as a Web Service) connected to **Aiven MySQL** with TLS/SSL encryption.

---

## 1. Aiven MySQL Database Setup

1. **Create Aiven MySQL Service**:
   - Go to [Aiven Console](https://console.aiven.io/).
   - Create a new **MySQL** service (version 8.0+).
   - In **Overview**, copy:
     - Host (`DB_HOST`)
     - Port (`DB_PORT`, e.g. 10000-28000)
     - User (`DB_USER`, default `avnadmin`)
     - Password (`DB_PASSWORD`)
     - Database name (`DB_NAME`, default `defaultdb`)
     - SSL mode: Enabled / Required.

2. **TLS / SSL Configuration**:
   - Set `DB_SSL=true`.
   - The backend automatically configures Sequelize dialectOptions with `ssl: { require: true, rejectUnauthorized: false }` or loads `AIVEN_CA_CERT` if provided.

3. **Schema Initialization**:
   - The backend auto-synchronizes tables safely without data loss on startup via `sequelize.sync({ force: false })` and executes non-destructive migrations.

---

## 2. Render Web Service Deployment

1. **Create Web Service on Render**:
   - Go to [Render Dashboard](https://dashboard.render.com/) -> **New** -> **Web Service**.
   - Connect repository: `soundhararajanmuthuvel-hub/vian-erp`.
   - **Root Directory**: Leave blank (uses root `package.json` and `render.yaml`).
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Health Check Path**: `/api/health`

2. **Environment Variables**:
   Under the **Environment** tab on Render, add:

   | Variable | Value / Notes |
   | :--- | :--- |
   | `NODE_ENV` | `production` |
   | `PORT` | `10000` (Render dynamically injects PORT) |
   | `HOST` | `0.0.0.0` |
   | `DB_HOST` | `<your-aiven-mysql-host>.aivencloud.com` |
   | `DB_PORT` | `<your-aiven-mysql-port>` |
   | `DB_NAME` | `defaultdb` |
   | `DB_USER` | `avnadmin` |
   | `DB_PASSWORD` | `<your-aiven-mysql-password>` |
   | `DB_SSL` | `true` |
   | `AUTO_FALLBACK_SQLITE` | `false` |
   | `JWT_SECRET` | `<high-entropy-jwt-secret>` |
   | `JWT_REFRESH_SECRET` | `<high-entropy-jwt-refresh-secret>` |
   | `CLOUDINARY_CLOUD_NAME` | `<your-cloudinary-cloud-name>` |
   | `CLOUDINARY_API_KEY` | `<your-cloudinary-api-key>` |
   | `CLOUDINARY_API_SECRET` | `<your-cloudinary-api-secret>` |
   | `GEMINI_API_KEY` | `<your-google-gemini-api-key>` |
   | `CORS_ORIGINS` | `https://vian-erp.pages.dev` |

---

## 3. Frontend Pointing to Render

When building Flutter Web for production or configuring Cloudflare Pages build environment variables:

```bash
--dart-define=API_URL=https://<your-render-service>.onrender.com/api
```

Health check verification:
```
GET https://<your-render-service>.onrender.com/api/health
```
Response:
```json
{
  "status": "ok",
  "service": "VIAN ERP API Server",
  "server": "running",
  "database": "connected",
  "latencyMs": 28,
  "environment": "production"
}
```
