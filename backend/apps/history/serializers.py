from rest_framework import serializers

from apps.accounts.models import SosLog
from apps.ai_assistant.models import AiRecommendationLog
from apps.community.models import IncidentReport
from apps.journey.models import JourneySummary


class HistoryJourneySerializer(serializers.ModelSerializer):
    class Meta:
        model = JourneySummary
        fields = ["id", "start_point", "end_point", "started_at", "ended_at", "distance_km", "was_completed_safely"]


class HistorySosEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = SosLog
        fields = ["id", "location_lat", "location_lng", "triggered_at", "resolved_at"]


class HistoryCommunityReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = IncidentReport
        fields = ["id", "category", "description", "location_lat", "location_lng", "status", "created_at"]


class HistoryAiRecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AiRecommendationLog
        fields = ["id", "query_type", "input_summary", "output_summary", "created_at"]
