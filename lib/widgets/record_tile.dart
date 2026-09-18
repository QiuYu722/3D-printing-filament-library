import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/inventory_record.dart';
import '../models/filament.dart';

class RecordTile extends StatelessWidget {
  final InventoryRecord record;
  final Filament? filament;
  final bool showDate;
  const RecordTile({super.key, required this.record, this.filament, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final isIn = record.type == InventoryType.stockIn;
    final color = isIn ? AppColors.success : AppColors.danger;

    String code = filament?.code ?? '未知耗材';
    String colorName = filament?.colorName ?? '';
    String material = filament?.material ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  colorName.isNotEmpty
                      ? '$colorName · $material · ${record.reason}'
                      : record.reason,
                  style: TextStyle(fontSize: 12, color: AppColors.sub(context)),
                ),
                if (showDate) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(record.createdAt),
                    style: TextStyle(fontSize: 11, color: AppColors.sub(context)),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'}${record.quantity}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
