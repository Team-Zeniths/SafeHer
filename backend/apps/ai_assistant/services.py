"""
AI orchestration for SafeHer.

Gemini is called only from the Django backend. The API key is read from
GEMINI_API_KEY in backend/.env and is never sent to Flutter.
"""

import os
import re

from django.utils import timezone
from google import genai
from google.genai import types

from apps.community.models import IncidentReport
from apps.core.utils import haversine_km

NEARBY_RADIUS_KM = 2.0
NEARBY_LOOKBACK_DAYS = 20

_MOCK_QA = {
    "late night travel tips": (
        "Stick to well-lit main roads and avoid shortcuts through parks or "
        "alleys. Share your live location with a trusted contact before you "
        "leave, and keep your phone charged above 20%."
    ),
    "how to stay safe in cabs": (
        "Verify the driver's name, photo, and plate number match the app "
        "before getting in. Share your trip status with a contact and, if "
        "anything feels wrong, move to a public place."
    ),
    "what to do in an emergency": (
        "Use SafeHer's SOS feature and contact local emergency services "
        "immediately if you are in danger. Move toward a public, well-lit "
        "place while waiting for help."
    ),
    "best safety apps": (
        "Look for features such as live location sharing, one-tap SOS, "
        "offline emergency information, and reliable emergency contacts."
    ),
    "building a safety network": (
        "Choose a few trusted emergency contacts and agree on a simple "
        "check-in routine for late trips. Set everything up before you need it."
    ),
}


def _normalize(text: str) -> str:
    text = re.sub(r"[^\w\s]", "", text, flags=re.UNICODE)
    return re.sub(r"\s+", " ", text).strip().lower()


_MOCK_QA_NORMALIZED = {_normalize(k): v for k, v in _MOCK_QA.items()}

_SYSTEM_PROMPT = (
    "You are SafeHer's safety assistant. Give short, calm, practical safety "
    "advice. Do not provide medical or legal advice. For urgent or "
    "life-threatening situations, tell the user to contact local emergency "
    "services immediately and use SafeHer's SOS feature. Do not invent "
    "specific emergency numbers unless the user provides their country."
)

_client = None


def _get_client():
    """Create the Gemini client lazily from the server-side environment key."""
    global _client
    if _client is not None:
        return _client

    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key or api_key == "your-gemini-api-key-here":
        raise RuntimeError(
            "Gemini API key is not configured. Set GEMINI_API_KEY in backend/.env."
        )

    _client = genai.Client(api_key=api_key)
    return _client


def call_llm(prompt: str) -> str:
    """Send one prompt to Gemini and return plain text."""
    response = _get_client().models.generate_content(
        model=os.environ.get("GEMINI_MODEL", "gemini-3.6-flash"),
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=_SYSTEM_PROMPT,
            temperature=0.3,
            max_output_tokens=700,
        ),
    )
    text = getattr(response, "text", None)
    if not text:
        raise RuntimeError("Gemini returned an empty response.")
    return text.strip()


def get_area_safety_score(lat: float, lng: float) -> dict:
    cutoff = timezone.now() - timezone.timedelta(days=NEARBY_LOOKBACK_DAYS)
    nearby_reports = [
        r
        for r in IncidentReport.objects.filter(created_at__gte=cutoff)
        if haversine_km(lat, lng, r.location_lat, r.location_lng) <= NEARBY_RADIUS_KM
    ]
    score = max(0, 100 - len(nearby_reports) * 10)
    return {
        "score": score,
        "nearby_report_count": len(nearby_reports),
        "categories": sorted({r.category for r in nearby_reports}),
    }


def get_route_recommendation(start_point: str, end_point: str) -> dict:
    return {
        "start_point": start_point,
        "end_point": end_point,
        "recommended_route_summary": (
            "Route scoring is not connected to a live maps provider yet."
        ),
        "safety_notes": [],
    }


def get_chat_response(message: str) -> str:
    """
    Use Gemini for every non-empty user message. Quick suggestions keep their
    deterministic demo answers so the app remains useful if Gemini is down.
    """
    key = _normalize(message)
    if key in _MOCK_QA_NORMALIZED:
        return _MOCK_QA_NORMALIZED[key]
    return call_llm(message)
