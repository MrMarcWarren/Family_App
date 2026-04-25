# Tahanan

Tahanan is a family care and connection app built for Filipino families to stay close through daily mood check-ins, reminders, medicine tracking, quick family messages, and emergency support.

## Overview

### What the app does
- Helps family members check in on each other quickly.
- Supports medicine and personal reminders.
- Provides a family feed for quick updates.
- Offers emergency toggle and family visibility features.
- Enables direct contact actions (message and call) from the family experience.

### Main features
- Dashboard: mood check-in, encouragement message, medicine panel, notes feed.
- Family tab: family list, location map, check-on actions, message/call actions.
- Reminders tab: create reminders, mark done, dismiss reminders.
- Auth and profile: registration, login, token refresh, profile updates.

## Credits

This project uses the following tools, frameworks, and resources:

### Frontend
- Flutter (mobile UI framework)
- Dart (language)
- Dio (HTTP client)
- Google Fonts (typography)
- flutter_map and latlong2 (map rendering and coordinates)
- url_launcher (open SMS and phone call actions)

### Backend
- Django (web framework)
- Django REST Framework (API framework)
- Simple JWT (JWT auth flow)
- SQLite (local development database)

### Dev tools and resources
- Android Studio and Android SDK (Android builds/emulator)
- OpenStreetMap tile service (map tiles)

## Run On Localhost

Use two terminals: one for backend and one for frontend.

### 1) Prerequisites
- Python 3.11+
- Flutter SDK 3.6.1+
- Android Studio (or Android SDK + platform tools)

### 2) Backend setup and run

From project root:

```powershell
cd backend/api
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Backend will run at:

```text
http://127.0.0.1:8000
```

### 3) Frontend setup and run

Open a second terminal from project root:

```powershell
cd frontend
flutter pub get
flutter run
```

### 4) API base URL by target

Update the base URL in frontend/lib/core/api_client.dart as needed:

- Android emulator: http://10.0.2.2:8000/api
- iOS simulator: http://127.0.0.1:8000/api
- Physical phone (same Wi-Fi): http://YOUR_PC_LAN_IP:8000/api

### 5) Optional initial admin account

```powershell
cd backend/api
venv\Scripts\activate
python manage.py createsuperuser
```

## Useful Files

- Backend API reference: backend/api/API_DOCUMENTATION.md
- Product spec and MVP: PRODUCT_SPEC_AND_MVP.md
