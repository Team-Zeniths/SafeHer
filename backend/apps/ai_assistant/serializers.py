from rest_framework import serializers

from .models import AiRecommendationLog


class AiRecommendationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AiRecommendationLog
        fields = ["id", "query_type", "input_summary", "output_summary", "created_at"]
        read_only_fields = ["id", "created_at"]


class ChatRequestSerializer(serializers.Serializer):
    message = serializers.CharField()


class RouteRecommendationRequestSerializer(serializers.Serializer):
    start_point = serializers.CharField()
    end_point = serializers.CharField()
