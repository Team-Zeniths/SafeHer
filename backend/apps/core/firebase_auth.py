"""
DRF authentication backend that verifies Firebase ID tokens.

Flow:
  1. Flutter signs the user in via the Firebase Auth SDK (phone/OTP).
  2. Flutter sends the resulting ID token as `Authorization: Bearer <token>`
     on every request to this Django API.
  3. This class verifies that token against Firebase (using the service
     account credentials at settings.FIREBASE_CREDENTIALS_PATH) and maps the
     Firebase UID to a local Django User + apps.accounts.Profile, creating
     both on first sight so every authenticated request has a normal
     request.user DRF permissions can work against.

Firebase itself is the source of truth for identity — this class never
issues, stores, or checks passwords. It only verifies a token Firebase
already signed.
"""

import base64
import json

import firebase_admin
from django.conf import settings
from django.contrib.auth import get_user_model
from firebase_admin import auth as firebase_auth_sdk
from firebase_admin import credentials
from rest_framework import authentication, exceptions

User = get_user_model()

_firebase_app = None


def _get_firebase_app():
    """Lazily initialize the Firebase Admin app (once per process).

    Prefers FIREBASE_CREDENTIALS_JSON_B64 (a base64-encoded copy of the full
    service_account.json) when set — convenient for hosts like Render that
    don't want a secret file on disk. Falls back to FIREBASE_CREDENTIALS_PATH
    otherwise.
    """
    global _firebase_app
    if _firebase_app is None:
        if settings.FIREBASE_CREDENTIALS_JSON_B64:
            decoded = base64.b64decode(settings.FIREBASE_CREDENTIALS_JSON_B64)
            cred_dict = json.loads(decoded)
            cred = credentials.Certificate(cred_dict)
        else:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)
    return _firebase_app


class FirebaseAuthentication(authentication.BaseAuthentication):
    """
    Verifies `Authorization: Bearer <firebase_id_token>` and returns
    (user, decoded_token) on success, per DRF's authenticate() contract.
    """

    keyword = "Bearer"

    def authenticate(self, request):
        auth_header = authentication.get_authorization_header(request).decode("utf-8")
        if not auth_header:
            return None  # no credentials supplied — let other authenticators / permissions decide

        parts = auth_header.split()
        if len(parts) != 2 or parts[0] != self.keyword:
            return None

        id_token = parts[1]

        try:
            _get_firebase_app()
            decoded_token = firebase_auth_sdk.verify_id_token(id_token)
        except FileNotFoundError as exc:
            # service_account.json is missing — a config problem, not a bad request
            raise exceptions.AuthenticationFailed(
                "Firebase credentials are not configured on the server."
            ) from exc
        except Exception as exc:  # firebase_admin raises several distinct error types
            raise exceptions.AuthenticationFailed(f"Invalid Firebase token: {exc}") from exc

        firebase_uid = decoded_token.get("uid")
        if not firebase_uid:
            raise exceptions.AuthenticationFailed("Firebase token did not contain a uid.")

        user = self._get_or_create_user(firebase_uid, decoded_token)
        return (user, decoded_token)

    def _get_or_create_user(self, firebase_uid, decoded_token):
        # apps.accounts.Profile.firebase_uid is the join key between Firebase
        # identity and the local Django User apps.accounts owns.
        from apps.accounts.models import Profile

        try:
            profile = Profile.objects.select_related("user").get(firebase_uid=firebase_uid)
            return profile.user
        except Profile.DoesNotExist:
            phone = decoded_token.get("phone_number", "")
            # username must be unique; firebase_uid always is
            user = User.objects.create(username=firebase_uid)
            Profile.objects.create(user=user, firebase_uid=firebase_uid, phone=phone)
            return user

    def authenticate_header(self, request):
        # Returned in the 401 WWW-Authenticate header when auth fails.
        return self.keyword
