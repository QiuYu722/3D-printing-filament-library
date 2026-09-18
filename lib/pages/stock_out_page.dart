import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../widgets/filament_search_select.dart';

class StockOutPage extends StatefulWidget {
  final String? prefillId;
  const StockOutPage({super.key, this.prefillId});

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  String? _selectedId;
  final _qtyCtrl = TextEditingController(text: '1');
  String _reason = '打印使用';
  final _remarkCtrl = TextEditingController();
  bool _saving = false;

  final _reasons = ['打印使用', '损耗', '样品', '其他'];

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
    final currentQty = f?.quantity ?? 0;
    final inputQty = int.tryParse(_qtyCtrl.text) ?? 0;
    final insufficient = inputQty > currentQty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('取走耗材'),
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
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _Label(text: '取走数量'),
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
                  decoration: InputDecoration(
                    prefixText: '− ',
                    suffixText: '卷',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    errorText: insufficient ? '库存不足' : null,
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: insufficient ? AppColors.danger : AppColors.text(context),
                  ),
                  onChanged: (_) => setState(() {}),
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
          _Label(text: '取走原因'),
          const SizedBox(height: 8),
          Row(
            children: _reasons.map((r) {
              final active = r == _reason;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.warning.withOpacity(0.15) : AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppColors.warning : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.warning : AppColors.sub(context),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
            onPressed: (_saving || _selectedId == null || insufficient) ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('确认取走'),
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
    final error = await p.stockOut(
      filamentId: _selectedId!,
      quantity: qty,
      reason: _reason,
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
          content: Text('取走成功 −$qty'),
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
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.warning),
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