from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

User = get_user_model()


class DevAuthResetPasswordTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.register_url = "/api/v1/auth/dev-register/"
        self.login_url = "/api/v1/auth/dev-login/"
        self.reset_password_url = "/api/v1/auth/dev-reset-password/"

        # Register a test user
        self.user_data = {
            "email": "sarah@example.com",
            "password": "Password123",
            "full_name": "Sarah Connor",
            "phone": "+919876543210",
        }
        res = self.client.post(self.register_url, self.user_data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

    def test_reset_password_success(self):
        # Reset password with new credentials
        payload = {
            "email": "sarah@example.com",
            "password": "NewSecretPassword456",
        }
        response = self.client.post(self.reset_password_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("detail", response.data)

        # Verify that old password no longer works
        old_login_res = self.client.post(
            self.login_url,
            {"email": "sarah@example.com", "password": "Password123"},
            format="json",
        )
        self.assertEqual(old_login_res.status_code, status.HTTP_401_UNAUTHORIZED)

        # Verify that new password works for login
        new_login_res = self.client.post(
            self.login_url,
            {"email": "sarah@example.com", "password": "NewSecretPassword456"},
            format="json",
        )
        self.assertEqual(new_login_res.status_code, status.HTTP_200_OK)
        self.assertIn("token", new_login_res.data)
        self.assertEqual(new_login_res.data["user"]["email"], "sarah@example.com")

    def test_reset_password_nonexistent_user(self):
        payload = {
            "email": "nonexistent@example.com",
            "password": "NewPassword123",
        }
        response = self.client.post(self.reset_password_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data["detail"], "No account found with this email address.")

    def test_reset_password_missing_fields(self):
        # Missing password
        response = self.client.post(
            self.reset_password_url,
            {"email": "sarah@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        # Missing email
        response = self.client.post(
            self.reset_password_url,
            {"password": "NewPassword123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
