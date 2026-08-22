"""Shared DRF permission classes used across apps."""

from rest_framework import permissions


class IsOwner(permissions.BasePermission):
    """
    Object-level permission: only the `owner` (or `reporter`) of a record can
    modify it. Read access is left to the view's other permission classes —
    this only gates write operations.

    Expects the model instance to have an `owner` or `reporter` FK to Profile,
    and Profile to have a `user` FK to the authenticated Django User.
    """

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True

        owner_profile = getattr(obj, "owner", None) or getattr(obj, "reporter", None)
        if owner_profile is None:
            return False
        return owner_profile.user_id == request.user.id
