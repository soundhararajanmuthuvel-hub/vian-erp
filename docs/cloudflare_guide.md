# Cloudflare Pages Deployment Guide (VIAN ERP)

This guide documents how to deploy the VIAN ERP Flutter Web frontend using GitHub Actions and Cloudflare Pages.

---

## Prerequisites

1. A **Cloudflare Account**
2. Access to the **VIAN ERP GitHub Repository**

---

## Step 1: Gather Cloudflare Account Information

To configure the GitHub Actions workflow, you need two pieces of information from Cloudflare:

### 1. Cloudflare Account ID
1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Click on **Workers & Pages** in the left sidebar, or view your account details on the home overview page.
3. Locate the **Account ID** string under the panel on the right side.
4. Copy this value. You will save it as `CLOUDFLARE_ACCOUNT_ID` in GitHub.

### 2. Cloudflare API Token
1. Go to your **My Profile** settings by clicking the user icon in the top right.
2. Select **API Tokens** from the sidebar menu.
3. Click **Create Token**.
4. Choose the **Cloudflare Pages** template (or select **Create Custom Token**).
5. Ensure the token has the following permission:
   - **Account** -> **Cloudflare Pages** -> **Edit**
6. Click **Continue to summary** and then **Create Token**.
7. Copy the generated API Token. You will save it as `CLOUDFLARE_API_TOKEN` in GitHub.

---

## Step 2: Configure GitHub Repository Secrets

1. Go to your repository on GitHub.
2. Navigate to **Settings** -> **Secrets and variables** -> **Actions**.
3. Click **New repository secret** and add:
   - **Name**: `CLOUDFLARE_ACCOUNT_ID`
   - **Value**: *(Paste your Account ID here)*
4. Click **New repository secret** again and add:
   - **Name**: `CLOUDFLARE_API_TOKEN`
   - **Value**: *(Paste your API Token here)*

---

## Step 3: Deployment Trigger

The GitHub Actions workflow `.github/workflows/deploy-cloudflare.yml` runs automatically whenever a push to the `main` branch occurs.

During the workflow:
- The project is checked out.
- The latest stable Flutter SDK is installed and cached.
- `flutter build web --release` compiles static files.
- The generated build artifacts under `apps/flutter_web/build/web` are uploaded and deployed to Cloudflare Pages.

---

## Verification & Troubleshooting

- To monitor deployment logs, visit the **Actions** tab in your GitHub repository.
- Ensure the project name in `.github/workflows/deploy-cloudflare.yml` (`vian-erp`) matches your Cloudflare Pages project name.
