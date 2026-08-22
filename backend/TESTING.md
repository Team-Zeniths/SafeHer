# Manual Testing — Firebase Auth Flow

This project has no automated test suite yet (per the build order — step 2 only
asked for manual verification instructions). Here's how to confirm the auth flow
end-to-end once you have real Firebase credentials.

## Setup

1. Download a real service account key: Firebase Console → Project Settings →
   Service Accounts → Generate new private key → save as `firebase/service_account.json`
   (already gitignored, don't commit it).
2. `cp .env.example .env` and adjust `FIREBASE_CREDENTIALS_PATH` if needed.
3. `pip install -r requirements.txt`
4. `python manage.py migrate`
5. `python manage.py runserver`

## Getting a real ID token to test with

The token has to come from Firebase Auth itself — you can't fake one. Easiest
options:
- Run the Flutter app against the same Firebase project, log in, and print
  `await FirebaseAuth.instance.currentUser.getIdToken()` to the console/log.
- Or use the Firebase Auth REST API directly with a test phone number
  (Firebase Console → Authentication → Sign-in method → Phone → add a test
  number with a fixed OTP) and exchange it for an ID token via
  `POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber`.

## Verifying the flow

```bash
# 1. No token — should be 401
curl -i http://127.0.0.1:8000/api/v1/accounts/me/

# 2. Garbage token — should be 401 with a clear "Invalid Firebase token" message
curl -i -H "Authorization: Bearer garbage" http://127.0.0.1:8000/api/v1/accounts/me/

# 3. Real token — should be 200 and auto-create a Profile + User on first call
curl -i -H "Authorization: Bearer <REAL_ID_TOKEN>" http://127.0.0.1:8000/api/v1/accounts/me/

# 4. Confirm the Profile actually got created
python manage.py shell -c "from apps.accounts.models import Profile; print(Profile.objects.all())"
```

If step 3 returns 200 and step 4 shows a row, the Firebase → Django user
mapping in `apps/core/firebase_auth.py` is working end-to-end.

## What was verified in this sandbox (no real Firebase project available here)

- `python manage.py check` — passes, no system errors.
- `python manage.py makemigrations` — clean migrations generated for accounts,
  journey, community, ai_assistant (history has no models, correctly produced none).
- `python manage.py migrate` — applies cleanly against SQLite.
- Server boots and every protected endpoint correctly returns `401` with no
  token and with a garbage token, with the error message confirming it's
  failing at Firebase verification (missing `service_account.json` in this
  sandbox) rather than a code bug.
- Not verified here: a real end-to-end request with a genuine Firebase ID
  token, since that requires a live Firebase project. Do that first before
  trusting this in front of the real app.
