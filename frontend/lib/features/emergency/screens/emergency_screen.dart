import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../../routes/route_names.dart';

/// The Emergency hub screen — SOS, fake call, siren, flashlight shortcuts.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    // Load contacts if not already done (user may not have visited Contacts tab).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = context.read<ContactsProvider>();
      if (cp.status == ContactsStatus.idle) {
        cp.loadContacts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A0008) : const Color(0xFFFFF0F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Emergency'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.md),

              // Main SOS Button
              const _MainSosButton(),
              const SizedBox(height: AppSizes.xl),

              // Emergency tools grid
              _sectionLabel('Emergency Tools'),
              const SizedBox(height: AppSizes.md),
              const _EmergencyToolsGrid(),
              const SizedBox(height: AppSizes.xl),

              // Emergency contacts
              _sectionLabel('Emergency Contacts'),
              const SizedBox(height: AppSizes.md),
              const _EmergencyContactsPreview(),
              const SizedBox(height: AppSizes.xl),

              // Emergency hotlines
              _sectionLabel('National Helplines'),
              const SizedBox(height: AppSizes.md),
              const _HotlinesList(),
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Builder(
      builder: (context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Main SOS Button ───────────────────────────────────────────────────────────

class _MainSosButton extends StatefulWidget {
  const _MainSosButton();

  @override
  State<_MainSosButton> createState() => _MainSosButtonState();
}

class _MainSosButtonState extends State<_MainSosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pulse rings + SOS circle
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Container(
                  width: 180 * _scale.value,
                  height: 180 * _scale.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sosRed.withValues(alpha: _opacity.value),
                      width: 3,
                    ),
                  ),
                ),
              ),
              // Middle ring
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sosRed.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.sosRed.withValues(alpha: 0.3), width: 2),
                ),
              ),
              // SOS Button — hold to activate (prevents accidental triggers)
              _HoldToActivateSos(),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          'Tap & hold to activate emergency SOS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMutedLight,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ── Emergency Tools Grid ─────────────────────────────────────────────────────

class _EmergencyToolsGrid extends StatelessWidget {
  const _EmergencyToolsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.md,
      mainAxisSpacing: AppSizes.md,
      childAspectRatio: 1.3,
      children: [
        _ToolCard(
          icon: Icons.contact_phone_rounded,
          label: 'Emergency\nContacts',
          subtitle: 'Alert trusted circle',
          color: const Color(0xFF2196F3),
          onTap: () => context.push(RouteNames.contacts),
        ),
        _ToolCard(
          icon: Icons.report_rounded,
          label: 'Report\nIncident',
          subtitle: 'File a safety report',
          color: const Color(0xFF9C27B0),
          onTap: () => context.push(RouteNames.incidentReport),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1.2,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emergency Contacts Preview ───────────────────────────────────────────────

class _EmergencyContactsPreview extends StatelessWidget {
  const _EmergencyContactsPreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Read real contacts from the backend-wired ContactsProvider.
    final cp = context.watch<ContactsProvider>();
    final contacts = cp.contacts;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Column(
        children: [
          if (cp.status == ContactsStatus.loading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: CircularProgressIndicator(),
            )
          else if (contacts.isEmpty)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.group_off_rounded, color: AppColors.textMutedLight),
              ),
              title: const Text('No emergency contacts yet', style: TextStyle(color: AppColors.textMutedLight)),
              subtitle: const Text('Add trusted contacts so they can be alerted'),
            )
          else
            ...contacts.map(
              (c) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call_rounded, color: AppColors.success, size: 20),
                      onPressed: () => _launchPhone(context, c.phone),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message_rounded, color: AppColors.info, size: 20),
                      onPressed: () => _launchSms(context, c.phone),
                    ),
                  ],
                ),
              ),
            ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.add_circle_outline, color: AppColors.primary),
            ),
            title: Text(
              'Manage Contacts',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            onTap: () => context.push(RouteNames.contacts),
          ),
        ],
      ),
    );
  }
}

// ── Hotlines ─────────────────────────────────────────────────────────────────

class _HotlinesList extends StatelessWidget {
  const _HotlinesList();

  static const _hotlines = [
    _Hotline('🚔', 'Police Emergency', '100', AppColors.info),
    _Hotline('🆘', 'Women\'s Helpline', '1091', AppColors.primary),
    _Hotline('🏥', 'Medical Emergency', '108', AppColors.success),
    _Hotline('🔥', 'Fire Department', '101', AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Column(
        children: _hotlines.map((h) {
          return ListTile(
            leading: Text(h.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
              decoration: BoxDecoration(
                color: h.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text(
                h.number,
                style: TextStyle(
                  color: h.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            onTap: () => _launchPhone(context, h.number),
          );
        }).toList(),
      ),
    );
  }
}

class _Hotline {
  const _Hotline(this.emoji, this.name, this.number, this.color);
  final String emoji, name, number;
  final Color color;
}

// ── Native call / SMS launchers ─────────────────────────────────────────────

/// Opens the phone's native dialer pre-filled with [phone]. Requires a tap
/// on "Call" in the dialer to actually place the call — this app never
/// dials silently on its own.
Future<void> _launchPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open dialer for $phone')),
    );
  }
}

/// Opens the phone's native SMS app pre-filled with [phone] and a short
/// default message. The user still has to tap send themselves — this is
/// the free, no-account alternative to automatic SMS via Twilio.
Future<void> _launchSms(BuildContext context, String phone) async {
  final uri = Uri(
    scheme: 'sms',
    path: phone,
    queryParameters: {'body': "I need help. Can you call me? — sent via SafeHer"},
  );
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open messages for $phone')),
    );
  }
}

// ── Hold-to-activate SOS button ─────────────────────────────────────────────

/// A press-and-hold button that fills a ring over [_holdDuration] before
/// navigating to the SOS screen. Prevents a single accidental tap from
/// triggering an emergency — the user has to deliberately hold it down.
/// Releasing early cancels with no side effects.
class _HoldToActivateSos extends StatefulWidget {
  const _HoldToActivateSos();

  @override
  State<_HoldToActivateSos> createState() => _HoldToActivateSosState();
}

class _HoldToActivateSosState extends State<_HoldToActivateSos>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 900);

  late final AnimationController _holdCtrl;

  @override
  void initState() {
    super.initState();
    _holdCtrl = AnimationController(vsync: this, duration: _holdDuration);
    _holdCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.push(RouteNames.sos);
        _holdCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _holdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _holdCtrl.forward(),
      onLongPressEnd: (_) {
        if (_holdCtrl.status != AnimationStatus.completed) {
          _holdCtrl.reverse();
        }
      },
      onLongPressCancel: () {
        if (_holdCtrl.status != AnimationStatus.completed) {
          _holdCtrl.reverse();
        }
      },
      child: SizedBox(
        width: 130,
        height: 130,
        child: AnimatedBuilder(
          animation: _holdCtrl,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Fill progress ring — shows how close the hold is to firing.
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: _holdCtrl.value,
                    strokeWidth: 4,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                child!,
              ],
            );
          },
          child: Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.sosRed, AppColors.sosRedDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sosRed.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sos_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 4),
                const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
