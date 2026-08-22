# Architecture

## Ownership map (which tab talks to what)

| Tab       | Talks to                                   | Why                                                                 |
|-----------|---------------------------------------------|----------------------------------------------------------------------|
| Home      | Firebase (Auth, FCM) + Django (contacts)   | SOS trigger is realtime/Firebase; emergency contact list is Django   |
| Journey   | Firestore directly (live) + Django (after) | Live location/ETA needs realtime listeners; ended journeys get archived to Django for History |
| AI        | Django only                                 | Orchestration, safety scoring, and recommendation logic live server-side |
| Community | Django only                                 | Relational queries (filter by location/date/type) fit DRF + Postgres, not Firestore |
| History   | Django only                                 | Read-only aggregation across journey/SOS/community/AI records         |

## Request flow examples

**SOS button pressed (Home tab):**
1. Flutter writes a doc to Firestore `sos_events/{id}` directly (no Django round-trip — speed matters here).
2. A Firebase Cloud Function trigger on that write sends FCM pushes to the user's emergency contacts.
3. Separately (not blocking the SOS), Flutter calls `POST /api/v1/accounts/sos-log/` on Django so the event is queryable later from the History tab.

**Starting a safe journey (Journey tab):**
1. Flutter creates `journeys/{id}` in Firestore and starts writing `currentLocation` updates on an interval — all client-to-Firestore, Django is not involved while the journey is live.
2. On "End Journey," Flutter calls `POST /api/v1/journey/summaries/` on Django with the final route/duration, so it becomes a permanent, queryable record. The live Firestore doc can then be deleted or archived.

**Reporting an incident (Community tab):**
1. Flutter calls Django directly: `POST /api/v1/community/reports/`. No Firestore involved — this is a standard relational write with fields like location, category, description.

**Viewing History tab:**
1. Flutter calls Django: `GET /api/v1/history/journeys/`, `GET /api/v1/history/sos-events/`, `GET /api/v1/history/community-reports/`. All reads, all from Postgres — nothing hits Firestore at this point since journey summaries were already archived.

**AI tab — asking for a safer route:**
1. Flutter calls Django: `POST /api/v1/ai/route-recommendation/` with start/end points.
2. `apps/ai_assistant/services.py` combines: (a) a call to your chosen LLM/ML provider, and (b) recent Community incident reports near that route (queried from the `community` app's models), to produce a scored recommendation.
3. Django returns the recommendation; Flutter renders it. Optionally logged to `ai_assistant` models for the History tab to show later.

## Auth flow

Every Django request from the app carries `Authorization: Bearer <firebase_id_token>`.
`apps/core/firebase_auth.py` verifies that token against Firebase Admin SDK on every
request — Django never issues its own tokens or passwords. This keeps identity
single-sourced in Firebase while Django still gets a normal `request.user` to apply
DRF permissions against.
