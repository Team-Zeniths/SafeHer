import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/journey_model.dart';

/// Journey Map Screen — shows start/end coordinates on a visual route
/// canvas and provides deep-links into Google Maps & OpenStreetMap.
class JourneyMapScreen extends StatelessWidget {
  const JourneyMapScreen({super.key, required this.journey});

  final JourneyModel journey;

  @override
  Widget build(BuildContext context) {
    final hasCoords = journey.startLat != null &&
        journey.startLng != null &&
        journey.endLat != null &&
        journey.endLng != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Journey Route'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Journey Info Header ──────────────────────────────────────
            _JourneyInfoCard(journey: journey, isDark: isDark),
            const SizedBox(height: AppSizes.lg),

            // ── Route Visual ─────────────────────────────────────────────
            if (hasCoords) ...[
              _SectionLabel('Route Visualization'),
              const SizedBox(height: AppSizes.sm),
              _RouteCanvas(journey: journey, isDark: isDark),
              const SizedBox(height: AppSizes.lg),

              // ── Coordinate Details ────────────────────────────────────
              _SectionLabel('Location Details'),
              const SizedBox(height: AppSizes.sm),
              _CoordinateCard(
                label: 'Start Point',
                lat: journey.startLat!,
                lng: journey.startLng!,
                color: AppColors.success,
                icon: Icons.trip_origin_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: AppSizes.sm),
              _CoordinateCard(
                label: 'End Point',
                lat: journey.endLat!,
                lng: journey.endLng!,
                color: AppColors.sosRed,
                icon: Icons.location_on_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: AppSizes.lg),

              // ── Open in Maps ──────────────────────────────────────────
              _SectionLabel('Open in Maps'),
              const SizedBox(height: AppSizes.sm),
              _OpenInMapsButtons(journey: journey),
            ] else ...[
              _NoCoordinatesCard(isDark: isDark),
            ],

            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Journey Info Card ─────────────────────────────────────────────────────────

class _JourneyInfoCard extends StatelessWidget {
  const _JourneyInfoCard({required this.journey, required this.isDark});
  final JourneyModel journey;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final distance = journey.distanceKm != null
        ? '${journey.distanceKm!.toStringAsFixed(2)} km'
        : 'Unknown';
    final duration = journey.durationMinutes != null
        ? '${journey.durationMinutes} min'
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Colors.white, size: 22),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  journey.startAddress,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (journey.destinationAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 30),
                const Icon(Icons.arrow_downward_rounded, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    journey.destinationAddress!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _Stat(icon: Icons.straighten_rounded, label: distance),
              const SizedBox(width: AppSizes.lg),
              _Stat(icon: Icons.timer_rounded, label: duration),
              const SizedBox(width: AppSizes.lg),
              _Stat(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.color = Colors.white70});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Route Canvas ──────────────────────────────────────────────────────────────

class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas({required this.journey, required this.isDark});
  final JourneyModel journey;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2137) : const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : const Color(0xFF90CAF9),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: [
            // Grid lines (map-like background)
            CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(isDark: isDark),
            ),
            // Route path
            CustomPaint(
              size: Size.infinite,
              painter: _RoutePainter(
                startLat: journey.startLat!,
                startLng: journey.startLng!,
                endLat: journey.endLat!,
                endLng: journey.endLng!,
              ),
            ),
            // Distance badge overlay
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      journey.distanceKm != null
                          ? '${journey.distanceKm!.toStringAsFixed(2)} km'
                          : 'Distance unknown',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            // Start label
            Positioned(
              bottom: 12,
              left: 16,
              child: _MapLabel('Start', AppColors.success, Icons.trip_origin_rounded),
            ),
            // End label
            Positioned(
              bottom: 12,
              right: 16,
              child: _MapLabel('End', AppColors.sosRed, Icons.location_on_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel(this.text, this.color, this.icon);
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Grid Painter (map-like background) ───────────────────────────────────────

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF1A3A5C).withValues(alpha: 0.5)
          : const Color(0xFF90CAF9).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}

// ── Route Painter ─────────────────────────────────────────────────────────────

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  final double startLat, startLng, endLat, endLng;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 48.0;

    // Map lat/lng → canvas coordinates.
    // Flip lat because canvas Y increases downward, lat increases upward.
    final latMin = math.min(startLat, endLat);
    final latMax = math.max(startLat, endLat);
    final lngMin = math.min(startLng, endLng);
    final lngMax = math.max(startLng, endLng);

    // Add 20% padding to avoid pins sitting on the edge
    final latRange = (latMax - latMin) == 0 ? 0.001 : (latMax - latMin) * 1.4;
    final lngRange = (lngMax - lngMin) == 0 ? 0.001 : (lngMax - lngMin) * 1.4;

    final latCenter = (latMin + latMax) / 2;
    final lngCenter = (lngMin + lngMax) / 2;

    Offset toCanvas(double lat, double lng) {
      final x = (lng - (lngCenter - lngRange / 2)) / lngRange * (size.width - padding * 2) + padding;
      final y = (1 - (lat - (latCenter - latRange / 2)) / latRange) * (size.height - padding * 2) + padding;
      return Offset(x, y);
    }

    final startPt = toCanvas(startLat, startLng);
    final endPt = toCanvas(endLat, endLng);

    // ── Dashed route line ─────────────────────────────────────────────
    final dashPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, startPt, endPt, dashPaint, dashLength: 10, gapLength: 6);

    // ── Route shadow / glow ───────────────────────────────────────────
    final glowPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(startPt, endPt, glowPaint);

    // ── Start pin (green circle) ──────────────────────────────────────
    _drawPin(canvas, startPt, AppColors.success, isStart: true);

    // ── End pin (red teardrop) ────────────────────────────────────────
    _drawPin(canvas, endPt, AppColors.sosRed, isStart: false);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 10,
    double gapLength = 5,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final total = math.sqrt(dx * dx + dy * dy);
    final nx = dx / total;
    final ny = dy / total;

    double drawn = 0;
    bool drawing = true;

    while (drawn < total) {
      final segLen = drawing ? dashLength : gapLength;
      final next = math.min(drawn + segLen, total);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + nx * drawn, start.dy + ny * drawn),
          Offset(start.dx + nx * next, start.dy + ny * next),
          paint,
        );
      }
      drawn = next;
      drawing = !drawing;
    }
  }

  void _drawPin(Canvas canvas, Offset center, Color color, {required bool isStart}) {
    // Outer glow
    canvas.drawCircle(
      center,
      isStart ? 18 : 16,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    // White ring
    canvas.drawCircle(
      center,
      isStart ? 13 : 12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    // Colored fill
    canvas.drawCircle(
      center,
      isStart ? 10 : 9,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Inner dot for start, X for end
    if (isStart) {
      canvas.drawCircle(
        center,
        4,
        Paint()..color = Colors.white,
      );
    } else {
      final iconPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center.translate(-3, -3), center.translate(3, 3), iconPaint);
      canvas.drawLine(center.translate(3, -3), center.translate(-3, 3), iconPaint);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.startLat != startLat ||
      old.startLng != startLng ||
      old.endLat != endLat ||
      old.endLng != endLng;
}

// ── Coordinate Card ───────────────────────────────────────────────────────────

class _CoordinateCard extends StatelessWidget {
  const _CoordinateCard({
    required this.label,
    required this.lat,
    required this.lng,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final double lat, lng;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Open in Maps Buttons ──────────────────────────────────────────────────────

class _OpenInMapsButtons extends StatelessWidget {
  const _OpenInMapsButtons({required this.journey});
  final JourneyModel journey;

  Future<void> _openGoogleMaps(BuildContext context) async {
    final sLat = journey.startLat!;
    final sLng = journey.startLng!;
    final eLat = journey.endLat!;
    final eLng = journey.endLng!;

    // Google Maps directions URL
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$sLat,$sLng'
      '&destination=$eLat,$eLng'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _showLaunchFailure(context);
    }
  }

  Future<void> _openOSM(BuildContext context) async {
    final sLat = journey.startLat!;
    final sLng = journey.startLng!;
    final eLat = journey.endLat!;
    final eLng = journey.endLng!;

    // OpenStreetMap route
    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_foot'
      '&route=$sLat%2C$sLng%3B$eLat%2C$eLng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _showLaunchFailure(context);
    }
  }

  void _showLaunchFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Couldn't open a maps app or browser. Make sure one is installed.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapsButton(
          label: 'Open in Google Maps',
          subtitle: 'View walking directions',
          icon: Icons.map_rounded,
          color: const Color(0xFF4285F4),
          onTap: () => _openGoogleMaps(context),
        ),
        const SizedBox(height: AppSizes.sm),
        _MapsButton(
          label: 'Open in OpenStreetMap',
          subtitle: 'View route on OSM',
          icon: Icons.public_rounded,
          color: const Color(0xFF7BC742),
          onTap: () => _openOSM(context),
        ),
      ],
    );
  }
}

class _MapsButton extends StatelessWidget {
  const _MapsButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle, style: TextStyle(color: AppColors.textMutedLight, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── No Coordinates Fallback ───────────────────────────────────────────────────

class _NoCoordinatesCard extends StatelessWidget {
  const _NoCoordinatesCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded, size: 56, color: AppColors.textMutedLight.withValues(alpha: 0.5)),
          const SizedBox(height: AppSizes.md),
          Text(
            'No location data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'GPS coordinates were not recorded for this journey.\nEnable location permission before starting a journey.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textMutedLight,
      ),
    );
  }
}
