from django.utils import timezone
from rest_framework import generics, status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.permissions import IsOwner

from .models import EmergencyContact, Profile, SosLog
from .serializers import EmergencyContactSerializer, ProfileSerializer, SosLogSerializer


class MeView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/v1/accounts/me/ — the authenticated user's own profile."""

    serializer_class = ProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user.profile


class EmergencyContactViewSet(viewsets.ModelViewSet):
    """
    /api/v1/accounts/contacts/        GET (list), POST (create)
    /api/v1/accounts/contacts/{id}/   GET, PATCH, DELETE
    Scoped to the authenticated user's own contacts only.
    """

    serializer_class = EmergencyContactSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return EmergencyContact.objects.filter(owner=self.request.user.profile).order_by("-id")

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user.profile)


class SosLogCreateView(generics.CreateAPIView):
    """
    POST /api/v1/accounts/sos-log/
    Archives a completed SOS event. The live event and the push notification
    to emergency contacts already happened via Firestore/FCM before this call
    — this just makes the event queryable from Django (History tab).
    """

    serializer_class = SosLogSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user.profile)


class SosLogCancelView(APIView):
    """
    POST /api/v1/accounts/sos-log/cancel/
    Marks the user's most recent unresolved SOS event as resolved. Called
    when the user cancels an active SOS from the app. If there's no
    unresolved log (e.g. the create call never made it to the server),
    this is a harmless no-op rather than an error, since the client's own
    UI state is already the source of truth for "SOS is off."
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        log = (
            SosLog.objects.filter(owner=request.user.profile, resolved_at__isnull=True)
            .order_by("-triggered_at")
            .first()
        )
        if log is not None:
            log.resolved_at = timezone.now()
            log.save(update_fields=["resolved_at"])
        return Response(status=status.HTTP_200_OK)
