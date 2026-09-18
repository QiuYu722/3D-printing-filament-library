import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../models/filament.dart';
import '../utils/color_utils.dart';
import 'filament_detail_page.dart';

class ColorWallPage extends StatefulWidget {
  const ColorWallPage({super.key});

  @override
  State<ColorWallPage> createState() => _ColorWallPageState();
}

class _ColorWallPageState extends State<ColorWallPage> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();

    // Group filaments by color classification
    final groups = <String, List<Filament>>{};
    for (final f in p.filaments) {
      final group = classifyColor(f.colorHex);
      groups.putIfAbsent(group, () => []).add(f);
    }

    // If a group is selected, show its filaments
    if (_selectedGroup != null) {
      final list = groups[_selectedGroup] ?? [];
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _selectedGroup = null),
          ),
          title: Text('$_selectedGroup 色系'),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final f = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => FilamentDetailPage(filamentId: f.id)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: f.colorValue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider(context)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.code,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text(context),
                            ),
                          ),
                          Text(
                            '${f.colorName} · ${f.material}',
                            style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${f.quantity}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sub(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Show color wall
    final sortedGroups = colorGroupOrder.where((g) => groups.containsKey(g)).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('我的耗材颜色'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: sortedGroups.length,
        itemBuilder: (ctx, i) {
          final group = sortedGroups[i];
          final items = groups[group]!;
          final color = groupColor(group);

          return GestureDetector(
            onTap: () => setState(() => _selectedGroup = group),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              Color.lerp(color, Colors.black, 0.15) ?? color,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                        Text(
                          '${items.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
