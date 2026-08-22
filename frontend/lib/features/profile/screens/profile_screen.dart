import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../home/providers/safety_score_provider.dart';
import '../../journey/providers/journey_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/route_names.dart';

/// User profile screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load real data so stats are never stale.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = context.read<ContactsProvider>();
      if (cp.status == ContactsStatus.idle) cp.loadContacts();
      final jp = context.read<JourneyProvider>();
      if (jp.status == JourneyProviderStatus.idle) jp.loadHistory();
      final sp = context.read<SafetyScoreProvider>();
      if (sp.status == SafetyScoreStatus.idle) sp.loadScore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9C27B0), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSizes.lg),
                      AvatarWidget(name: user?.fullName, imageUrl: user?.avatarUrl, radius: 40),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        (user?.fullName != null && user!.fullName.isNotEmpty) ? user.fullName : 'SafeHer User',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        (user?.email != null && user!.email.isNotEmpty) ? user.email : 'No email set',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (user?.isVerified == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.white70, size: 14),
                              SizedBox(width: 4),
                              Text('Verified', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => context.push(RouteNames.editProfile),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  // Safety stats
                  _SafetyStatsCard(),
                  const SizedBox(height: AppSizes.lg),
                  // Account section
                  _SectionCard(title: 'Account', children: [
                    _MenuItem(Icons.person_outline, 'Edit Profile', () => context.push(RouteNames.editProfile)),
                    _MenuItem(Icons.contacts_outlined, 'Trusted Contacts', () => context.push(RouteNames.contacts)),
                    _MenuItem(Icons.history_rounded, 'Activity History', () => context.push(RouteNames.history)),
                  ]),
                  const SizedBox(height: AppSizes.md),
                  // Preferences section
                  _SectionCard(title: 'Preferences', children: [
                    _ThemeToggleTile(),
                    _MenuItem(Icons.notifications_outlined, 'Notifications', () => context.push(RouteNames.notifications)),
                    _MenuItem(Icons.settings_outlined, 'Settings', () => context.push(RouteNames.settings)),
                  ]),
                  const SizedBox(height: AppSizes.md),
                  // Support section
                  _SectionCard(title: 'Support', children: [
                    _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                    _MenuItem(Icons.info_outline, 'About SafeHer', () => context.push(RouteNames.about)),
                    _MenuItem(Icons.help_outline, 'Help & Support', () {}),
                  ]),
                  const SizedBox(height: AppSizes.lg),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out?'),
                            content: const Text('You will be returned to the login screen.'),
                            actions: [
                              TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => ctx.pop(true),
                                child: const Text('Log Out', style: TextStyle(color: AppColors.sosRed)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await context.read<AuthProvider>().logout();
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.sosRed),
                      label: const Text('Log Out', style: TextStyle(color: AppColors.sosRed, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sosRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      ),
                    ),
                  ),
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

class _SafetyStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final journeyCount = context.watch<JourneyProvider>().history.length;
    final contactCount = context.watch<ContactsProvider>().contacts.length;
    final sp = context.watch<SafetyScoreProvider>();

    final scoreText = sp.score != null
        ? '${sp.score}'
        : (sp.status == SafetyScoreStatus.loading ? '...' : '--');

    final scoreColor = sp.score != null
        ? (sp.score! >= 70
            ? AppColors.success
            : (sp.score! >= 40 ? AppColors.warning : AppColors.sosRed))
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Row(
        children: [
          _Stat(
            scoreText,
            'Safety\nScore',
            scoreColor,
            onTap: sp.status == SafetyScoreStatus.error
                ? () => context.read<SafetyScoreProvider>().loadScore()
                : null,
          ),
          _divider(),
          _Stat('$journeyCount', 'Safe\nJourneys', AppColors.info),
          _divider(),
          _Stat('$contactCount', 'Trusted\nContacts', AppColors.success),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.lightOutline);
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color, {this.onTap});
  final String value, label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textMutedLight, height: 1.3)),
      ],
    );

    return Expanded(
      child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
    );
  }
}


class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMutedLight, letterSpacing: 0.5)),
        ),
        Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            side: BorderSide(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMutedLight),
      onTap: onTap,
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.themeMode == ThemeMode.dark;

    return ListTile(
      dense: true,
      leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 22, color: AppColors.primary),
      title: Text(isDark ? 'Dark Mode' : 'Light Mode', style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (_) => tp.toggleTheme(),
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

