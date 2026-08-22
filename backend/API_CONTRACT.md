# API Contract

Concrete enough to implement directly from. Adjust field names to taste, but keep
the shape — it's derived from the app's actual IA (safety-app tabs).

## apps/accounts

**Model `Profile`** (extends/links to Django User, keyed by Firebase UID)
- `firebase_uid` (unique), `display_name`, `phone`, `secret_code` (for duress signaling)

**Model `EmergencyContact`**
- `owner` (FK Profile), `name`, `phone`, `relationship`

**Model `SosLog`** (permanent record; live event itself is in Firestore)
- `owner` (FK Profile), `location_lat`, `location_lng`, `triggered_at`, `resolved_at`

Endpoints:
- `GET/PATCH /api/v1/accounts/me/` — current user's profile
- `GET/POST /api/v1/accounts/contacts/` — list/add emergency contacts
- `DELETE /api/v1/accounts/contacts/{id}/`
- `POST /api/v1/accounts/sos-log/` — archive a completed SOS event from Firestore

## apps/journey

**Model `JourneySummary`** (archived after a live Firestore journey ends)
- `owner` (FK Profile), `start_point`, `end_point`, `started_at`, `ended_at`, `distance_km`, `was_completed_safely` (bool)

Endpoints:
- `POST /api/v1/journey/summaries/` — archive a finished journey
- `GET /api/v1/journey/summaries/` — list past journeys (also surfaced via History)

## apps/community

**Model `IncidentReport`**
- `reporter` (FK Profile), `category` (choices: harassment/theft/lighting/other), `description`, `location_lat`, `location_lng`, `created_at`, `status` (open/reviewed)

**Model `SafetyAlert`**
- `title`, `description`, `area_lat`, `area_lng`, `radius_km`, `active_until`, `created_by` (admin/staff)

Endpoints:
- `GET/POST /api/v1/community/reports/` — list (filterable by lat/lng/radius/category) / create
- `GET /api/v1/community/alerts/` — active alerts near a location
- `GET /api/v1/community/map/` — pins for the safety map view

## apps/history

Read-only, aggregates the above. No new models needed initially.

Endpoints:
- `GET /api/v1/history/journeys/`
- `GET /api/v1/history/sos-events/`
- `GET /api/v1/history/community-reports/?reporter=me`
- `GET /api/v1/history/ai-recommendations/`

## apps/ai_assistant

**Model `AiRecommendationLog`**
- `owner` (FK Profile), `query_type` (route/area_score/chat), `input_summary`, `output_summary`, `created_at`

Endpoints:
- `POST /api/v1/ai/chat/` — general safety Q&A
- `POST /api/v1/ai/route-recommendation/` — start/end point in, scored route(s) out
- `GET /api/v1/ai/area-score/?lat=&lng=` — safety score for a point, blends Community reports + external data

## Auth header (every endpoint above)

```
Authorization: Bearer <firebase_id_token>
```
Verified in `apps/core/firebase_auth.py`. No endpoint here should accept unauthenticated
requests except health checks.
