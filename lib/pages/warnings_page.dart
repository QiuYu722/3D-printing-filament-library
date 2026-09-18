import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../widgets/warning_card.dart';
import '../widgets/empty_state.dart';
import 'filament_detail_page.dart';

class WarningsPage extends StatelessWidget {
  const WarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final critical = p.criticalStock;
    final low = p.lowStock;
    final normal = p.normalStock;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('库存预警'),
      ),
      body: (critical.isEmpty && low.isEmpty)
          ? const EmptyState(
              title: '库存充足',
              subtitle: '所有耗材库存均在安全范围内',
              icon: Icons.check_circle_outline_rounded,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (critical.isNotEmpty) ...[
                  _GroupHeader(
                    icon: Icons.error_rounded,
                    color: AppColors.danger,
                    title: '库存不足',
                    count: critical.length,
                  ),
                  const SizedBox(height: 12),
                  ...critical.map((f) => WarningCard(
                        filament: f,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FilamentDetailPage(filamentId: f.id)),
                        ),
                      )),
                ],
                if (low.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _GroupHeader(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    title: '库存偏低',
                    count: low.length,
                  ),
                  const SizedBox(height: 12),
                  ...low.map((f) => WarningCard(
                        filament: f,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FilamentDetailPage(filamentId: f.id)),
                        ),
                      )),
                ],
                const SizedBox(height: 24),
                _GroupHeader(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  title: '库存正常',
                  count: normal.length,
                ),
                const SizedBox(height: 12),
                ...normal.take(10).map((f) => WarningCard(filament: f)),
              ],
            ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  const _GroupHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text(context),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}
