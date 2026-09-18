import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import '../models/filament.dart';
import '../models/inventory_record.dart';

/// Local storage backed by SharedPreferences with JSON serialization.
/// Can be migrated to Drift by implementing this interface with a Drift database.
class StorageService {
  static const _filamentsKey = 'filaments_v2';
  static const _recordsKey = 'records_v2';
  static const _darkModeKey = 'dark_mode_v1';
  static const _initializedKey = 'initialized_v2';
  static const _materialHistoryKey = 'material_history_v1';
  static const _defaultMinQtyKey = 'default_min_qty_v1';

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // ── Filaments ──
  Future<List<Filament>> loadFilaments() async {
    final raw = _prefs.getString(_filamentsKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => Filament.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveFilaments(List<Filament> filaments) async {
    final raw = json.encode(filaments.map((f) => f.toMap()).toList());
    await _prefs.setString(_filamentsKey, raw);
  }

  // ── Records ──
  Future<List<InventoryRecord>> loadRecords() async {
    final raw = _prefs.getString(_recordsKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => InventoryRecord.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveRecords(List<InventoryRecord> records) async {
    final raw = json.encode(records.map((r) => r.toMap()).toList());
    await _prefs.setString(_recordsKey, raw);
  }

  // ── Settings ──
  bool get isDarkMode => _prefs.getBool(_darkModeKey) ?? false;

  Future<void> setDarkMode(bool v) => _prefs.setBool(_darkModeKey, v);

  bool get isInitialized => _prefs.getBool(_initializedKey) ?? false;

  Future<void> markInitialized() => _prefs.setBool(_initializedKey, true);

  /// 清空所有数据（耗材、记录、初始化标记），保留深色模式设置。
  Future<void> clearAllData() async {
    await _prefs.remove(_filamentsKey);
    await _prefs.remove(_recordsKey);
    await _prefs.remove(_initializedKey);
  }

  // ── Material History ──
  List<String> loadMaterialHistory() {
    final raw = _prefs.getStringList(_materialHistoryKey);
    return raw ?? ['PLA', 'PETG', 'ABS', 'TPU', 'PLA+', 'ASA'];
  }

  Future<void> saveMaterialHistory(List<String> materials) async {
    await _prefs.setStringList(_materialHistoryKey, materials);
  }

  Future<void> addMaterialToHistory(String material) async {
    final list = loadMaterialHistory();
    if (!list.contains(material)) {
      list.insert(0, material);
      if (list.length > 20) list.removeLast();
      await saveMaterialHistory(list);
    }
  }

  // ── Default Min Quantity ──
  int get defaultMinQuantity => _prefs.getInt(_defaultMinQtyKey) ?? 1;

  Future<void> setDefaultMinQuantity(int value) => _prefs.setInt(_defaultMinQtyKey, value);

  // ── Import / Export ──
  Future<String> exportAllJson() async {
    final filaments = await loadFilaments();
    final records = await loadRecords();
    final map = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'filaments': filaments.map((f) => f.toMap()).toList(),
      'records': records.map((r) => r.toMap()).toList(),
    };
    return json.encode(map);
  }

  /// 导入耗材数据（不包含记录），返回导入数量
  Future<({int count, String? error})> importFilamentsJson(String jsonStr) async {
    try {
      final data = json.decode(jsonStr);
      if (data is! Map) {
        return (count: 0, error: 'JSON 顶层必须是对象，例如 {"filaments":[...]}');
      }
      final rawList = data['filaments'];
      if (rawList is! List) {
        return (count: 0, error: '未找到 "filaments" 数组字段');
      }
      if (rawList.isEmpty) {
        return (count: 0, error: '"filaments" 数组为空');
      }

      final existing = await loadFilaments();
      final existingCodes = existing.map((f) => f.code).toSet();
      final records = await loadRecords();
      final now = DateTime.now();

      int count = 0;
      int skipped = 0;
      for (final item in rawList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final code = (m['code'] as String?)?.trim() ?? '';
        if (code.isEmpty || existingCodes.contains(code)) {
          skipped++;
          continue;
        }

        existing.add(_filamentFromFields(
          code: code,
          material: (m['material'] as String?) ?? '',
          colorName: (m['colorName'] as String?) ?? '',
          colorHex: (m['colorHex'] as String?) ?? '',
          quantity: (m['quantity'] as num?)?.toInt() ?? 0,
          minQuantity: (m['minQuantity'] as num?)?.toInt() ?? 1,
          brand: (m['brand'] as String?) ?? '',
          id: 'json_${now.microsecondsSinceEpoch}_$count',
          createdAt: now,
        ));
        existingCodes.add(code);
        count++;
      }

      await saveFilaments(existing);
      await saveRecords(records);
      if (count == 0) {
        return (
          count: 0,
          error: skipped > 0 ? '所有编号已存在或为空（跳过 $skipped 条）' : '没有可导入的数据'
        );
      }
      return (count: count, error: null);
    } catch (e) {
      return (count: 0, error: '解析失败：${e.toString()}');
    }
  }

  /// 从 CSV / 制表符分隔文本导入耗材，返回导入数量
  /// 支持带表头或无表头；无表头时默认列顺序：编号|颜色名称|色值|数量|品牌|材质
  Future<({int count, String? error})> importFilamentsDelimited(String text) async {
    try {
      final lines = text
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        return (count: 0, error: '文件内容为空');
      }

      final first = lines.first.trimLeft();
      if (first.startsWith('{') || first.startsWith('[')) {
        return (count: 0, error: '文件内容是 JSON，请使用「粘贴 JSON 导入」');
      }

      final delim = lines.first.contains('\t') ? '\t' : ',';
      final cells = lines
          .map((l) => l.split(delim).map((c) => c.trim()).toList())
          .toList();
      final hasHeader = _looksLikeHeader(cells.first);
      final count = await _importFromCells(cells, hasHeader);
      if (count == 0) {
        return (count: 0, error: '未导入任何数据：请确认每行包含「编号」，且编号不重复');
      }
      return (count: count, error: null);
    } catch (e) {
      return (count: 0, error: '解析失败：${e.toString()}');
    }
  }

  /// 从 Excel 字节数据导入耗材，返回导入数量
  /// 支持带表头或无表头；无表头时默认列顺序：编号|颜色名称|色值|数量|品牌|材质
  Future<({int count, String? error})> importFilamentsExcel(List<int> bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return (count: 0, error: 'Excel 文件为空');
      }

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) {
        return (count: 0, error: 'Excel 无数据行');
      }

      final cells = <List<String>>[];
      for (final row in rows) {
        final line = <String>[];
        for (final cell in row) {
          line.add(cell?.value?.toString() ?? '');
        }
        cells.add(line);
      }

      final hasHeader = cells.isNotEmpty && _looksLikeHeader(cells.first);
      final count = await _importFromCells(cells, hasHeader);
      if (count == 0) {
        return (count: 0, error: '未导入任何数据：请确认包含「编号」列，且编号不重复');
      }
      return (count: count, error: null);
    } catch (e) {
      return (count: 0, error: 'Excel 解析失败：${e.toString()}');
    }
  }

  // ── 共享导入逻辑 ──
  bool _looksLikeHeader(List<String> firstRow) {
    return firstRow.any((c) {
      final v = c.trim().toLowerCase();
      return v.contains('编号') || v.contains('材质') || v.contains('颜色') || v == 'code';
    });
  }

  Future<int> _importFromCells(List<List<String>> cells, bool hasHeader) async {
    if (cells.isEmpty) return 0;

    final existing = await loadFilaments();
    final existingCodes = existing.map((f) => f.code).toSet();
    final records = await loadRecords();
    final now = DateTime.now();

    // 默认（无表头）列顺序：编号|颜色名称|色值|数量|品牌|材质
    int codeIdx = 0;
    int colorNameIdx = 1;
    int colorHexIdx = 2;
    int quantityIdx = 3;
    int brandIdx = 4;
    int materialIdx = 5;
    int minQtyIdx = -1;

    int startRow = 0;
    if (hasHeader) {
      startRow = 1;
      final header = cells.first;
      for (int i = 0; i < header.length; i++) {
        final v = header[i].trim().toLowerCase();
        if (v.contains('编号') || v == 'code' || v.contains('编码')) {
          codeIdx = i;
        } else if (v.contains('颜色名') || v == '颜色' || v == 'colorname') {
          colorNameIdx = i;
        } else if (v.contains('色值') || v.contains('hex')) {
          colorHexIdx = i;
        } else if (v.contains('数量') || v == 'quantity' || v.contains('库存')) {
          quantityIdx = i;
        } else if (v.contains('品牌') || v == 'brand') {
          brandIdx = i;
        } else if (v.contains('材质') || v == 'material' || v.contains('类型')) {
          materialIdx = i;
        } else if (v.contains('预警') || v.contains('最低') || v.contains('min')) {
          minQtyIdx = i;
        }
      }
    }

    int count = 0;
    for (int r = startRow; r < cells.length; r++) {
      final row = cells[r];
      final code = _cell(row, codeIdx);
      if (code.isEmpty || existingCodes.contains(code)) continue;

      existing.add(_filamentFromFields(
        code: code,
        material: _cell(row, materialIdx),
        colorName: _cell(row, colorNameIdx),
        colorHex: _cell(row, colorHexIdx),
        quantity: int.tryParse(_cell(row, quantityIdx)) ?? 0,
        minQuantity: minQtyIdx >= 0 ? (int.tryParse(_cell(row, minQtyIdx)) ?? 1) : 1,
        brand: _cell(row, brandIdx),
        id: 'import_${now.microsecondsSinceEpoch}_$r',
        createdAt: now,
      ));
      existingCodes.add(code);
      count++;
    }

    await saveFilaments(existing);
    await saveRecords(records);
    return count;
  }

  Filament _filamentFromFields({
    required String code,
    required String material,
    required String colorName,
    required String colorHex,
    required int quantity,
    required int minQuantity,
    required String brand,
    required String id,
    required DateTime createdAt,
  }) {
    return Filament(
      id: id,
      code: code,
      material: material.isEmpty ? 'PLA' : material,
      colorName: colorName.isEmpty ? '未知' : colorName,
      colorHex: _normalizeHex(colorHex),
      brand: brand.isEmpty ? null : brand,
      quantity: quantity < 0 ? 0 : quantity,
      minQuantity: minQuantity < 0 ? 1 : minQuantity,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  String _cell(List<String> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx].trim();
  }

  String _normalizeHex(String hex) {
    if (hex.isEmpty) return '#CCCCCC';
    var h = hex.trim();
    if (!h.startsWith('#')) h = '#$h';
    if (h.length == 7) return h.toUpperCase();
    if (h.length == 4) {
      // #RGB -> #RRGGBB
      final r = h[1];
      final g = h[2];
      final b = h[3];
      return '#$r$r$g$g$b$b'.toUpperCase();
    }
    return '#CCCCCC';
  }
}
