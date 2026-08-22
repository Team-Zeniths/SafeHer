from rest_framework import serializers

from .models import JourneySummary


class JourneySummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = JourneySummary
        fields = [
            "id", "start_point", "end_point", "started_at",
            "ended_at", "distance_km", "was_completed_safely",
        ]
        read_only_fields = ["id"]
