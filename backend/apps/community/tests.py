from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from apps.accounts.models import Profile
from apps.community.models import IncidentReport


class IncidentReportApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="password")
        self.profile = Profile.objects.create(
            user=self.user,
            firebase_uid="uid_testuser_123",
            display_name="Jane Doe",
            phone="+1234567890",
        )
        self.client.force_authenticate(user=self.user)

    def test_create_and_list_incident_reports(self):
        # Create non-anonymous incident report
        payload = {
            "category": "harassment",
            "description": "Location: Main Street\n\nSuspicious individual following people.",
            "location_lat": 37.7749,
            "location_lng": -122.4194,
            "is_anonymous": False,
        }
        res = self.client.post("/api/v1/community/reports/", data=payload)
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["category"], "harassment")
        self.assertEqual(res.data["reporter_name"], "Jane Doe")
        self.assertEqual(res.data["is_anonymous"], False)

        # Create anonymous report with default coordinates
        payload_anon = {
            "category": "unsafe_area",
            "description": "Streetlights are broken on Elm St.",
            "is_anonymous": True,
        }
        res_anon = self.client.post("/api/v1/community/reports/", data=payload_anon)
        self.assertEqual(res_anon.status_code, 201)
        self.assertEqual(res_anon.data["category"], "unsafe_area")
        self.assertEqual(res_anon.data["reporter_name"], "Anonymous")
        self.assertEqual(res_anon.data["is_anonymous"], True)

        # List all reports in community feed
        get_res = self.client.get("/api/v1/community/reports/")
        self.assertEqual(get_res.status_code, 200)
        reports = get_res.data if isinstance(get_res.data, list) else get_res.data["results"]
        self.assertEqual(len(reports), 2)
