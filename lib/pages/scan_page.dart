import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  XFile? _image;
  bool _analyzing = false;

  final _codeCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _colorNameCtrl = TextEditingController();

  String _colorHex = '#5B67F1';
  List<Color> _palette = [];

  @override
  void dispose() {
    _codeCtrl.dispose();
    _materialCtrl.dispose();
    _colorNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('拍照识别'),
      ),
      body: _image == null ? _buildPickView() : _buildResultView(),
    );
  }

  // ── Pick view ──
  Widget _buildPickView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_rounded, size: 48, color: AppColors.primary.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text(
                    '拍摄耗材标签',
                    style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '拍照或选择标签图片',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '自动吸取色块，填写材质、编号、颜色名称',
              style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('拍照识别'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text('从相册选择'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result view ──
  Widget _buildResultView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Image preview
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              File(_image!.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.card(context),
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_rounded, color: AppColors.sub(context)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Color palette
        Text('色块吸取', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text(context))),
        const SizedBox(height: 12),
        _buildPaletteRow(),
        const SizedBox(height: 20),
        // Fields
        _buildField('材质', _materialCtrl, hint: '如 PLA / PETG / ABS'),
        const SizedBox(height: 12),
        _buildField('耗材编号', _codeCtrl, hint: '如 35501', number: true),
        const SizedBox(height: 12),
        _buildField('颜色名称', _colorNameCtrl, hint: '如 Avocado Green'),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _analyzing ? null : _save,
          icon: const Icon(Icons.check_rounded, size: 20),
          label: const Text('保存到耗材库'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('重新识别'),
        ),
      ],
    );
  }

  Widget _buildPaletteRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_analyzing) {
      return Container(
        height: 56,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text('正在吸取颜色...', style: TextStyle(fontSize: 13, color: AppColors.sub(context))),
          ],
        ),
      );
    }
    if (_palette.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('未吸取到颜色，请重试', style: TextStyle(fontSize: 13, color: AppColors.sub(context))),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _palette.map((c) {
        final hex = _colorToHex(c);
        final selected = hex == _colorHex;
        return GestureDetector(
          onTap: () => setState(() => _colorHex = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider(context),
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20, shadows: [Shadow(color: Colors.black45, blurRadius: 3)])
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? hint, bool number = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  // ── Actions ──
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (img == null) return;
      setState(() {
        _image = img;
        _analyzing = true;
        _palette = [];
      });
      await _extractPalette(img.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法获取图片：$e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _extractPalette(String path) async {
    final collected = <Color>[];
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        FileImage(File(path)),
        maximumColorCount: 16,
        size: const Size(260, 260),
      );
      collected.addAll([
        if (generator.dominantColor != null) generator.dominantColor!.color,
        if (generator.vibrantColor != null) generator.vibrantColor!.color,
        if (generator.lightVibrantColor != null) generator.lightVibrantColor!.color,
        if (generator.darkVibrantColor != null) generator.darkVibrantColor!.color,
        if (generator.mutedColor != null) generator.mutedColor!.color,
        if (generator.lightMutedColor != null) generator.lightMutedColor!.color,
        if (generator.darkMutedColor != null) generator.darkMutedColor!.color,
        ...generator.paletteColors.map((p) => p.color),
      ]);
    } catch (_) {}

    final seen = <String>{};
    final unique = <Color>[];
    for (final c in collected) {
      final hex = _colorToHex(c);
      if (!seen.contains(hex)) {
        seen.add(hex);
        unique.add(c);
      }
    }

    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _palette = unique;
      if (_palette.isNotEmpty) _colorHex = _colorToHex(_palette.first);
    });
  }

  Future<void> _save() async {
    final provider = context.read<InventoryProvider>();
    final code = _codeCtrl.text.trim();
    final material = _materialCtrl.text.trim();
    final colorName = _colorNameCtrl.text.trim();

    if (code.isEmpty) {
      _toast('请输入耗材编号');
      return;
    }
    if (material.isEmpty) {
      _toast('请输入材质');
      return;
    }

    final err = await provider.addFilament(
      code: code,
      material: material,
      colorName: colorName.isEmpty ? '未命名' : colorName,
      colorHex: _colorHex,
      quantity: 1,
    );

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已录入耗材 $code'), backgroundColor: AppColors.success),
    );
    _reset();
  }

  void _reset() {
    setState(() {
      _image = null;
      _analyzing = false;
      _palette = [];
      _colorHex = '#5B67F1';
      _codeCtrl.clear();
      _materialCtrl.clear();
      _colorNameCtrl.clear();
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  String _colorToHex(Color c) {
    String two(double v) {
      final n = (v * 255.0).round().clamp(0, 255).toInt();
      return n.toRadixString(16).padLeft(2, '0').toUpperCase();
    }
    return '#${two(c.r)}${two(c.g)}${two(c.b)}';
  }
}