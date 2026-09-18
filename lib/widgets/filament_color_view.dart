import 'package:flutter/material.dart';
import '../models/filament.dart';

/// Displays the filament's real color as a filled Container,
/// or the user's uploaded color image if available.
class FilamentColorView extends StatelessWidget {
  final Filament filament;
  final double size;
  final bool showLabel;

  const FilamentColorView({
    super.key,
    required this.filament,
    this.size = double.infinity,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = filament.colorValue;
    final isLight = color.computeLuminance() > 0.6;

    if (filament.colorImage != null && filament.colorImage!.isNotEmpty) {
      return Image.network(
        filament.colorImage!,
        width: size == double.infinity ? null : size,
        height: size == double.infinity ? null : size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _colorBox(color, isLight),
      );
    }

    return _colorBox(color, isLight);
  }

  Widget _colorBox(Color color, bool isLight) {
    final box = Container(
      width: size == double.infinity ? null : size,
      height: size == double.infinity ? null : size,
      decoration: BoxDecoration(
        color: color,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.15) ?? color,
          ],
        ),
      ),
      child: showLabel
          ? Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  filament.colorName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLight ? Colors.black54 : Colors.white70,
                  ),
                ),
              ),
            )
          : null,
    );
    return box;
  }
}
