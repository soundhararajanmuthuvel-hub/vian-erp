# VIAN ERP - Enterprise Management Portal

VIAN ERP is a premium, production-ready enterprise dashboard and client enquiry management system designed exclusively for **VIAN Architects & Interior Designers**.

This project provides a robust solution for tracking leads, clients, onboarding workflows, estimations/BOQs, construction tasks, and client enquiry submissions with secure, authenticated access control.

---

## Folder Structure

```
vian-erp/
├── apps/
│   ├── flutter_web/        # Unified Flutter frontend codebase (Web, Android, iOS)
│   └── flutter_mobile/     # Mobile deployment configurations & docs
├── backend/
│   ├── database/           # SQLite / MySQL schema setups, models, and mock/live seeders
│   ├── routes.js           # API route mappings and business action handlers
│   ├── server.js           # Production server start script, Helmet, CORS, Rate Limiters
│   └── package.json
├── .env.example
├── .gitignore
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
└── SECURITY.md
```

---

## Architecture Stack

- **Frontend**: Flutter Web (Material 3 luxury dark/gold aesthetics, Google Fonts Outfit)
- **Backend**: Node.js + Express
- **Database**: MySQL (Production) / SQLite (Fallback Developer Mode)
- **Deployment Targets**: Vercel (Frontend), Railway (Backend)
- **Storage**: Cloudinary (Attachments & conceptual design sketches)

---

## Installation & Setup

### Prerequisites

1. Node.js >= 16.x
2. Flutter SDK >= 3.x
3. MySQL Server / local database

### Backend Configuration

1. Change directory to backend:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy environment configuration:
   ```bash
   cp ../.env.example .env
   ```
4. Start developer server:
   ```bash
   npm start
   ```

### Frontend Configuration

1. Change directory to frontend:
   ```bash
   cd apps/flutter_web
   ```
2. Resolve pub dependencies:
   ```bash
   flutter pub get
   ```
3. Run release compilation for Web:
   ```bash
   flutter build web
   ```

---

## Production Deployments

### Frontend on Vercel
Connect your GitHub repository to Vercel, set the root directory to `apps/flutter_web`, and configure output directory to `build/web`.

### Backend on Railway
Deploy the `backend` folder to Railway, link the MySQL Database Addon, and set environment variables as detailed in `.env.example`.

---

## License

This software is licensed under the MIT License. See [LICENSE](LICENSE) for details.
