from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import EmergencyContactViewSet, MeView, SosLogCancelView, SosLogCreateView

router = DefaultRouter()
router.register("contacts", EmergencyContactViewSet, basename="emergency-contact")

urlpatterns = [
    path("me/", MeView.as_view(), name="profile-me"),
    path("sos-log/", SosLogCreateView.as_view(), name="sos-log-create"),
    path("sos-log/cancel/", SosLogCancelView.as_view(), name="sos-log-cancel"),
] + router.urls
