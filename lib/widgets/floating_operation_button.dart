import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Floating circular "+" button in the center of the bottom nav.
/// Parent handles the tap via the bottom nav's center tap.
class FloatingOperationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const FloatingOperationButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
