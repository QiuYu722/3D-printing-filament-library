import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../app/theme.dart';
import '../providers/inventory_provider.dart';
import 'warnings_page.dart';
import 'records_page.dart';
import 'scan_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.print_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3D Printer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '我的打印工作室',
                          style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.sub(context)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Settings items
            _SettingsGroup(
              title: '设置',
              items: [
                _SettingsItem(
                  icon: Icons.warehouse_outlined,
                  color: AppColors.primary,
                  title: '仓库设置',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('仓库设置 - 开发中')),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.notifications_active_outlined,
                  color: AppColors.warning,
                  title: '库存预警',
                  trailingText: p.warningList.isEmpty ? '正常' : '${p.warningList.length} 项',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WarningsPage()),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.success,
                  title: '拍照识别',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanPage()),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.restart_alt_rounded,
                  color: AppColors.danger,
                  title: '清空数据并重新登记',
                  onTap: () => _showResetConfirm(context, p),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Default min quantity
            _SettingsGroup(
              title: '默认设置',
              items: [
                _SettingsItem(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  title: '默认预警数量',
                  trailingText: '${p.defaultMinQuantity}',
                  onTap: () => _showDefaultMinQtyDialog(context, p),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dark mode
            _SettingsGroup(
              title: '外观',
              items: [
                _SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  color: const Color(0xFF6366F1),
                  title: '深色模式',
                  trailing: Switch.adaptive(
                    value: p.isDarkMode,
                    onChanged: (_) => p.toggleDarkMode(),
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // About & Import
            _SettingsGroup(
              title: '其他',
              items: [
                _SettingsItem(
                  icon: Icons.file_download_outlined,
                  color: AppColors.primary,
                  title: '导入耗材库',
                  trailingText: 'JSON',
                  onTap: () => _showImportDialog(context, p),
                ),
                _SettingsItem(
                  icon: Icons.file_upload_outlined,
                  color: AppColors.success,
                  title: '导出耗材库',
                  trailingText: 'CSV',
                  onTap: () => _exportFilaments(context, p),
                ),
                _SettingsItem(
                  icon: Icons.history_rounded,
                  color: AppColors.sub(context),
                  title: '出入库记录',
                  trailingText: '${p.records.length} 条',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordsPage()),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.sub(context),
                  title: '关于',
                  trailingText: 'v1.1.0',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirm(BuildContext context, InventoryProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('清空数据并重新登记'),
        content: const Text('此操作将清空所有耗材和出入库记录，并重新生成演示数据。确定继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await p.resetAllData();
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('数据已清空并重新登记')),
                );
              }
            },
            child: Text('确定', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showDefaultMinQtyDialog(BuildContext context, InventoryProvider p) {
    final ctrl = TextEditingController(text: '${p.defaultMinQuantity}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('默认预警数量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('新建耗材时的默认库存预警数量'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '请输入数量',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final n = int.tryParse(ctrl.text.trim());
              if (n == null || n < 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入有效数量')),
                );
                return;
              }
              await p.setDefaultMinQuantity(n);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFilaments(BuildContext context, InventoryProvider p) async {
    final csv = p.exportFilamentsCsv();
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final fileName = '耗材库_${_timestamp()}.csv';

    try {
      // 桌面 / Web：弹出保存对话框或触发下载
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '导出耗材库',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (!context.mounted) return;
      if (path == null) return; // 用户取消
      _snack(context, '已导出 ${p.totalSKUs} 条耗材', ok: true);
    } catch (_) {
      // 移动端 saveFile 不可用，回退写入应用文档目录
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}耗材库_${_timestamp()}.csv');
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          _snack(
            context,
            '已导出 ${p.totalSKUs} 条耗材，保存至应用文档目录',
            ok: true,
          );
        }
      } catch (e) {
        if (context.mounted) {
          _snack(context, '导出失败：$e', ok: false);
        }
      }
    }
  }

  String _timestamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  void _snack(BuildContext context, String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  void _showImportDialog(BuildContext context, InventoryProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ImportSheet(
        onPickExcel: () async {
          Navigator.pop(ctx);
          await _pickExcelAndImport(context, p);
        },
        onPasteJson: () {
          Navigator.pop(ctx);
          _showJsonImportDialog(context, p);
        },
      ),
    );
  }

  Future<void> _pickExcelAndImport(BuildContext context, InventoryProvider p) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      List<int>? bytes = file.bytes;
      // 部分机型 withData 返回 null，用路径兜底读取
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法读取文件内容，请改用「粘贴 JSON」导入')),
          );
        }
        return;
      }

      final ext = (file.extension ?? '').toLowerCase();
      late ({int count, String? error}) res;
      if (ext == 'csv' || ext == 'txt') {
        final text = utf8.decode(bytes, allowMalformed: true);
        res = await p.importFilamentsFromDelimited(text);
      } else {
        res = await p.importFilamentsFromExcel(bytes);
      }

      if (context.mounted) {
        final ok = res.error == null;
        final msg = ok ? '成功导入 ${res.count} 个耗材' : res.error!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：${e.toString().substring(0, e.toString().length > 80 ? 80 : e.toString().length)}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showJsonImportDialog(BuildContext context, InventoryProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('粘贴 JSON 导入'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '格式示例：',
                style: TextStyle(fontSize: 12, color: AppColors.sub(ctx)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFF0F0EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '{"filaments":[{"code":"10300","material":"PLA","colorName":"橘色","colorHex":"#FF8C00","quantity":1}]}',
                  style: TextStyle(fontSize: 11, color: AppColors.sub(ctx), fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: TextField(
                  controller: ctrl,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '在此粘贴 JSON 数据...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final content = ctrl.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入 JSON 数据')),
                );
                return;
              }
              final res = await p.importFilamentsFromJson(content);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                final ok = res.error == null;
                final msg = ok ? '成功导入 ${res.count} 个耗材' : res.error!;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Filament Hub'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3D 打印耗材库管理系统'),
            SizedBox(height: 8),
            Text('Version 1.1.0'),
            SizedBox(height: 8),
            Text('使用 Flutter 构建'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: items.map((item) {
              final idx = items.indexOf(item);
              return Column(
                children: [
                  item,
                  if (idx < items.length - 1)
                    Divider(height: 1, indent: 16, color: AppColors.divider(context)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    this.trailingText,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, color: AppColors.text(context)),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(fontSize: 14, color: AppColors.sub(context)),
              ),
            if (trailing != null) trailing!,
            if (trailing == null && trailingText == null && onTap != null)
              Icon(Icons.chevron_right_rounded, color: AppColors.sub(context), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ImportSheet extends StatelessWidget {
  final VoidCallback onPickExcel;
  final VoidCallback onPasteJson;
  const _ImportSheet({required this.onPickExcel, required this.onPasteJson});

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
                '导入耗材库',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '选择导入方式，相同编号将自动跳过',
                style: TextStyle(fontSize: 13, color: AppColors.sub(context)),
              ),
              const SizedBox(height: 20),
              // 文件导入
              _ImportOption(
                icon: Icons.table_chart_rounded,
                color: AppColors.success,
                title: '从文件导入',
                desc: '支持 .xlsx / .xls / .csv / .txt',
                onTap: onPickExcel,
              ),
              const SizedBox(height: 10),
              // JSON 导入
              _ImportOption(
                icon: Icons.code_rounded,
                color: AppColors.primary,
                title: '粘贴 JSON 导入',
                desc: '手动粘贴 JSON 数据',
                onTap: onPasteJson,
              ),
              const SizedBox(height: 8),
              // 格式说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.sub(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '文件列顺序：编号、颜色名称、色值、数量、品牌、材质（可含表头或直接是数据）',
                        style: TextStyle(fontSize: 12, color: AppColors.sub(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _ImportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF9F9F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: AppColors.sub(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.sub(context)),
          ],
        ),
      ),
    );
  }
}
