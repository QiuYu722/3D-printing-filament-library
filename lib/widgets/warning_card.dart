import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/filament.dart';

class WarningCard extends StatelessWidget {
  final Filament filament;
  final VoidCallback? onTap;
  const WarningCard({super.key, required this.filament, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (filament.status) {
      StockStatus.normal => AppColors.success,
      StockStatus.low => AppColors.warning,
      StockStatus.critical => AppColors.danger,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                filament.status == StockStatus.critical
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${filament.code} · ${filament.colorName}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${filament.material} · 剩余 ${filament.quantity}',
                    style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                filament.status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
