import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import '../models/filament.dart';

class AddFilamentPage extends StatefulWidget {
  final Filament? filament;
  const AddFilamentPage({super.key, this.filament});

  @override
  State<AddFilamentPage> createState() => _AddFilamentPageState();
}

class _AddFilamentPageState extends State<AddFilamentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _code;
  late TextEditingController _colorName;
  late TextEditingController _brand;
  late TextEditingController _quantity;
  late TextEditingController _minQuantity;
  late TextEditingController _materialCtrl;
  late TextEditingController _colorHexCtrl;

  String _colorHex = '#5B67F1';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.filament;
    final p = Provider.of<InventoryProvider>(context, listen: false);
    _code = TextEditingController(text: f?.code ?? '');
    _colorName = TextEditingController(text: f?.colorName ?? '');
    _brand = TextEditingController(text: f?.brand ?? '');
    _quantity = TextEditingController(text: '${f?.quantity ?? 1}');
    _minQuantity = TextEditingController(text: '${f?.minQuantity ?? p.defaultMinQuantity}');
    _materialCtrl = TextEditingController(text: f?.material ?? '');
    _colorHex = f?.colorHex ?? '#5B67F1';
    _colorHexCtrl = TextEditingController(text: _colorHex);
  }

  @override
  void dispose() {
    _code.dispose();
    _colorName.dispose();
    _brand.dispose();
    _quantity.dispose();
    _minQuantity.dispose();
    _materialCtrl.dispose();
    _colorHexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.filament != null;
    final p = context.watch<InventoryProvider>();
    final history = p.materialHistory;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? '编辑耗材' : '添加耗材'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Color preview
            Center(
              child: GestureDetector(
                onTap: _pickColor,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _parseColor(_colorHex),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider(context)),
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(_colorHex).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.color_lens_rounded, color: _isLightColor() ? Colors.black54 : Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _colorName.text.isEmpty ? '点击选择颜色' : _colorName.text,
                style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
              ),
            ),
            const SizedBox(height: 24),
            _Field(
              label: '耗材编号',
              controller: _code,
              hint: '如 10300',
              validator: (v) => (v == null || v.isEmpty) ? '请输入编号' : null,
            ),
            const SizedBox(height: 16),
            // Material with history
            _Label(text: '材质'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _materialCtrl,
              decoration: InputDecoration(
                hintText: '如 PLA、PETG',
                counterText: '',
              ),
              maxLength: 20,
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入材质' : null,
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: history.map((m) {
                  final selected = _materialCtrl.text.trim() == m;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _materialCtrl.text = m;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.15)
                            : Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF252525)
                                : const Color(0xFFF2F2F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? AppColors.primary : AppColors.text(context),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Color (name + hex)
            _Label(text: '颜色'),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickColor,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(_colorHex),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _colorName,
                    decoration: const InputDecoration(
                      hintText: '颜色名称',
                      counterText: '',
                    ),
                    maxLength: 20,
                    validator: (v) => (v == null || v.isEmpty) ? '请输入颜色名称' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.color_lens_rounded),
                  color: AppColors.primary,
                  onPressed: _pickColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _colorHexCtrl,
              decoration: const InputDecoration(
                hintText: '#RRGGBB',
                counterText: '',
              ),
              maxLength: 7,
              onChanged: (v) {
                if (v.startsWith('#') && v.length == 7) {
                  setState(() => _colorHex = v);
                }
              },
            ),
            const SizedBox(height: 16),
            _Field(
              label: '数量',
              controller: _quantity,
              hint: '1',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return '请输入有效数量';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _Field(
              label: '品牌 (选填)',
              controller: _brand,
              hint: '如 拓竹',
            ),
            const SizedBox(height: 16),
            _Field(
              label: '库存预警数量',
              controller: _minQuantity,
              hint: '1',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return '请输入有效数量';
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : Text(isEdit ? '保存修改' : '保存耗材'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor() async {
    final colors = <(String, Color)>[
      ('白色', const Color(0xFFFFFFFF)),
      ('黑色', const Color(0xFF1A1A1A)),
      ('红色', const Color(0xFFE53935)),
      ('橙色', const Color(0xFFFB8C00)),
      ('黄色', const Color(0xFFFDD835)),
      ('绿色', const Color(0xFF43A047)),
      ('青色', const Color(0xFF00ACC1)),
      ('蓝色', const Color(0xFF1E88E5)),
      ('紫色', const Color(0xFF8E24AA)),
      ('粉色', const Color(0xFFEC407A)),
      ('灰色', const Color(0xFF9E9E9E)),
      ('棕色', const Color(0xFF795548)),
      ('橘色', const Color(0xFFFF8C00)),
      ('淡蓝色', const Color(0xFF81D4FA)),
      ('抹茶绿', const Color(0xFFAED581)),
      ('透明粉', const Color(0xFFF8BBD0)),
    ];

    final picked = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('选择颜色'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () {
                final hex = '#${c.$2.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                Navigator.pop(ctx, (c.$1, hex));
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.$2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider(context)),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );

    if (picked != null) {
      setState(() {
        _colorHex = picked.$2;
        _colorHexCtrl.text = picked.$2;
        _colorName.text = picked.$1;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final p = context.read<InventoryProvider>();
    final material = _materialCtrl.text.trim();
    String? error;

    if (widget.filament != null) {
      final updated = widget.filament!.copyWith(
        code: _code.text.trim(),
        material: material,
        colorName: _colorName.text.trim(),
        colorHex: _colorHex,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        quantity: int.tryParse(_quantity.text) ?? 0,
        minQuantity: int.tryParse(_minQuantity.text) ?? 1,
      );
      error = await p.updateFilament(updated);
    } else {
      error = await p.addFilament(
        code: _code.text.trim(),
        material: material,
        colorName: _colorName.text.trim(),
        colorHex: _colorHex,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        quantity: int.tryParse(_quantity.text) ?? 0,
        minQuantity: int.tryParse(_minQuantity.text) ?? 1,
      );
    }

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
          content: Text(widget.filament != null ? '耗材已更新' : '耗材已添加'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Color _parseColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 8) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) return Color(v);
    }
    if (h.length == 6) {
      final v = int.tryParse('FF$h', radix: 16);
      if (v != null) return Color(v);
    }
    return const Color(0xFF5B67F1);
  }

  bool _isLightColor() => _parseColor(_colorHex).computeLuminance() > 0.6;
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
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
