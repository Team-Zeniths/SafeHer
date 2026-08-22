from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("apps.core.urls")),
    path("api/v1/accounts/", include("apps.accounts.urls")),
    path("api/v1/journey/", include("apps.journey.urls")),
    path("api/v1/community/", include("apps.community.urls")),
    path("api/v1/history/", include("apps.history.urls")),
    path("api/v1/ai/", include("apps.ai_assistant.urls")),
]
