from django.db import models

from apps.accounts.models import Profile


class AiRecommendationLog(models.Model):
    class QueryType(models.TextChoices):
        ROUTE = "route", "Route recommendation"
        AREA_SCORE = "area_score", "Area safety score"
        CHAT = "chat", "Chat"

    owner = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="ai_recommendations")
    query_type = models.CharField(max_length=20, choices=QueryType.choices)
    input_summary = models.TextField(blank=True)
    output_summary = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.get_query_type_display()} for {self.owner}"
