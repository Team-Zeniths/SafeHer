"""Shared helpers used by multiple apps."""

from math import asin, cos, radians, sin, sqrt


def haversine_km(lat1, lng1, lat2, lng2):
    """
    Great-circle distance between two lat/lng points in kilometers.
    Good enough for "incidents/alerts near me" filtering at city scale —
    switch to PostGIS if you outgrow this (large datasets, complex geo
    queries), but that's not needed yet.
    """
    lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
    c = 2 * asin(sqrt(a))
    earth_radius_km = 6371
    return earth_radius_km * c
