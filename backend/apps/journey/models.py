from django.db import models

from apps.accounts.models import Profile


class JourneySummary(models.Model):
    """
    Archived record of a finished journey. Live tracking (current location,
    ETA) happens in Firestore while the journey is active — Flutter posts
    here once via POST /api/v1/journey/summaries/ after calling "End Journey",
    so the History tab has a permanent, queryable record.
    See firebase/firestore_schema.md for the live-journey Firestore shape.
    """

    owner = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="journey_summaries")
    start_point = models.CharField(max_length=255)
    end_point = models.CharField(max_length=255)
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField()
    distance_km = models.FloatField(null=True, blank=True)
    was_completed_safely = models.BooleanField(default=True)

    class Meta:
        ordering = ["-ended_at"]

    def __str__(self):
        return f"{self.owner}: {self.start_point} -> {self.end_point}"
