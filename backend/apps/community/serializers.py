from rest_framework import serializers

from .models import IncidentReport, SafetyAlert


class IncidentReportSerializer(serializers.ModelSerializer):
    reporter = serializers.PrimaryKeyRelatedField(read_only=True)
    reporter_name = serializers.SerializerMethodField()
    location_lat = serializers.FloatField(required=False, default=0.0)
    location_lng = serializers.FloatField(required=False, default=0.0)

    class Meta:
        model = IncidentReport
        fields = [
            "id", "reporter", "reporter_name", "category", "description",
            "location_lat", "location_lng", "is_anonymous", "status", "created_at",
        ]
        read_only_fields = ["id", "reporter", "reporter_name", "status", "created_at"]

    def get_reporter_name(self, obj):
        if obj.is_anonymous:
            return "Anonymous"
        if obj.reporter:
            return obj.reporter.display_name or getattr(obj.reporter.user, "username", "") or "Community Member"
        return "Community Member"


class SafetyAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetyAlert
        fields = [
            "id", "title", "description", "area_lat", "area_lng",
            "radius_km", "active_until", "created_at",
        ]
        read_only_fields = ["id", "created_at"]
