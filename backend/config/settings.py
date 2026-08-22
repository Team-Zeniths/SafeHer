"""
Django settings for the SafeHer backend (Firebase + Django hybrid plan).

Firebase owns: Auth, Firestore (live journey/SOS), FCM.
This project owns: accounts, community, history, ai_assistant, journey summaries.
See ARCHITECTURE.md for the full request-flow breakdown.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "insecure-dev-key-change-me")
DEBUG = os.environ.get("DJANGO_DEBUG", "True") == "True"

# Network configuration is environment-driven so the backend is not tied to
# one laptop/LAN IP. For local development, bind Django to 0.0.0.0.
ALLOW_ALL_HOSTS = os.environ.get("ALLOW_ALL_HOSTS", "True" if DEBUG else "False") == "True"
if ALLOW_ALL_HOSTS:
    ALLOWED_HOSTS = ["*"]
else:
    ALLOWED_HOSTS = [
        h.strip()
        for h in os.environ.get("ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
        if h.strip()
    ]


# Trusted origins for CSRF (needed for /admin login over HTTPS on Render).
# Add your Render domain, e.g. https://safeher-backend.onrender.com
CSRF_TRUSTED_ORIGINS = [
    o.strip()
    for o in os.environ.get("CSRF_TRUSTED_ORIGINS", "").split(",")
    if o.strip()
]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # third-party
    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",
    # local apps
    "apps.accounts",
    "apps.journey",
    "apps.community",
    "apps.history",
    "apps.ai_assistant",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# --- Database ---------------------------------------------------------------
# SQLite by default for development; PostgreSQL configurable via DB_ENGINE=postgresql
DB_ENGINE = os.environ.get("DB_ENGINE", "sqlite3").lower()
if os.environ.get("DATABASE_URL"):
    # Render's standard single-var Postgres connection string — preferred
    # when present, since it's what Render's dashboard gives you directly.
    import dj_database_url

    DATABASES = {
        "default": dj_database_url.parse(
            os.environ["DATABASE_URL"],
            conn_max_age=600,
            ssl_require=not DEBUG,
        )
    }
elif DB_ENGINE in ("postgresql", "postgres"):
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.environ.get("DB_NAME", "safeher"),
            "USER": os.environ.get("DB_USER", "postgres"),
            "PASSWORD": os.environ.get("DB_PASSWORD", "postgres"),
            "HOST": os.environ.get("DB_HOST", "localhost"),
            "PORT": os.environ.get("DB_PORT", "5432"),
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# --- CORS --------------------------------------------------------------------
# In dev (DEBUG=True) allow everything — Flutter web picks a random port.
# In production, lock this down to specific origins via the env var.
CORS_ALLOW_ALL_ORIGINS = (
    os.environ.get("CORS_ALLOW_ALL_ORIGINS", "True" if DEBUG else "False") == "True"
)
if not CORS_ALLOW_ALL_ORIGINS:
    CORS_ALLOWED_ORIGINS = [
        o.strip()
        for o in os.environ.get("CORS_ALLOWED_ORIGINS", "").split(",")
        if o.strip()
    ]

# --- DRF -----------------------------------------------------------------
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        # Dev-only token auth comes first so dev logins work without Firebase
        "rest_framework.authentication.TokenAuthentication",
        "apps.core.firebase_auth.FirebaseAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

# --- Dev auth bypass -------------------------------------------------------
# When True, exposes /api/v1/auth/dev-register/ and /api/v1/auth/dev-login/
# so you can test the app without a real Firebase project.
# NEVER set to True in production.
DEV_AUTH_BYPASS = os.environ.get("DEV_AUTH_BYPASS", "True") == "True"

# --- Firebase ------------------------------------------------------------
# Path to the service account JSON downloaded from Firebase Console.
# The real file is gitignored; assumed present at runtime (see firebase/service_account.json.example).
FIREBASE_CREDENTIALS_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS_PATH", str(BASE_DIR / "firebase" / "service_account.json")
)
# Alternative for hosts without file uploads (e.g. Render without a Secret
# File configured): base64-encode the whole service_account.json contents
# into this env var instead. apps.core.firebase_auth prefers this when set.
FIREBASE_CREDENTIALS_JSON_B64 = os.environ.get("FIREBASE_CREDENTIALS_JSON_B64", "")
