import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../providers/inventory_provider.dart';
import '../pages/home_page.dart';
import '../pages/inventory_page.dart';
import '../pages/statistics_page.dart';
import '../pages/settings_page.dart';
import '../pages/stock_in_page.dart';
import '../pages/stock_out_page.dart';
import '../pages/scan_page.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/floating_operation_button.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  void _onTap(int i) {
    if (i == 2) {
      _showOperationSheet();
      return;
    }
    setState(() => _index = i);
  }

  void _showOperationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _OperationSheet(onAction: (type) {
        Navigator.pop(ctx);
        _navigateToOperation(type);
      }),
    );
  }

  void _navigateToOperation(_OpType type) {
    final provider = context.read<InventoryProvider>();
    switch (type) {
      case _OpType.stockIn:
        if (provider.filaments.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先添加耗材')),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockInPage()));
      case _OpType.stockOut:
        if (provider.filaments.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先添加耗材')),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOutPage()));
      case _OpType.scan:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _index > 2 ? _index - 1 : _index,
        children: [
          HomePage(),
          InventoryPage(),
          StatisticsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _onTap,
      ),
      floatingActionButton: FloatingOperationButton(onPressed: _showOperationSheet),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

enum _OpType { stockIn, stockOut, scan }

class _OperationSheet extends StatelessWidget {
  final void Function(_OpType) onAction;
  const _OperationSheet({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '快捷操作',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _OpItem(
                    icon: Icons.inventory_2_rounded,
                    label: '录入耗材',
                    color: AppColors.success,
                    onTap: () => onAction(_OpType.stockIn),
                  ),
                  const SizedBox(width: 12),
                  _OpItem(
                    icon: Icons.output_rounded,
                    label: '取走耗材',
                    color: AppColors.warning,
                    onTap: () => onAction(_OpType.stockOut),
                  ),
                  const SizedBox(width: 12),
                  _OpItem(
                    icon: Icons.camera_alt_rounded,
                    label: '拍照录入',
                    color: AppColors.primary,
                    onTap: () => onAction(_OpType.scan),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OpItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
