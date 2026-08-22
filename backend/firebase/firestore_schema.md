# Firestore Schema (owned by Firebase, not Django)

Collections the Flutter app reads/writes directly via the Firebase SDK.
Django never touches these directly — if it needs this data, it reads it
through the Firebase Admin SDK (e.g. to snapshot a finished journey into
Postgres for the History tab).

## users/{uid}
- displayName, phone, secretCode, emergencyContactIds: []

## journeys/{journeyId}          <- Journey tab, live only
- userId, status (active|ended), startPoint, endPoint,
  currentLocation (geopoint, updated every N seconds while active),
  eta, sharedWith: [contactIds]
- On journey end: Django's journey app can pull this doc via a Cloud
  Function webhook or a periodic job and store a permanent summary
  in Postgres for the History tab.

## sos_events/{eventId}
- userId, location (geopoint), timestamp, status
- Writing a doc here triggers a Cloud Function -> FCM push to emergency
  contacts. Django's history app stores the permanent record afterward.

## fcm_tokens/{uid}
- token, updatedAt   (device push token, refreshed on app login)
