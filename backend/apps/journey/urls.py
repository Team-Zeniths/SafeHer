from django.urls import path

from .views import JourneySummaryListCreateView

urlpatterns = [
    path("summaries/", JourneySummaryListCreateView.as_view(), name="journey-summary-list"),
]
