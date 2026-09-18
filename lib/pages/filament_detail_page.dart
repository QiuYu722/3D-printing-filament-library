import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../models/filament.dart';
import '../widgets/filament_color_view.dart';
import '../widgets/record_tile.dart';
import 'stock_in_page.dart';
import 'stock_out_page.dart';
import 'add_filament_page.dart';

class FilamentDetailPage extends StatelessWidget {
  final String filamentId;
  const FilamentDetailPage({super.key, required this.filamentId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final f = p.getFilament(filamentId);
    if (f == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('耗材不存在')),
      );
    }
    final records = p.recordsForFilament(filamentId);
    final statusColor = switch (f.status) {
      StockStatus.normal => AppColors.success,
      StockStatus.low => AppColors.warning,
      StockStatus.critical => AppColors.danger,
    };

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('耗材详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showMoreMenu(context, f, p),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              children: [
                // Color display
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FilamentColorView(filament: f, size: double.infinity),
                  ),
                ),
                const SizedBox(height: 20),
                // Title section
                Text(
                  f.code,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${f.colorName} · ${f.material}',
                      style: TextStyle(fontSize: 16, color: AppColors.sub(context)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        f.status.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Current quantity
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '当前库存',
                            style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${f.quantity}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.inventory_2_rounded, size: 48, color: AppColors.primary.withOpacity(0.3)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '基本信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: '耗材编号', value: f.code),
                      _InfoRow(label: '材质', value: f.material),
                      _InfoRow(label: '颜色', value: f.colorName),
                      _InfoRow(label: '品牌', value: f.brand ?? '未设置'),
                      _InfoRow(label: '直径', value: '${f.diameter}mm'),
                      _InfoRow(label: '预警数量', value: '${f.minQuantity}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Records
                Row(
                  children: [
                    Text(
                      '最近记录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...records.take(10).map((r) => RecordTile(
                      record: r,
                      filament: f,
                      showDate: true,
                    )),
                if (records.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        '暂无操作记录',
                        style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(filament: f),
    );
  }

  void _showMoreMenu(BuildContext context, Filament f, InventoryProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sub(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('编辑耗材'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddFilamentPage(filament: f)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('删除耗材', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, f, p);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Filament f, InventoryProvider p) {
    bool keepRecords = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('删除耗材？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${f.code} ${f.colorName} ${f.material}'),
              const SizedBox(height: 12),
              Text('删除后相关库存记录是否保留？', style: TextStyle(fontSize: 14, color: AppColors.sub(context))),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: keepRecords,
                onChanged: (v) => setState(() => keepRecords = v ?? true),
                title: const Text('保留历史记录', style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                p.deleteFilament(f.id, keepRecords: keepRecords);
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('耗材已删除')),
                );
              },
              child: const Text('删除', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final Filament filament;
  const _BottomActions({required this.filament});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          border: Border(
            top: BorderSide(color: AppColors.divider(context)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockOutPage(prefillId: filament.id)),
                ),
                icon: const Icon(Icons.output_rounded, size: 18),
                label: const Text('取走耗材'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockInPage(prefillId: filament.id)),
                ),
                icon: const Icon(Icons.inventory_2_rounded, size: 18),
                label: const Text('录入耗材'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
