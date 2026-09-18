import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../models/filament.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/filter_chip_group.dart';
import '../widgets/empty_state.dart';
import 'filament_detail_page.dart';
import 'add_filament_page.dart';
import 'color_wall_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _query = '';
  String _material = '全部';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Filament> _filtered(List<Filament> all) {
    var list = _material == '全部' ? all : all.where((f) => f.material == _material).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((f) {
        return f.code.toLowerCase().contains(q) ||
            f.colorName.toLowerCase().contains(q) ||
            f.material.toLowerCase().contains(q) ||
            (f.brand?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final materials = ['全部', ...p.materialCounts.keys.toList()..sort()];
    final filtered = _filtered(p.filaments);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    '耗材库',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ColorWallPage()),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.palette_rounded, size: 20, color: AppColors.sub(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFilamentPage()),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomSearchBar(
                controller: _searchCtrl,
                hintText: '搜索耗材编号、颜色、材质',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilterChipGroup(
                labels: materials,
                selected: _material,
                onSelected: (v) => setState(() => _material = v),
              ),
            ),
            const SizedBox(height: 12),
            // Table
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      title: p.filaments.isEmpty ? '还没有耗材' : '未找到匹配耗材',
                      subtitle: p.filaments.isEmpty
                          ? '添加第一卷耗材，开始管理你的 3D 打印库存。'
                          : '尝试更换关键词或筛选条件。',
                      actionLabel: p.filaments.isEmpty ? '添加耗材' : null,
                      onAction: p.filaments.isEmpty
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddFilamentPage()),
                              )
                          : null,
                    )
                  : _FilamentTable(
                      filaments: filtered,
                      isDark: isDark,
                      onTap: (f) => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FilamentDetailPage(filamentId: f.id)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilamentTable extends StatelessWidget {
  final List<Filament> filaments;
  final bool isDark;
  final ValueChanged<Filament> onTap;
  const _FilamentTable({required this.filaments, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final headerColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDF2FF);
    final altRowColor = isDark ? const Color(0xFF181818) : const Color(0xFFF8FAFF);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: headerColor,
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      '编号',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '颜色',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '数量',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '类型',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                    ),
                  ),
                ],
              ),
            ),
            // Data rows
            ...filaments.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              final isAlt = i.isOdd;
              final rowColor = isAlt ? altRowColor : (isDark ? const Color(0xFF1B1B1B) : Colors.white);

              return GestureDetector(
                onTap: () => onTap(f),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: rowColor,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 编号
                      SizedBox(
                        width: 70,
                        child: Text(
                          f.code,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 颜色 (色块 + 名称)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: f.colorValue,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f.colorName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 数量
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${f.quantity}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: f.quantity == 0 ? AppColors.danger : AppColors.text(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 类型 (材质)
                      Expanded(
                        flex: 2,
                        child: Text(
                          f.material,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.sub(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
