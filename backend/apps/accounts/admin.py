from django.contrib import admin

from .models import EmergencyContact, Profile, SosLog


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "phone", "firebase_uid", "created_at")
    search_fields = ("display_name", "phone", "firebase_uid")


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ("name", "phone", "relationship", "owner")
    search_fields = ("name", "phone")


@admin.register(SosLog)
class SosLogAdmin(admin.ModelAdmin):
    list_display = ("owner", "triggered_at", "resolved_at")
    list_filter = ("triggered_at",)
