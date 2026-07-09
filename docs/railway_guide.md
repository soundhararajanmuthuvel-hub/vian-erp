# Railway Deployment Guide - Node.js Backend

This guide outlines how to deploy the VIAN ERP backend on **Railway** with SQLite or MySQL databases.

## Deploying to Railway

1. **Log in to Railway**: Go to [Railway Dashboard](https://railway.app/) and click **New Project** -> **Deploy from GitHub**.
2. **Select Repository**: Select the `vian-erp` repository.
3. **Automatic Build Detection**:
   Railway reads the root `package.json` and uses the **NIXPACKS** builder to:
   - Run `npm install` which triggers the `postinstall` hook (`cd backend && npm install`) to set up dependencies.
   - Run `npm start` which proxies execution (`cd backend && npm start`) to the Node.js server.
4. **Configure Environment Variables**:
   Under the **Variables** tab in Railway, input all configuration variables detailed in the [Environment Variables Guide](environment_variables.md).
5. **Port Binding**:
   Railway automatically assigns a dynamic port via `process.env.PORT`. The backend is pre-configured in `server.js` to bind to `process.env.PORT` automatically.

## Persistent Storage (SQLite Fallback)
If you deploy without a MySQL database, the backend automatically falls back to an SQLite database (`vian_architects.sqlite`). 
Because Railway containers have ephemeral file systems, database changes will be lost on redeployments unless you attach a **Persistent Volume**.
- Add a Volume in Railway.
- Set the volume mount path to `/app/backend/database`.
- Railway will mount a persistent storage drive so SQLite records persist across restarts and deploys.
