from django.urls import path

from .views import IncidentReportDetailView, IncidentReportListCreateView, SafetyAlertListView, SafetyMapView

urlpatterns = [
    path("reports/", IncidentReportListCreateView.as_view(), name="incident-report-list"),
    path("reports/<int:pk>/", IncidentReportDetailView.as_view(), name="incident-report-detail"),
    path("alerts/", SafetyAlertListView.as_view(), name="safety-alert-list"),
    path("map/", SafetyMapView.as_view(), name="safety-map"),
]
