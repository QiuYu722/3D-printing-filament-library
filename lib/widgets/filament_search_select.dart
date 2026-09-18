import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/filament.dart';

/// 可通过输入「编号 / 颜色名称 / 材质」搜索过滤，并从下拉列表选择耗材。
class FilamentSearchSelect extends StatefulWidget {
  final List<Filament> filaments;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const FilamentSearchSelect({
    super.key,
    required this.filaments,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<FilamentSearchSelect> createState() => _FilamentSearchSelectState();
}

class _FilamentSearchSelectState extends State<FilamentSearchSelect> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  late List<Filament> _filtered;
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focusNode = FocusNode();
    _filtered = widget.filaments;
    if (widget.selectedId != null) {
      Filament? f;
      for (final e in widget.filaments) {
        if (e.id == widget.selectedId) {
          f = e;
          break;
        }
      }
      if (f != null) _ctrl.text = '${f.code} · ${f.colorName}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final query = q.trim().toLowerCase();
    final list = query.isEmpty
        ? widget.filaments
        : widget.filaments.where((f) =>
            f.code.toLowerCase().contains(query) ||
            f.colorName.toLowerCase().contains(query) ||
            f.material.toLowerCase().contains(query)).toList();
    setState(() {
      _filtered = list;
      _showList = true;
    });
  }

  void _select(Filament f) {
    _ctrl.text = '${f.code} · ${f.colorName}';
    _focusNode.unfocus();
    setState(() => _showList = false);
    widget.onChanged(f.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          onTap: () => setState(() => _showList = true),
          onChanged: _filter,
          decoration: InputDecoration(
            hintText: '输入编号或颜色名称搜索',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _ctrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _ctrl.clear();
                      _focusNode.unfocus();
                      setState(() {
                        _showList = false;
                        _filtered = widget.filaments;
                      });
                      widget.onChanged(null);
                    },
                  ),
          ),
        ),
        if (_showList) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider(context)),
            ),
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '没有匹配的耗材',
                      style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider(context)),
                    itemBuilder: (_, i) {
                      final f = _filtered[i];
                      return ListTile(
                        dense: true,
                        selected: f.id == widget.selectedId,
                        leading: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: f.colorValue,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.divider(context)),
                          ),
                        ),
                        title: Text('${f.code} · ${f.colorName}', style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${f.material} · 库存 ${f.quantity}', style: const TextStyle(fontSize: 12)),
                        onTap: () => _select(f),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}