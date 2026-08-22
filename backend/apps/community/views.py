from django.utils import timezone
from rest_framework import generics, permissions

from apps.core.permissions import IsOwner
from apps.core.utils import haversine_km

from .models import IncidentReport, SafetyAlert
from .serializers import IncidentReportSerializer, SafetyAlertSerializer


class _NearbyFilterMixin:
    """
    Shared lat/lng/radius_km query-param filtering for the near-me style
    endpoints below. Filtering is done in Python via Haversine rather than in
    SQL — fine at this dataset size; move to PostGIS if that changes.
    """

    lat_field = "location_lat"
    lng_field = "location_lng"

    def filter_by_radius(self, queryset):
        lat = self.request.query_params.get("lat")
        lng = self.request.query_params.get("lng")
        radius_km = self.request.query_params.get("radius_km")

        if lat is None or lng is None or radius_km is None:
            return queryset  # no location filter requested — return unfiltered

        lat, lng, radius_km = float(lat), float(lng), float(radius_km)
        ids = [
            obj.id
            for obj in queryset
            if haversine_km(lat, lng, getattr(obj, self.lat_field), getattr(obj, self.lng_field)) <= radius_km
        ]
        return queryset.filter(id__in=ids)


class IncidentReportListCreateView(_NearbyFilterMixin, generics.ListCreateAPIView):
    """
    GET  /api/v1/community/reports/?lat=&lng=&radius_km=&category=
    POST /api/v1/community/reports/
    """

    serializer_class = IncidentReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = IncidentReport.objects.all()
        category = self.request.query_params.get("category")
        if category:
            qs = qs.filter(category=category)
        return self.filter_by_radius(qs)

    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user.profile)


class IncidentReportDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PATCH/DELETE /api/v1/community/reports/{id}/"""

    queryset = IncidentReport.objects.all()
    serializer_class = IncidentReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwner]


class SafetyAlertListView(_NearbyFilterMixin, generics.ListAPIView):
    """GET /api/v1/community/alerts/?lat=&lng=&radius_km= — active alerts near a location."""

    serializer_class = SafetyAlertSerializer
    permission_classes = [permissions.IsAuthenticated]
    lat_field = "area_lat"
    lng_field = "area_lng"

    def get_queryset(self):
        qs = SafetyAlert.objects.filter(active_until__gte=timezone.now()) | SafetyAlert.objects.filter(
            active_until__isnull=True
        )
        return self.filter_by_radius(qs)


class SafetyMapView(SafetyAlertListView):
    """
    GET /api/v1/community/map/
    Same underlying data as SafetyAlertListView for now — kept as a distinct
    endpoint per API_CONTRACT.md in case the map view later needs a different
    shape (e.g. combining alerts + open incident reports as pins).
    """
