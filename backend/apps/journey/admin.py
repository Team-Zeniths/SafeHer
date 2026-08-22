from django.contrib import admin

from .models import JourneySummary


@admin.register(JourneySummary)
class JourneySummaryAdmin(admin.ModelAdmin):
    list_display = ("owner", "start_point", "end_point", "ended_at", "was_completed_safely")
    list_filter = ("was_completed_safely",)
