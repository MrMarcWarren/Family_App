# Tahanan Quickstart (2 Minutes)

Use this guide for the fastest local run.

## 1) Start Backend

From project root:

```powershell
cd backend/api
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Backend URL:

```text
http://127.0.0.1:8000
```

## 2) Start Frontend

Open a second terminal from project root:

```powershell
cd frontend
flutter pub get
flutter run
```

## 3) Base URL (Important)

Set API base URL in frontend/lib/core/api_client.dart:

- Android emulator: http://10.0.2.2:8000/api
- iOS simulator: http://127.0.0.1:8000/api
- Physical phone (same Wi-Fi): http://YOUR_PC_LAN_IP:8000/api

## 4) Optional Admin User

```powershell
cd backend/api
venv\Scripts\activate
python manage.py createsuperuser
```

## 5) Common Fixes

- If frontend cannot connect, check the API base URL first.
- If physical phone cannot connect, ensure phone and PC are on the same Wi-Fi.
- If backend errors on first run, rerun migrations:

```powershell
python manage.py migrate
```
