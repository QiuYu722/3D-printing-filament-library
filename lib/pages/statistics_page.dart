import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../widgets/statistic_card.dart';

enum _Range { today, week, month, year }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  _Range _range = _Range.week;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();

    final (start, end, days) = _rangeDates(_range);
    final stats = p.recordsInRange(start, end);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Title
            Text(
              '数据统计',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 16),
            // Range tabs
            _RangeTabs(
              range: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 16),
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    label: '入库',
                    value: '+${stats.inQty}',
                    icon: Icons.south_west_rounded,
                    iconColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    label: '取走',
                    value: '−${stats.outQty}',
                    icon: Icons.north_east_rounded,
                    iconColor: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Material distribution
            _MaterialChart(p: p),
            const SizedBox(height: 24),
            // Color usage - horizontal
            _ColorUsageChart(p: p),
          ],
        ),
      ),
    );
  }

  (DateTime, DateTime, int) _rangeDates(_Range r) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (r) {
      case _Range.today:
        return (today, today.add(const Duration(days: 1)), 1);
      case _Range.week:
        return (today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1)), 7);
      case _Range.month:
        return (today.subtract(const Duration(days: 29)), today.add(const Duration(days: 1)), 30);
      case _Range.year:
        return (today.subtract(const Duration(days: 364)), today.add(const Duration(days: 1)), 365);
    }
  }
}

class _RangeTabs extends StatelessWidget {
  final _Range range;
  final ValueChanged<_Range> onChanged;
  const _RangeTabs({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['今日', '本周', '本月', '今年'];
    final values = _Range.values;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = range == values[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? Colors.white : AppColors.sub(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MaterialChart extends StatelessWidget {
  final InventoryProvider p;
  const _MaterialChart({required this.p});

  @override
  Widget build(BuildContext context) {
    final quantities = p.quantityByMaterial();
    final total = quantities.values.fold(0, (s, v) => s + v);
    final entries = quantities.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final colors = <String, Color>{
      'PLA': const Color(0xFF22C55E),
      'PETG': const Color(0xFF1E88E5),
      'ABS': const Color(0xFF9E9E9E),
      'TPU': const Color(0xFFE53935),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '材质分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: total > 0
                      ? PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: entries.map((e) {
                              final pct = total > 0 ? (e.value / total * 100) : 0.0;
                              final c = colors[e.key] ?? AppColors.primary;
                              return PieChartSectionData(
                                color: c,
                                value: e.value.toDouble(),
                                title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                                radius: 32,
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                          duration: const Duration(milliseconds: 800),
                        )
                      : Center(
                          child: Text('暂无数据', style: TextStyle(color: AppColors.sub(context))),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: entries.map((e) {
                      final c = colors[e.key] ?? AppColors.primary;
                      final pct = total > 0 ? (e.value / total * 100) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(e.key, style: TextStyle(fontSize: 13, color: AppColors.text(context))),
                            const Spacer(),
                            Text(
                              '${pct.toStringAsFixed(0)}% · ${e.value}卷',
                              style: TextStyle(fontSize: 12, color: AppColors.sub(context)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorUsageChart extends StatelessWidget {
  final InventoryProvider p;
  const _ColorUsageChart({required this.p});

  @override
  Widget build(BuildContext context) {
    final quantities = p.quantityByColor();
    final entries = quantities.entries.take(6).toList();
    final maxVal = entries.isEmpty ? 1.0 : entries.first.value.toDouble();

    final colors = <String, Color>{};
    for (final e in entries) {
      final filaments = p.filaments.where((f) => f.colorName == e.key);
      if (filaments.isNotEmpty) {
        colors[e.key] = filaments.first.colorValue;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '使用最多的颜色',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            Center(child: Text('暂无数据', style: TextStyle(color: AppColors.sub(context))))
          else
            Column(
              children: entries.map((e) {
                final c = colors[e.key] ?? AppColors.primary;
                final pct = maxVal > 0 ? (e.value / maxVal) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.divider(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 56,
                        child: Text(
                          e.key,
                          style: TextStyle(fontSize: 13, color: AppColors.text(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.divider(context),
                            color: c,
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${e.value}卷',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
