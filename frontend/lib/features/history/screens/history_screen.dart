import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../journey/providers/journey_provider.dart';
import '../../emergency/providers/sos_history_provider.dart';

/// Safety history timeline screen — driven by real provider data.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    // Refresh journey and SOS history whenever this screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JourneyProvider>().loadHistory();
      context.read<SosHistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Journeys'),
            Tab(text: 'SOS'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMutedLight,
        ),
      ),
      body: Column(
        children: [
          // Stats header — reads from real providers
          const _StatsHeader(),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.xs),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _HistoryList(filter: 'all', search: _search),
                _HistoryList(filter: 'journey', search: _search),
                _HistoryList(filter: 'sos', search: _search),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Header ──────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    final jp = context.watch<JourneyProvider>();
    final sp = context.watch<SosHistoryProvider>();
    final journeyCount = jp.history.length;
    final totalKm = jp.history.fold<double>(0, (s, j) => s + (j.distanceKm ?? 0));
    final kmLabel = totalKm == 0 ? '0 km' : '${totalKm.toStringAsFixed(1)} km';
    final sosCount = sp.events.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.12), const Color(0xFF9C27B0).withValues(alpha: 0.08)],
        ),
      ),
      child: Row(
        children: [
          _StatItem('$journeyCount', 'Journeys', Icons.route_rounded, AppColors.info),
          const VerticalDivider(width: 1),
          _StatItem('$sosCount', 'SOS Alerts', Icons.sos_rounded, AppColors.sosRed),
          const VerticalDivider(width: 1),
          _StatItem(kmLabel, 'Travelled', Icons.straighten_rounded, AppColors.success),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.value, this.label, this.icon, this.color);
  final String value, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          Text(label, style: TextStyle(color: AppColors.textMutedLight, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── History List ──────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.filter, required this.search});
  final String filter;
  final String search;

  @override
  Widget build(BuildContext context) {
    final jp = context.watch<JourneyProvider>();

    if (jp.status == JourneyProviderStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build entries from real journey history
    final journeyEntries = jp.history.map((j) => _HistoryEntry(
          type: 'journey',
          title: j.destinationAddress != null
              ? '${j.startAddress} → ${j.destinationAddress}'
              : j.startAddress,
          subtitle: [
            if (j.distanceKm != null) '${j.distanceKm!.toStringAsFixed(1)} km',
            if (j.durationMinutes != null) '${j.durationMinutes} min',
          ].join(' • '),
          time: j.startTime,
          icon: Icons.route_rounded,
          color: AppColors.info,
        ));

    final sp = context.watch<SosHistoryProvider>();
    final sosEntries = sp.events.map((s) => _HistoryEntry(
          type: 'sos',
          title: s.isResolved ? 'SOS — resolved' : 'SOS — active',
          subtitle: '${s.locationLat.toStringAsFixed(5)}, ${s.locationLng.toStringAsFixed(5)}',
          time: s.triggeredAt,
          icon: Icons.sos_rounded,
          color: AppColors.sosRed,
          lat: s.locationLat,
          lng: s.locationLng,
        ));

    final all = [...journeyEntries, ...sosEntries]
      ..sort((a, b) => b.time.compareTo(a.time));

    var filtered = filter == 'all'
        ? all
        : filter == 'journey'
            ? journeyEntries.toList()
            : sosEntries.toList();

    if (search.isNotEmpty) {
      filtered = filtered
          .where((e) => e.title.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: filter == 'sos' ? Icons.sos_rounded : Icons.history_rounded,
        title: filter == 'sos' ? 'No SOS events' : 'No history yet',
        subtitle: filter == 'sos'
            ? 'Stay safe — SOS events will appear here if triggered.'
            : 'Complete a journey to see it here.',
        iconColor: AppColors.primary,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
      itemCount: filtered.length,
      itemBuilder: (context, i) =>
          _TimelineItem(entry: filtered[i], isLast: i == filtered.length - 1),
    );
  }
}

// ── Timeline Item ─────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.entry, required this.isLast});
  final _HistoryEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.icon, color: entry.color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Content
          Expanded(
            child: InkWell(
              onTap: entry.lat != null && entry.lng != null
                  ? () => _showLocationDialog(context, entry)
                  : null,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                        Text(_formatDate(entry.time),
                            style: TextStyle(color: AppColors.textMutedLight, fontSize: 11)),
                      ],
                    ),
                    if (entry.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(entry.subtitle,
                          style: TextStyle(color: AppColors.textMutedLight, fontSize: 13)),
                    ],
                    if (entry.lat != null && entry.lng != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Tap to verify on map',
                              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
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

/// Shows the exact coordinates an SOS event saved, with a button to open
/// them in Google Maps — lets the user confirm after the fact that the
/// recorded location actually matches where the incident happened.
void _showLocationDialog(BuildContext context, _HistoryEntry entry) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Verify saved location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSizes.sm),
          Text('Latitude: ${entry.lat!.toStringAsFixed(6)}'),
          Text('Longitude: ${entry.lng!.toStringAsFixed(6)}'),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Open this in Maps to check it matches where this actually happened.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        FilledButton.icon(
          icon: const Icon(Icons.map_rounded, size: 18),
          label: const Text('Open in Maps'),
          onPressed: () async {
            final uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${entry.lat},${entry.lng}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ],
    ),
  );
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.lat,
    this.lng,
  });
  final String type, title, subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;
  final double? lat;
  final double? lng;
}
