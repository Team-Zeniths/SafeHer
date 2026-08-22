import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// A circular avatar widget with fallback initials and optional online indicator.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = AppSizes.avatarMd / 2,
    this.showOnlineIndicator = false,
    this.backgroundColor,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final bool showOnlineIndicator;
  final Color? backgroundColor;

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: bg,
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bg.withValues(alpha: 0.15),
        child: Text(
          _initials,
          style: TextStyle(
            color: bg,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }

    if (!showOnlineIndicator) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
