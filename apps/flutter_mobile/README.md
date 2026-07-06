# VIAN Architects - Flutter Mobile Application

This folder represents the mobile build targets (Android & iOS) of the unified VIAN ERP codebase.

To maintain single-source-of-truth and avoid duplication of design templates, API logic, and layout canvas modules, the complete application source files are unified and managed under the sister directory:

👉 **[apps/flutter_web/](../flutter_web/)**

## Running Mobile Apps

You can run Android and iOS targets directly from the unified codebase:

```bash
cd ../flutter_web
flutter run -d <android-device-id-or-simulator>
```
