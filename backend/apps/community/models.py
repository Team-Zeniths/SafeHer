from django.db import models

from apps.accounts.models import Profile


class IncidentReport(models.Model):
    class Category(models.TextChoices):
        HARASSMENT = "harassment", "Harassment"
        STALKING = "stalking", "Stalking"
        THEFT = "theft", "Theft"
        UNSAFE_AREA = "unsafe_area", "Unsafe area"
        TIP = "tip", "Safety tip"
        QUESTION = "question", "Question"
        OTHER = "other", "Other"

    class Status(models.TextChoices):
        OPEN = "open", "Open"
        REVIEWED = "reviewed", "Reviewed"

    reporter = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="incident_reports")
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.OTHER)
    description = models.TextField(blank=True)
    location_lat = models.FloatField(default=0.0)
    location_lng = models.FloatField(default=0.0)
    is_anonymous = models.BooleanField(
        default=False,
        help_text="If true, the reporter's identity should not be shown in Community UI, "
        "even though the FK is kept for moderation/abuse purposes.",
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.get_category_display()} report by {self.reporter}"


class SafetyAlert(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    area_lat = models.FloatField()
    area_lng = models.FloatField()
    radius_km = models.FloatField(default=1.0)
    active_until = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        Profile, on_delete=models.SET_NULL, null=True, blank=True, related_name="created_alerts"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title
