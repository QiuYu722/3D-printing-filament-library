import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_record.dart';
import '../widgets/record_tile.dart';
import '../widgets/empty_state.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _filter = '全部'; // 全部, 入库, 取走

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    var records = [...p.records]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_filter == '入库') {
      records = records.where((r) => r.type == InventoryType.stockIn).toList();
    } else if (_filter == '取走') {
      records = records.where((r) => r.type == InventoryType.stockOut).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('出入库记录'),
      ),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: ['全部', '入库', '取走'].map((f) {
                final active = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.card(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? Colors.white : AppColors.sub(context),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // List
          Expanded(
            child: records.isEmpty
                ? const EmptyState(
                    title: '暂无记录',
                    icon: Icons.history_rounded,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: records.length,
                    itemBuilder: (ctx, i) {
                      final r = records[i];
                      final f = p.getFilament(r.filamentId);
                      return RecordTile(record: r, filament: f, showDate: true);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
