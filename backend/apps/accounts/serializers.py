from rest_framework import serializers

from .models import EmergencyContact, Profile, SosLog


class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ["id", "display_name", "phone", "secret_code", "created_at"]
        read_only_fields = ["id", "created_at"]


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = ["id", "name", "phone", "relationship", "created_at"]
        read_only_fields = ["id", "created_at"]


class SosLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SosLog
        fields = ["id", "location_lat", "location_lng", "triggered_at", "resolved_at"]
        read_only_fields = ["id"]
