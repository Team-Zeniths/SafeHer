from rest_framework import permissions
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import APIView

from . import services
from .models import AiRecommendationLog
from .serializers import ChatRequestSerializer, RouteRecommendationRequestSerializer


class ChatView(APIView):
    """POST /api/v1/ai/chat/ — {"message": "..."}"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChatRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = serializer.validated_data["message"]

        try:
            reply = services.get_chat_response(message)
        except Exception as exc:
            # Avoid leaking the actual API key or provider internals.
            raise APIException(
                "AI service is temporarily unavailable. Check the server's "
                "GEMINI_API_KEY and GEMINI_MODEL configuration."
            ) from exc

        AiRecommendationLog.objects.create(
            owner=request.user.profile,
            query_type=AiRecommendationLog.QueryType.CHAT,
            input_summary=message,
            output_summary=reply,
        )
        return Response({"reply": reply})


class RouteRecommendationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = RouteRecommendationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        result = services.get_route_recommendation(
            data["start_point"], data["end_point"]
        )
        AiRecommendationLog.objects.create(
            owner=request.user.profile,
            query_type=AiRecommendationLog.QueryType.ROUTE,
            input_summary=f"{data['start_point']} -> {data['end_point']}",
            output_summary=result["recommended_route_summary"],
        )
        return Response(result)


class AreaScoreView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        if lat is None or lng is None:
            return Response(
                {"detail": "lat and lng query params are required."}, status=400
            )
        result = services.get_area_safety_score(float(lat), float(lng))
        AiRecommendationLog.objects.create(
            owner=request.user.profile,
            query_type=AiRecommendationLog.QueryType.AREA_SCORE,
            input_summary=f"lat={lat}, lng={lng}",
            output_summary=str(result["score"]),
        )
        return Response(result)
