# VIAN ERP - Enterprise Management Portal

VIAN ERP is a premium, production-ready enterprise dashboard and client enquiry management system designed exclusively for **VIAN Architects & Interior Designers**.

This project provides a robust solution for tracking leads, clients, onboarding workflows, estimations/BOQs, construction tasks, and client enquiry submissions with secure, authenticated access control.

---

## Folder Structure

```
vian-erp/
├── apps/
│   ├── flutter_web/        # Unified Flutter frontend codebase (Web, Android, iOS)
│   └── flutter_mobile/     # Mobile deployment configurations & pointer
├── backend/
│   ├── config/             # DB settings
│   ├── controllers/        # Route controllers
│   ├── database/           # SQLite / MySQL schema setups, models, and mock/live seeders
│   ├── middleware/         # Security / JWT middlewares
│   ├── routes.js           # API route mappings and business action handlers
│   ├── server.js           # Production server start script, Helmet, CORS, Rate Limiters
│   ├── services/           # Service connectors (Gemini, Cloudinary)
│   ├── utils/              # Helper utilities
│   ├── uploads/            # Local file storage
│   └── package.json
├── docs/                   # Deployment guides and environment configurations
├── .github/                # GitHub Actions CI pipelines
├── .env.example
├── .gitignore
├── LICENSE
├── README.md
└── package.json            # Railway deployment proxy configuration
```

---

## Architecture Stack

- **Frontend**: Flutter Web (Material 3 luxury dark/gold aesthetics, Google Fonts Outfit)
- **Backend**: Node.js + Express
- **Database**: MySQL (Production) / SQLite (Fallback Developer Mode)
- **Deployment Targets**: Cloudflare Pages (Frontend), Railway (Backend)
- **Storage**: Cloudinary (Attachments & conceptual design sketches)

---

## Documentation Links

For detailed production deployment steps, please refer to our documentation in the `docs` folder:

- 📖 **[Main Deployment Guide](docs/deployment_guide.md)**
- 🧡 **[Cloudflare Pages Deploy Guide](docs/deployment/cloudflare-pages.md)**
- 🚂 **[Railway Backend Deploy Guide](docs/railway_guide.md)**
- 🔑 **[Environment Variables Setup](docs/environment_variables.md)**

---

## Installation & Setup (Local Development)

### Prerequisites

1. Node.js >= 18.x
2. Flutter SDK >= 3.44.x
3. Local MySQL Server or SQLite

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
   cp .env.example .env
   ```
4. Start developer server:
   ```bash
   npm run dev
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
   flutter build web --release
   ```

---

## License

This software is licensed under the MIT License. See [LICENSE](LICENSE) for details.
