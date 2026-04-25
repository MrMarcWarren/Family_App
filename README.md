# Tahanan

A Family Care & Connection App — built for Filipino families, wherever they are.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Python | 3.11+ |
| pip / venv | bundled with Python |
| Flutter SDK | 3.6.1+ |
| Android Studio + Emulator **or** physical device | API 21+ |

---

## 1. Backend Setup

### 1a. Create and activate a virtual environment

```bash
cd backend/api
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
```

### 1b. Install dependencies

```bash
pip install -r requirements.txt
```

### 1c. Run migrations

```bash
python manage.py migrate
```

### 1d. Create a superuser (for Django admin)

```bash
python manage.py createsuperuser
```

Or use the pre-seeded credentials below if the database was already seeded.

### 1e. Seed a test family (required for the Join Family demo flow)

```bash
python manage.py shell -c "
from app.models import Family
f, created = Family.objects.get_or_create(name='Dela Cruz Family')
print(f'Family id={f.id}')
"
```

### 1f. Start the dev server

```bash
python manage.py runserver
```

Server runs at `http://127.0.0.1:8000`

---

## 2. Frontend Setup

### 2a. Install Flutter dependencies

```bash
cd frontend
flutter pub get
```

### 2b. Configure the base URL

The app is pre-configured for **Android Emulator** (`10.0.2.2:8000`).

| Target | URL to set in `frontend/lib/core/api_client.dart` |
|--------|---------------------------------------------------|
| Android Emulator | `http://10.0.2.2:8000/api` (default) |
| Physical device (same Wi-Fi) | `http://<your-machine-LAN-IP>:8000/api` |
| iOS Simulator | `http://127.0.0.1:8000/api` |

### 2c. Run on a device or emulator

```bash
flutter run
```

To target a specific device:

```bash
flutter devices                  # list connected devices
flutter run -d <device-id>
```

---

## 3. Pre-seeded Test Data

| | |
|---|---|
| Admin username | `admin` |
| Admin password | `admin1234` |
| Admin panel | `http://127.0.0.1:8000/admin/` |
| Test family name | `Dela Cruz Family` |
| Test family ID | `1` |

---

## 4. Demo Flow

### Create a family (admin flow)
1. Log in to `/admin/` with `admin` / `admin1234`
2. Under **Families**, create a new family and note its ID

### Register and join a family (user flow)
1. Open the app → tap **Join a Family**
2. Enter Family ID `1`, fill in username, email, password, and optional details
3. Tap **Join Family** — you'll land on the Dashboard

### Register and create a new family (admin-assisted flow)
1. Tap **Create a Family** on the welcome screen
2. Register an account — the account is created but not yet assigned to a family
3. Have an admin go to `/admin/` → Users → assign the user to a family

---

## 5. Features

| Screen | What it does |
|--------|-------------|
| **Dashboard** | Shows greeting, current mood selector, today's medicine reminder, and a family message board |
| **Family** | Map view of family member locations, mood indicators, and "Check on them" care pings |
| **Reminders** | View upcoming reminders assigned to you; create new reminders and assign them to family members |

---

## 6. Project Structure

```
Family_App/
├── backend/
│   └── api/
│       ├── api/          # Django project config (settings, urls)
│       ├── app/          # Models, views, serializers, middleware
│       ├── requirements.txt
│       └── manage.py
└── frontend/
    └── lib/
        ├── core/         # api_client, token_store, models
        ├── app/          # App root and routing
        └── features/
            ├── auth/
            ├── dashboard/
            ├── family/
            └── reminders/
```

---

## 7. Key API Endpoints

All routes are prefixed with `/api/`.

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register/` | Register a new user |
| POST | `/api/auth/login/` | Login — returns JWT access + refresh tokens |
| POST | `/api/auth/token/refresh/` | Refresh access token |
| GET/PATCH | `/api/users/me/` | Get or update current user profile |
| GET | `/api/families/{id}/members/` | List members of a family |
| POST | `/api/families/{id}/join/` | Join a family |
| GET/POST | `/api/reminders/` | List or create reminders |
| GET | `/api/reminders/mine/` | Reminders assigned to current user |
| GET/POST | `/api/medicines/` | List or add medicines |
| POST | `/api/notes/` | Post a family message |

Full API reference: [`backend/api/API_DOCUMENTATION.md`](backend/api/API_DOCUMENTATION.md)

---

## 8. Development Notes

- The backend uses SQLite for development — no database setup required
- `db.sqlite3` is gitignored; run `migrate` fresh on each new clone
- JWT tokens expire — the app will redirect to login on 401
- CORS is open (`CORS_ALLOW_ALL_ORIGINS = True`) for development only
