import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/emergency_provider.dart';

/// Full SOS screen with countdown, cancel, and sent confirmation.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().startCountdown();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EmergencyProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          ep.cancelCountdown();
          ep.cancelSos();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF8E0000),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        ep.cancelCountdown();
                        ep.cancelSos();
                        context.pop();
                      },
                    ),
                    const Spacer(),
                    const Text('SafeHer SOS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  children: [
                    if (ep.status == EmergencyStatus.counting) ...[
                      const Text('Sending SOS in', style: TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: AppSizes.xl),
                      ScaleTransition(
                        scale: _pulseScale,
                        child: Text(
                          '${ep.countdown}',
                          style: const TextStyle(color: Colors.white, fontSize: 120, fontWeight: FontWeight.w900, height: 1),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      const Text(
                        'Your location will be recorded\nfor this SOS event',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ] else if (ep.status == EmergencyStatus.active) ...[
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 80),
                      const SizedBox(height: AppSizes.lg),
                      const Text('SOS Activated!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'Your location has been recorded.\nCall a trusted contact now if you can.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ep.lastError == null ? Icons.location_on_rounded : Icons.location_off_rounded,
                              color: ep.lastError == null ? Colors.greenAccent : Colors.orangeAccent,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              ep.lastError == null ? 'Location saved' : 'Location not confirmed — check connection',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  children: [
                    if (ep.status == EmergencyStatus.counting)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                          ),
                          onPressed: () {
                            ep.cancelCountdown();
                            context.pop();
                          },
                          child: const Text('Cancel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      )
                    else if (ep.status == EmergencyStatus.active)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.sosRed,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                          ),
                          onPressed: () async {
                            await ep.cancelSos();
                            if (context.mounted) context.pop();
                          },
                          child: const Text('Cancel SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      ep.status == EmergencyStatus.counting
                          ? 'Tap Cancel if this was a mistake'
                          : 'Help is on the way. Stay safe! 💪',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
