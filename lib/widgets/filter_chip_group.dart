import 'package:flutter/material.dart';
import '../app/theme.dart';

class FilterChipGroup extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  const FilterChipGroup({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final label = labels[i];
          final isActive = label == selected;
          return GestureDetector(
            onTap: () => onSelected(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF252525)
                        : const Color(0xFFF2F2F0)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : AppColors.sub(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
