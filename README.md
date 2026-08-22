# SafeHer

A personal safety app for women — SOS alerts, live journey tracking, an AI safety assistant, and a community reporting layer — built with Flutter and Django.

## Features

- **SOS / Emergency** — one-tap emergency alerts and incident reporting
- **Journey tracking** — share a live route with trusted contacts
- **AI safety assistant** — chat-based guidance and area safety scoring
- **Community** — local safety reports from other users
- **Contacts & Notifications** — manage trusted contacts and alert history
- **Auth** — email/password (dev mode) and Google Sign-In via Firebase

## Tech stack

**Frontend:** Flutter, Provider, GoRouter, Dio, Firebase Auth, Google Sign-In, Geolocator
**Backend:** Django, Django REST Framework, PostgreSQL (SQLite for local dev), Firebase Admin SDK, Google Gemini API

## Project structure

```
SafeHer/
├── frontend/   # Flutter app (lib/features/* — ai, auth, community, contacts,
│               #   emergency, history, home, journey, notifications, profile)
└── backend/    # Django REST API (apps/* — accounts, ai_assistant, community,
                #   core, history, journey)
```

## Backend setup (local development)

```bash
cd backend
python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env          # then fill in the values below
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

**Required environment variables** (see `.env.example` for the full list):

| Variable | Notes |
|---|---|
| `DJANGO_SECRET_KEY` | any random string for local dev |
| `DJANGO_DEBUG` | `True` for local dev |
| `DB_ENGINE` | `sqlite3` for local dev, `postgresql` for production |
| `ALLOWED_HOSTS` | e.g. `127.0.0.1,localhost` |
| `FIREBASE_CREDENTIALS_PATH` | path to your Firebase service account JSON (see below) |
| `GEMINI_API_KEY` | your Google Gemini API key |

**Firebase service account:** download it from Firebase Console → Project Settings → Service Accounts → "Generate new private key", save it as `backend/firebase/service_account.json` (gitignored — see `service_account.json.example` for the expected shape).

## Frontend setup (local development)

```bash
cd frontend
flutter pub get
```

**Point the app at your backend.** By default the app targets a local dev URL — override it if needed:

```bash
# Android emulator
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1/

# Physical phone on the same Wi-Fi as your backend
flutter run --dart-define=API_URL=http://<your-PC-LAN-IP>:8000/api/v1/
```

Also run the Django backend with `runserver 0.0.0.0:8000` (not just `runserver`) so a phone on the same network can reach it.

**Google Sign-In:** requires a registered Firebase Android app with your keystore's SHA-1/SHA-256 fingerprint added, and `google-services.json` placed at `frontend/android/app/google-services.json` (gitignored — see `.example` files for reference).

## Building a release APK

1. Generate a release keystore and register its SHA-1/SHA-256 in Firebase Console (debug and release keystores need separate fingerprints).
2. Copy `frontend/android/key.properties.example` → `frontend/android/key.properties` and fill in your real keystore details.
3. Build, pointing at your deployed backend:

```bash
flutter build apk --release --dart-define=API_URL=https://your-backend-url/api/v1/
```

## Deployment (Render)

The backend includes a `Procfile` and `build.sh` for Render:

- Set `DATABASE_URL` (Render's Postgres connection string), `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=False`, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`, and `GEMINI_API_KEY` as environment variables on the Render service.
- For Firebase credentials without a mounted file, set `FIREBASE_CREDENTIALS_JSON_B64` to a base64-encoded copy of `service_account.json` instead of `FIREBASE_CREDENTIALS_PATH`.

## Notes

- Auth currently supports a dev-mode email/password flow (immediate login, no OTP) alongside real Google Sign-In via Firebase — useful for fast local testing without SMS/Firebase dependencies.
- Render's free tier spins down after 15 minutes of inactivity; the first request afterward may take 30–50 seconds.
