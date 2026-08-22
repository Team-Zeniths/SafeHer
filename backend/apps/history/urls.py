from django.urls import path

from .views import (
    HistoryAiRecommendationListView,
    HistoryCommunityReportListView,
    HistoryJourneyListView,
    HistorySosEventListView,
)

urlpatterns = [
    path("journeys/", HistoryJourneyListView.as_view(), name="history-journeys"),
    path("sos-events/", HistorySosEventListView.as_view(), name="history-sos-events"),
    path("community-reports/", HistoryCommunityReportListView.as_view(), name="history-community-reports"),
    path("ai-recommendations/", HistoryAiRecommendationListView.as_view(), name="history-ai-recommendations"),
]
