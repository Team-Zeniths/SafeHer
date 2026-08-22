from django.contrib import admin

from .models import AiRecommendationLog


@admin.register(AiRecommendationLog)
class AiRecommendationLogAdmin(admin.ModelAdmin):
    list_display = ("owner", "query_type", "created_at")
    list_filter = ("query_type",)
