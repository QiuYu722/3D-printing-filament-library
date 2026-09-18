import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../widgets/filament_search_select.dart';

class StockInPage extends StatefulWidget {
  final String? prefillId;
  const StockInPage({super.key, this.prefillId});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  String? _selectedId;
  final _qtyCtrl = TextEditingController(text: '1');
  final _remarkCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.prefillId;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final f = _selectedId != null ? p.getFilament(_selectedId!) : null;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('录入耗材'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _Label(text: '选择耗材'),
          const SizedBox(height: 8),
          FilamentSearchSelect(
            filaments: p.filaments,
            selectedId: _selectedId,
            onChanged: (id) => setState(() => _selectedId = id),
          ),
          if (f != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: f.colorValue,
                      borderRadius: BorderRadius.circular(14),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                        Text(
                          '${f.colorName} · ${f.material}',
                          style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '当前 ${f.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _Label(text: '本次入库数量'),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                onTap: () {
                  final v = (int.tryParse(_qtyCtrl.text) ?? 0) - 1;
                  if (v > 0) _qtyCtrl.text = v.toString();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    suffixText: '卷',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StepBtn(
                icon: Icons.add_rounded,
                onTap: () {
                  final v = (int.tryParse(_qtyCtrl.text) ?? 0) + 1;
                  _qtyCtrl.text = v.toString();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Label(text: '备注 (选填)'),
          const SizedBox(height: 8),
          TextField(
            controller: _remarkCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '输入备注...'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_saving || _selectedId == null) ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('确认入库'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedId == null) return;
    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效数量'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _saving = true);
    final p = context.read<InventoryProvider>();
    final error = await p.stockIn(
      filamentId: _selectedId!,
      quantity: qty,
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
    );
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('入库成功 +$qty'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.sub(context)),
    );
  }
}