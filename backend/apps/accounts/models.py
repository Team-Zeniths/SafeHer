from django.conf import settings
from django.db import models


class Profile(models.Model):
    """
    Extends Django's built-in User with the fields SafeHer needs.
    `firebase_uid` is the join key apps.core.firebase_auth uses to map a
    verified Firebase ID token to this row (and its linked User).
    """

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="profile")
    firebase_uid = models.CharField(max_length=128, unique=True, db_index=True)
    display_name = models.CharField(max_length=150, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    secret_code = models.CharField(
        max_length=50, blank=True, help_text="Duress code — e.g. saying/entering this can signal distress silently."
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.display_name or self.phone or self.firebase_uid


class EmergencyContact(models.Model):
    owner = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="emergency_contacts")
    name = models.CharField(max_length=150)
    phone = models.CharField(max_length=20)
    relationship = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.relationship})" if self.relationship else self.name


class SosLog(models.Model):
    """
    Permanent record of an SOS event. The live event itself (and the FCM push
    to emergency contacts) is handled by Firestore + Cloud Functions — this
    row is written by Flutter afterward so the History tab has something to
    query. See firebase/firestore_schema.md for the Firestore side.
    """

    owner = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="sos_logs")
    location_lat = models.FloatField()
    location_lng = models.FloatField()
    triggered_at = models.DateTimeField()
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-triggered_at"]

    def __str__(self):
        return f"SOS by {self.owner} at {self.triggered_at}"
