import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../providers/safety_score_provider.dart';
import '../../../routes/route_names.dart';

/// Full Home Dashboard — personalized greeting, safety score, SOS shortcut,
/// quick actions, recent activity, safe tips, and nearby services.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Load notifications count and safety score on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
      context.read<SafetyScoreProvider>().loadScore();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final unread = context.watch<NotificationsProvider>().unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                // Logo + brand
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF9C27B0)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'SafeHer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF9C27B0)],
                          ).createShader(const Rect.fromLTWH(0, 0, 100, 30)),
                      ),
                ),
              ],
            ),
            actions: [
              // Notification bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push(RouteNames.notifications),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.sosRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.sm),
                child: GestureDetector(
                  onTap: () => context.push(RouteNames.profile),
                  child: AvatarWidget(
                    name: user?.fullName,
                    imageUrl: user?.avatarUrl,
                    radius: 18,
                  ),
                ),
              ),
            ],
          ),

          // ── Body Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.sm),

                  // Greeting
                  _GreetingSection(name: user?.fullName),
                  const SizedBox(height: AppSizes.lg),

                  // Safety Score Card
                  const _SafetyScoreCard(),
                  const SizedBox(height: AppSizes.lg),

                  // SOS Button
                  _SosShortcutButton(pulseAnim: _pulseAnim),
                  const SizedBox(height: AppSizes.lg),

                  // Quick Actions
                  SectionHeader(
                    title: 'Quick Actions',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _QuickActionsGrid(),
                  const SizedBox(height: AppSizes.lg),

                  // Safe Tips
                  SectionHeader(
                    title: 'Safety Tips',
                    actionLabel: 'See all',
                    onAction: () => context.push(RouteNames.community),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _SafeTipsCarousel(),
                  const SizedBox(height: AppSizes.lg),

                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Greeting ─────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({this.name});
  final String? name;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()}, ${name?.split(' ').first ?? 'there'} 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stay safe. We\'re watching over you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMutedLight,
              ),
        ),
      ],
    );
  }
}

// ── Safety Score Card ────────────────────────────────────────────────────────

class _SafetyScoreCard extends StatelessWidget {
  const _SafetyScoreCard();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SafetyScoreProvider>();

    // Loading state — first fetch (getting GPS fix + calling the API).
    if (sp.status == SafetyScoreStatus.loading || sp.status == SafetyScoreStatus.idle) {
      return _scoreContainer(
        context,
        child: const Row(
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
            SizedBox(width: AppSizes.md),
            Text('Checking your area…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // Error state — could be location denial, GPS off, or a network/server failure.
    if (sp.status == SafetyScoreStatus.error || sp.score == null) {
      return _scoreContainer(
        context,
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.white70, size: 22),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                sp.errorMessage ?? "Couldn't load your area's safety score",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => context.read<SafetyScoreProvider>().loadScore(),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final score = sp.score!;
    final isGood = score >= 70;
    final isOk = score >= 40 && score < 70;
    final statusEmoji = isGood ? '🟢' : (isOk ? '🟡' : '🔴');
    final statusText = sp.nearbyReportCount == 0
        ? 'No recent reports nearby'
        : '${sp.nearbyReportCount} recent report${sp.nearbyReportCount == 1 ? '' : 's'} nearby';

    return _scoreContainer(
      context,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'SAFETY SCORE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$score / 100',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$statusEmoji $statusText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreContainer(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── SOS Shortcut ─────────────────────────────────────────────────────────────

class _SosShortcutButton extends StatelessWidget {
  const _SosShortcutButton({required this.pulseAnim});
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(RouteNames.emergency),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.sosRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.sosRed.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: pulseAnim,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.sosRed, AppColors.sosRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sosRed.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.sosRed,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to alert your trusted contacts instantly',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMutedLight,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.sosRed),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    _Action(Icons.route_rounded, 'Start\nJourney', RouteNames.journey, Color(0xFF2196F3)),
    _Action(Icons.contacts_rounded, 'Contacts', RouteNames.contacts, Color(0xFF4CAF50)),
    _Action(Icons.smart_toy_rounded, 'AI Assistant', RouteNames.aiAssistant, Color(0xFF9C27B0)),
    _Action(Icons.history_rounded, 'History', RouteNames.history, Color(0xFFFF9800)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, i) => _QuickActionTile(_actions[i]),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile(this.action);
  final _Action action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: action.color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 28),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: action.color,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  const _Action(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

// ── Safe Tips Carousel ───────────────────────────────────────────────────────

class _SafeTipsCarousel extends StatelessWidget {
  const _SafeTipsCarousel();

  static const _tips = [
    _Tip('🌙', 'Late Night Safety', 'Always share your live location when traveling at night.', Color(0xFF673AB7)),
    _Tip('📱', 'Keep Charged', 'Maintain at least 20% battery when going out.', Color(0xFF2196F3)),
    _Tip('👥', 'Trust Your Circle', 'Keep 3+ trusted contacts updated and reachable.', Color(0xFF4CAF50)),
    _Tip('🚕', 'Cab Safety', 'Share your cab details with a trusted contact before riding.', Color(0xFFFF9800)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, i) => _TipCard(_tips[i]),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard(this.tip);
  final _Tip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: tip.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: tip.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tip.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  tip.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tip.color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            tip.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  const _Tip(this.emoji, this.title, this.body, this.color);
  final String emoji, title, body;
  final Color color;
}
