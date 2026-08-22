import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/route_names.dart';
import '../../auth/providers/auth_provider.dart';

/// App settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Appearance'),
          _ThemeTile(),
          _SectionHeader('Notifications'),
          _SwitchTile(
            icon: Icons.sos_rounded,
            title: 'SOS Alerts',
            subtitle: 'Notify trusted contacts on SOS',
            value: true,
            color: AppColors.sosRed,
            onChanged: (_) {}, // TODO: Persist setting
          ),
          _SwitchTile(
            icon: Icons.route_rounded,
            title: 'Journey Updates',
            subtitle: 'Notify during active journeys',
            value: true,
            color: AppColors.info,
            onChanged: (_) {},
          ),
          _SwitchTile(
            icon: Icons.people_rounded,
            title: 'Community Alerts',
            subtitle: 'Nearby safety alerts from community',
            value: true,
            color: AppColors.success,
            onChanged: (_) {},
          ),
          _SectionHeader('Privacy & Security'),
          _NavTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              final userEmail = context.read<AuthProvider>().user?.email;
              context.push(RouteNames.forgotPassword, extra: userEmail);
            },
          ),
          _NavTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Settings', onTap: () {}),
          _NavTile(icon: Icons.security_rounded, title: 'Security Settings', onTap: () {}),
          _SectionHeader('Location'),
          _SwitchTile(
            icon: Icons.location_on_outlined,
            title: 'Background Location',
            subtitle: 'Required for journey tracking',
            value: true,
            color: AppColors.primary,
            onChanged: (_) {},
          ),
          _SectionHeader('Emergency'),
          _SwitchTile(
            icon: Icons.vibration_rounded,
            title: 'SOS Vibration',
            subtitle: 'Vibrate when SOS is activated',
            value: true,
            color: AppColors.warning,
            onChanged: (_) {},
          ),
          _NavTile(icon: Icons.language_rounded, title: 'Language', trailing: 'English', onTap: () {}),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.xs),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMutedLight, letterSpacing: 1),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final mode = tp.themeMode;

    return ListTile(
      leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 16)),
          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 16)),
          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 16)),
        ],
        selected: {mode},
        onSelectionChanged: (s) => tp.setThemeMode(s.first),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: Icon(widget.icon, color: widget.color, size: 22),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle, style: TextStyle(color: AppColors.textMutedLight, fontSize: 12)),
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
      activeTrackColor: widget.color,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.onTap, this.trailing});
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing!, style: TextStyle(color: AppColors.textMutedLight, fontSize: 13)),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMutedLight),
        ],
      ),
      onTap: onTap,
    );
  }
}
