import 'package:flutter/material.dart';
import '../app/theme.dart';

class CustomSearchBar extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final bool readOnly;
  const CustomSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.controller,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252525)
              : const Color(0xFFF2F2F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.text(context),
          ),
          decoration: InputDecoration(
            hintText: hintText ?? '搜索耗材编号、颜色、材质',
            hintStyle: TextStyle(fontSize: 14, color: AppColors.sub(context)),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.sub(context)),
            suffixIcon: controller != null && (controller!.text.isNotEmpty)
                ? GestureDetector(
                    onTap: () {
                      controller!.clear();
                      onChanged?.call('');
                      onClear?.call();
                    },
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.sub(context)),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
