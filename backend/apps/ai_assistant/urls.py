from django.urls import path

from .views import AreaScoreView, ChatView, RouteRecommendationView

urlpatterns = [
    path("chat/", ChatView.as_view(), name="ai-chat"),
    path("route-recommendation/", RouteRecommendationView.as_view(), name="ai-route-recommendation"),
    path("area-score/", AreaScoreView.as_view(), name="ai-area-score"),
]
