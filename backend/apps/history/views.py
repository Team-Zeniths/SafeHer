"""
Read-only aggregation views for the History tab. Every endpoint here scopes
strictly to the authenticated user's own records — History is personal, not
a global feed (Community already covers the shared/public view).
"""

from rest_framework import generics, permissions

from apps.accounts.models import SosLog
from apps.ai_assistant.models import AiRecommendationLog
from apps.community.models import IncidentReport
from apps.journey.models import JourneySummary

from .serializers import (
    HistoryAiRecommendationSerializer,
    HistoryCommunityReportSerializer,
    HistoryJourneySerializer,
    HistorySosEventSerializer,
)


class HistoryJourneyListView(generics.ListAPIView):
    """GET /api/v1/history/journeys/"""

    serializer_class = HistoryJourneySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return JourneySummary.objects.filter(owner=self.request.user.profile)


class HistorySosEventListView(generics.ListAPIView):
    """GET /api/v1/history/sos-events/"""

    serializer_class = HistorySosEventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SosLog.objects.filter(owner=self.request.user.profile)


class HistoryCommunityReportListView(generics.ListAPIView):
    """
    GET /api/v1/history/community-reports/?reporter=me
    The `reporter=me` param from API_CONTRACT.md is accepted but not required
    to mean anything else yet — this view only ever returns the caller's own
    reports, since History is a personal record view, not a moderation queue.
    """

    serializer_class = HistoryCommunityReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return IncidentReport.objects.filter(reporter=self.request.user.profile)


class HistoryAiRecommendationListView(generics.ListAPIView):
    """GET /api/v1/history/ai-recommendations/"""

    serializer_class = HistoryAiRecommendationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return AiRecommendationLog.objects.filter(owner=self.request.user.profile)
