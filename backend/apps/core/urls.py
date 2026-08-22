from django.urls import path
from .dev_auth import dev_login, dev_me, dev_register, dev_reset_password

urlpatterns = [
    path("dev-register/", dev_register, name="dev-register"),
    path("dev-login/", dev_login, name="dev-login"),
    path("dev-me/", dev_me, name="dev-me"),
    path("dev-reset-password/", dev_reset_password, name="dev-reset-password"),
    path("dev-forgot-password/", dev_reset_password, name="dev-forgot-password"),
]

