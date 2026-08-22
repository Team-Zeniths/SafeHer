"""
Development-only authentication endpoints.

These endpoints bypass Firebase entirely so you can register and log in with
a plain email + password during local development.  They are protected by the
DEV_AUTH_BYPASS=True setting and will raise Http404 in production.

Endpoints
---------
POST /api/v1/auth/dev-register/
    Body: { email, password, full_name, phone }
    Creates a Django User + Profile and returns a DRF Token.

POST /api/v1/auth/dev-login/
    Body: { email, password }
    Returns the DRF Token for an existing user.

GET  /api/v1/auth/dev-me/
    Header: Authorization: Token <token>
    Returns the profile for the token owner — mirrors the shape of /accounts/me/
    so the Flutter ProfileSerializer tests work unchanged.
"""

from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.http import Http404
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.accounts.models import Profile
from apps.accounts.serializers import ProfileSerializer

User = get_user_model()

DEV_MODE = getattr(settings, "DEV_AUTH_BYPASS", False)


def _require_dev_mode():
    """Raise Http404 when DEV_AUTH_BYPASS is not enabled."""
    if not DEV_MODE:
        raise Http404("Dev-auth endpoints are disabled in production.")


# ---------------------------------------------------------------------------
# Register
# ---------------------------------------------------------------------------


@api_view(["POST"])
@permission_classes([AllowAny])
def dev_register(request):
    """Create a new user + profile and return an auth token."""
    _require_dev_mode()

    email = (request.data.get("email") or "").strip().lower()
    password = request.data.get("password") or ""
    full_name = (request.data.get("full_name") or "").strip()
    phone = (request.data.get("phone") or "").strip()

    if not email or not password:
        return Response(
            {"detail": "email and password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if User.objects.filter(email=email).exists():
        return Response(
            {"detail": "A user with that email already exists."},
            status=status.HTTP_409_CONFLICT,
        )

    # firebase_uid is required-unique on Profile; use a stable dev prefix
    dev_uid = f"dev_{email}"

    user = User.objects.create_user(
        username=email,
        email=email,
        password=password,
        first_name=full_name.split()[0] if full_name else "",
        last_name=" ".join(full_name.split()[1:]) if len(full_name.split()) > 1 else "",
    )
    profile = Profile.objects.create(
        user=user,
        firebase_uid=dev_uid,
        display_name=full_name,
        phone=phone,
    )

    token, _ = Token.objects.get_or_create(user=user)

    return Response(
        {
            "token": token.key,
            "user": {
                "id": str(user.id),
                "email": user.email,
                "full_name": profile.display_name,
                "phone": profile.phone,
                "is_verified": True,
            },
        },
        status=status.HTTP_201_CREATED,
    )


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------


@api_view(["POST"])
@permission_classes([AllowAny])
def dev_login(request):
    """Return the auth token for an existing dev user."""
    _require_dev_mode()

    email = (request.data.get("email") or "").strip().lower()
    password = request.data.get("password") or ""

    user = authenticate(request, username=email, password=password)
    if user is None:
        return Response(
            {"detail": "Invalid email or password."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    token, _ = Token.objects.get_or_create(user=user)

    try:
        profile = user.profile
    except Profile.DoesNotExist:
        profile = Profile.objects.create(
            user=user,
            firebase_uid=f"dev_{email}",
            display_name=f"{user.first_name} {user.last_name}".strip() or email,
        )

    return Response(
        {
            "token": token.key,
            "user": {
                "id": str(user.id),
                "email": user.email,
                "full_name": profile.display_name,
                "phone": profile.phone,
                "is_verified": True,
            },
        }
    )


# ---------------------------------------------------------------------------
# Reset Password / Forgot Password
# ---------------------------------------------------------------------------


@api_view(["POST"])
@permission_classes([AllowAny])
def dev_reset_password(request):
    """Reset password for an existing dev user."""
    _require_dev_mode()

    email = (request.data.get("email") or "").strip().lower()
    password = request.data.get("password") or request.data.get("new_password") or ""

    if not email or not password:
        return Response(
            {"detail": "Email and new password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = User.objects.filter(email=email).first()
    if not user:
        user = User.objects.filter(username=email).first()

    if user is None:
        return Response(
            {"detail": "No account found with this email address."},
            status=status.HTTP_404_NOT_FOUND,
        )

    user.set_password(password)
    user.save()

    # Invalidate old auth tokens so they sign in freshly with new credentials
    Token.objects.filter(user=user).delete()

    return Response(
        {"detail": "Password has been reset successfully. Please sign in with your new password."},
        status=status.HTTP_200_OK,
    )


# ---------------------------------------------------------------------------
# Me (profile fetch — mirrors /accounts/me/ but uses TokenAuthentication)
# ---------------------------------------------------------------------------


@api_view(["GET", "PATCH"])
@permission_classes([IsAuthenticated])
def dev_me(request):
    """Return or update the authenticated user's profile."""
    _require_dev_mode()

    try:
        profile = request.user.profile
    except Profile.DoesNotExist:
        raise Http404("Profile not found.")

    if request.method == "PATCH":
        serializer = ProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    return Response(ProfileSerializer(profile).data)

