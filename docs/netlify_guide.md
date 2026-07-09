# Netlify Deployment Guide - Flutter Web Frontend

This guide outlines how to deploy the VIAN ERP frontend to **Netlify** using automated Git-based builds.

## Setup Instructions

1. **Log in to Netlify**: Go to [Netlify Dashboard](https://app.netlify.com/) and click **Add new site** -> **Import an existing project**.
2. **Connect Repository**: Authorize Netlify to access your GitHub account and select your `vian-erp` repository.
3. **Configure Build Settings**:
   Netlify reads the configuration from the repository's `netlify.toml` file automatically. Verify the following parameters are populated:
   - **Base directory**: `apps/flutter_web`
   - **Build command**: `if [ -d 'flutter' ]; then cd flutter && git pull && cd ..; else git clone --depth 1 --branch stable https://github.com/flutter/flutter.git; fi && ./flutter/bin/flutter build web --release`
   - **Publish directory**: `apps/flutter_web/build/web`
4. **Environment Variables**:
   Add any runtime variables (such as custom Google Maps API keys or backend endpoints) that need to be compiled at build time by adding `--dart-define` parameters to the build command.
5. **Deploy**: Click **Deploy Site**. Netlify will clone the stable Flutter SDK, compile the codebase, and host it on a global CDN.

## SPA Routing Fallback
Netlify uses the `_redirects` rule declared in `netlify.toml` to automatically redirect all non-file route calls to `index.html` with a `200` status. This prevents `404 Not Found` errors when refreshing routes managed by `go_router`.
