import 'package:flutter/material.dart';

/// Centered circular progress indicator, themed with the app's
/// primary color. Use inside a [Center] or [Expanded] as needed.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
