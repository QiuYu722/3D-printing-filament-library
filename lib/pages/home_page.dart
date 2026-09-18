import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../widgets/warning_card.dart';
import '../widgets/record_tile.dart';
import 'warnings_page.dart';
import 'records_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    if (p.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => p.init(),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _Header(p: p),
              ),
              // Overview card
              SliverToBoxAdapter(
                child: _OverviewCard(p: p),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Material stat cards
              SliverToBoxAdapter(
                child: _MaterialCards(p: p),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Warnings section
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: '库存提醒',
                  actionLabel: '查看全部',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WarningsPage()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _WarningsList(p: p),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Recent records
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: '最近操作',
                  actionLabel: '全部记录',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordsPage()),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final r = p.recentRecords[i];
                    final f = p.getFilament(r.filamentId);
                    return RecordTile(record: r, filament: f);
                  },
                  childCount: p.recentRecords.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final InventoryProvider p;
  const _Header({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filament Hub',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.sub(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '我的耗材库',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
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

class _OverviewCard extends StatelessWidget {
  final InventoryProvider p;
  const _OverviewCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前库存',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${p.totalSpools}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '卷耗材',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: '种类',
                    value: '${p.totalSKUs}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withOpacity(0.15),
                ),
                Expanded(
                  child: _StatChip(
                    label: '材质',
                    value: '${p.totalMaterials} 种',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withOpacity(0.15),
                ),
                Expanded(
                  child: _StatChip(
                    label: '颜色',
                    value: '${p.totalColors} 个',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _MaterialCards extends StatelessWidget {
  final InventoryProvider p;
  const _MaterialCards({required this.p});

  @override
  Widget build(BuildContext context) {
    final entries = p.materialCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: top.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MaterialRowTile(
              material: e.key,
              count: e.value,
              color: _materialColor(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _materialColor(String m) {
    switch (m) {
      case 'PLA': return const Color(0xFF22C55E);
      case 'PETG': return const Color(0xFF1E88E5);
      case 'ABS': return const Color(0xFF9E9E9E);
      case 'TPU': return const Color(0xFFE53935);
      default: return AppColors.primary;
    }
  }
}

class _MaterialRowTile extends StatelessWidget {
  final String material;
  final int count;
  final Color color;
  const _MaterialRowTile({
    required this.material,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.layers_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              material,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
              ),
            ),
          ),
          Text(
            '$count 卷',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(fontSize: 13, color: AppColors.primary),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WarningsList extends StatelessWidget {
  final InventoryProvider p;
  const _WarningsList({required this.p});

  @override
  Widget build(BuildContext context) {
    final warnings = p.warningList.take(5).toList();
    if (warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Text(
                '所有耗材库存充足',
                style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: warnings.map((f) => WarningCard(
          filament: f,
          onTap: () {},
        )).toList(),
      ),
    );
  }
}
