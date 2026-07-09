# Environment Variables Reference

Below is the list of environment variables configured for VIAN ERP. For a quick template, reference the [.env.example](file:///d:/VIAN%20Architects/.env.example) file at the root.

## Server Variables

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `PORT` | The port Express listens on (dynamic on Railway). | `5050` |
| `NODE_ENV` | Running context. | `production` |

## Database Configurations

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `DATABASE_URL` | MySQL Connection URL. | `mysql://user:pass@host:3306/db` |
| `AUTO_FALLBACK_SQLITE`| Fall back to SQLite if MySQL fails. | `true` |

## Authentication Keys

| Variable | Description | Notes |
| :--- | :--- | :--- |
| `JWT_SECRET` | Secret key used for signing JWT access tokens. | Keep secure in production. |
| `JWT_REFRESH_SECRET` | Secret key for JWT refresh tokens. | Keep secure in production. |

## External Service Integrations

| Variable | Description | Usage |
| :--- | :--- | :--- |
| `GEMINI_API_KEY` | Google Gemini AI Api key. | Fuels automated estimation & text processing. |
| `CLOUDINARY_CLOUD_NAME`| Cloudinary account name. | Handles image uploads. |
| `CLOUDINARY_API_KEY` | Cloudinary API access key. | Handles image uploads. |
| `CLOUDINARY_API_SECRET`| Cloudinary secret signature. | Handles image uploads. |

## Email Configuration (SMTP)

| Variable | Description | Example |
| :--- | :--- | :--- |
| `EMAIL_HOST` | SMTP server address. | `smtp.gmail.com` |
| `EMAIL_PORT` | SMTP port. | `587` |
| `EMAIL_USER` | Sending mailbox email. | `office@vianarchitects.in` |
| `EMAIL_PASS` | App password/mailbox password. | `xxxx xxxx xxxx xxxx` |
