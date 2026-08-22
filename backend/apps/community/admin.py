from django.contrib import admin

from .models import IncidentReport, SafetyAlert


@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    list_display = ("category", "reporter", "status", "created_at")
    list_filter = ("category", "status")
    search_fields = ("description",)


@admin.register(SafetyAlert)
class SafetyAlertAdmin(admin.ModelAdmin):
    list_display = ("title", "radius_km", "active_until", "created_by")
    list_filter = ("active_until",)
