import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/emergency_provider.dart';

/// Full-screen emergency siren alarm with animated visual strobe,
/// loop playback controls, and emergency hotline shortcuts.
class SirenScreen extends StatefulWidget {
  const SirenScreen({super.key});

  @override
  State<SirenScreen> createState() => _SirenScreenState();
}

class _SirenScreenState extends State<SirenScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.8, end: 0.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-start the siren when opening the Siren screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = context.read<EmergencyProvider>();
      if (!ep.isSirenOn) {
        ep.startSiren();
      }
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
    final isPlaying = ep.isSirenOn;

    return Scaffold(
      backgroundColor: isPlaying ? const Color(0xFF1E0005) : const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Emergency Siren', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top status banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: isPlaying ? AppColors.sosRed.withValues(alpha: 0.25) : Colors.white10,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: isPlaying ? AppColors.sosRed : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: isPlaying ? AppColors.sosRed : Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      isPlaying ? 'SIREN IS PLAYING AT MAX VOLUME' : 'SIREN IS MUTED',
                      style: TextStyle(
                        color: isPlaying ? AppColors.sosRed : Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Center pulsing siren button
              Column(
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated strobe ring 1
                        if (isPlaying)
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) => Container(
                              width: 200 * _pulseScale.value,
                              height: 200 * _pulseScale.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sosRed.withValues(alpha: _pulseOpacity.value * 0.4),
                              ),
                            ),
                          ),
                        // Outer ring
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlaying
                                ? AppColors.sosRed.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: isPlaying ? AppColors.sosRed.withValues(alpha: 0.4) : Colors.white24,
                              width: 2,
                            ),
                          ),
                        ),
                        // Action Button
                        GestureDetector(
                          onTap: () => ep.toggleSiren(),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isPlaying
                                    ? [AppColors.sosRed, AppColors.sosRedDark]
                                    : [Colors.grey.shade800, Colors.grey.shade900],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isPlaying
                                      ? AppColors.sosRed.withValues(alpha: 0.6)
                                      : Colors.black54,
                                  blurRadius: isPlaying ? 35 : 10,
                                  spreadRadius: isPlaying ? 6 : 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPlaying ? 'STOP' : 'START',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    isPlaying ? 'Attracting attention & deterring threat' : 'Tap to trigger loud alarm',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Bottom helper text and actions
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
                        SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            'Siren plays high-decibel continuous alarm audio until manually stopped.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlaying ? Colors.white : AppColors.sosRed,
                        foregroundColor: isPlaying ? AppColors.sosRedDark : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      onPressed: () => ep.toggleSiren(),
                      child: Text(
                        isPlaying ? 'Stop Siren Audio' : 'Start Emergency Siren',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
