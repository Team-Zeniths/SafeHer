import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../providers/journey_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../../models/journey_model.dart';

/// Journey module main screen.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JourneyProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.watch<JourneyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Journey Tracker')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.sm),
              // Active journey card
              if (jp.hasActiveJourney) ...[
                _ActiveJourneyCard(journey: jp.activeJourney!),
                const SizedBox(height: AppSizes.lg),
              ] else ...[
                _StartJourneyCard(),
                const SizedBox(height: AppSizes.lg),
              ],

              // Quick stats
              const _JourneyStatsRow(),
              const SizedBox(height: AppSizes.lg),

              // History
              SectionHeader(
                title: 'Journey History',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSizes.md),
              if (jp.status == JourneyProviderStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (jp.history.isEmpty)
                EmptyStateWidget(
                  icon: Icons.route_outlined,
                  title: 'No journeys yet',
                  subtitle: 'Start a journey to track your safety on the go.',
                  iconColor: AppColors.info,
                )
              else
                ...jp.history.map((j) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: _JourneyHistoryCard(journey: j),
                    )),
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartJourneyCard extends StatefulWidget {
  @override
  State<_StartJourneyCard> createState() => _StartJourneyCardState();
}

class _StartJourneyCardState extends State<_StartJourneyCard> {
  final _destCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Colors.white, size: 28),
              const SizedBox(width: AppSizes.sm),
              Text('Start Journey', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Share your route for extra safety', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: AppSizes.md),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            child: TextField(
              controller: _destCtrl,
              decoration: const InputDecoration(
                hintText: 'Where are you going? (optional)',
                prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF1565C0)),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      final jp = context.read<JourneyProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await jp.startJourney(
                            startAddress: 'Current Location',
                            destinationAddress: _destCtrl.text.trim().isEmpty ? null : _destCtrl.text.trim(),
                          );
                      if (mounted) {
                        setState(() => _isLoading = false);
                        if (!ok) {
                          final err = jp.errorMessage;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Could not start journey: ${err ?? "unknown error"}')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
              label: Text(_isLoading ? 'Starting...' : 'Start Journey', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJourneyCard extends StatelessWidget {
  const _ActiveJourneyCard({required this.journey});
  final JourneyModel journey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('Journey Active', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final jp = context.read<JourneyProvider>();
                  final ok = await jp.endJourney();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not end journey: ${jp.errorMessage ?? "unknown error"}')),
                    );
                  }
                },
                child: const Text('End Journey', style: TextStyle(color: AppColors.sosRed, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _InfoRow(Icons.my_location_rounded, 'From', journey.startAddress),
          if (journey.destinationAddress != null) ...[
            const SizedBox(height: 4),
            _InfoRow(Icons.location_on_rounded, 'To', journey.destinationAddress!),
          ],
          const SizedBox(height: AppSizes.md),
          Builder(builder: (context) {
            final contactCount = context.watch<ContactsProvider>().contacts.length;
            final label = contactCount == 0
                ? 'No contacts added yet — add contacts to share location'
                : 'Live location shared with $contactCount contact${contactCount == 1 ? '' : 's'}';
            final color = contactCount == 0 ? AppColors.textMutedLight : AppColors.success;
            return Row(
              children: [
                Icon(Icons.share_location_rounded, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
              ],
            );
          }),
          // View on Map — only shown once journey is active (has start coords)
          if (journey.startLat != null) ...[
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.push('/journey/map', extra: journey),
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text('View Start Location on Map'),
                style: TextButton.styleFrom(foregroundColor: AppColors.info),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMutedLight),
        const SizedBox(width: 6),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _JourneyStatsRow extends StatelessWidget {
  const _JourneyStatsRow();

  @override
  Widget build(BuildContext context) {
    final jp = context.watch<JourneyProvider>();
    final contactCount = context.watch<ContactsProvider>().contacts.length;
    final totalJourneys = jp.history.length;
    // Sum up distance from completed journeys; show 0.0 for new users
    final totalDistance = jp.history.fold<double>(0, (sum, j) => sum + (j.distanceKm ?? 0));
    final distanceLabel = totalDistance == 0 ? '0 km' : '${totalDistance.toStringAsFixed(1)} km';

    return Row(
      children: [
        _StatCard('$totalJourneys', 'Total\nJourneys', Icons.route_rounded, const Color(0xFF1565C0)),
        const SizedBox(width: AppSizes.sm),
        _StatCard(distanceLabel, 'Total\nDistance', Icons.straight_rounded, AppColors.success),
        const SizedBox(width: AppSizes.sm),
        _StatCard('$contactCount', 'Safe\nContacts', Icons.people_rounded, AppColors.primary),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.value, this.label, this.icon, this.color);
  final String value, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMutedLight, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _JourneyHistoryCard extends StatelessWidget {
  const _JourneyHistoryCard({required this.journey});
  final JourneyModel journey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  journey.startAddress,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${journey.distanceKm?.toStringAsFixed(1) ?? "?"} km',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (journey.destinationAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 24),
                const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.textMutedLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(journey.destinationAddress!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMutedLight),
              const SizedBox(width: 4),
              Text(
                '${journey.durationMinutes ?? "?"} min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
              ),
              const SizedBox(width: AppSizes.md),
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMutedLight),
              const SizedBox(width: 4),
              Text(
                _formatDate(journey.startTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
              ),
              const Spacer(),
              if (journey.startLat != null && journey.endLat != null)
                GestureDetector(
                  onTap: () => context.push('/journey/map', extra: journey),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 12, color: AppColors.info),
                        const SizedBox(width: 3),
                        Text('Map', style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
