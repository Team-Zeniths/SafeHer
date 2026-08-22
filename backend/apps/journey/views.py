from rest_framework import generics, permissions


from .models import JourneySummary
from .serializers import JourneySummarySerializer


class JourneySummaryListCreateView(generics.ListCreateAPIView):
    """
    POST /api/v1/journey/summaries/ — archive a finished journey.
    GET  /api/v1/journey/summaries/ — list the authenticated user's past journeys.
    """

    serializer_class = JourneySummarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return JourneySummary.objects.filter(owner=self.request.user.profile)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user.profile)
