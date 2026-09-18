import 'package:flutter/material.dart';
import '../models/filament.dart';
import '../models/inventory_record.dart';
import '../services/inventory_service.dart';
import '../services/storage_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service;
  final StorageService _storage;

  List<Filament> _filaments = [];
  List<InventoryRecord> _records = [];
  List<String> _materialHistory = [];
  int _defaultMinQuantity = 1;
  bool _isDarkMode = false;
  bool _loading = true;

  InventoryProvider(this._service, this._storage);

  // ── Getters ──
  List<Filament> get filaments => List.unmodifiable(_filaments);
  List<InventoryRecord> get records => List.unmodifiable(_records);
  List<String> get materialHistory => List.unmodifiable(_materialHistory);
  int get defaultMinQuantity => _defaultMinQuantity;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _loading;

  // ── Stats ──
  int get totalSpools => _filaments.fold(0, (sum, f) => sum + f.quantity);
  int get totalSKUs => _filaments.length;
  int get totalMaterials => _filaments.map((f) => f.material).toSet().length;
  int get totalColors => _filaments.map((f) => f.colorHex).toSet().length;

  Map<String, int> get materialCounts {
    final m = <String, int>{};
    for (final f in _filaments) {
      m[f.material] = (m[f.material] ?? 0) + f.quantity;
    }
    return m;
  }

  // ── Warnings ──
  List<Filament> get criticalStock =>
      _filaments.where((f) => f.status == StockStatus.critical).toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));

  List<Filament> get lowStock =>
      _filaments.where((f) => f.status == StockStatus.low).toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));

  List<Filament> get normalStock =>
      _filaments.where((f) => f.status == StockStatus.normal).toList();

  List<Filament> get warningList => [...criticalStock, ...lowStock];

  // ── Recent records ──
  List<InventoryRecord> get recentRecords {
    final sorted = [..._records]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(8).toList();
  }

  // ── Init ──
  Future<void> init() async {
    _loading = true;
    notifyListeners();

    _isDarkMode = _storage.isDarkMode;
    _materialHistory = _storage.loadMaterialHistory();
    _defaultMinQuantity = _storage.defaultMinQuantity;

    if (!_storage.isInitialized) {
      _filaments = _service.generateDemoFilaments();
      _records = _service.generateDemoRecords(_filaments);
      await _service.persist(_filaments, _records);
      await _storage.markInitialized();
    } else {
      final data = await _service.loadData();
      _filaments = data.filaments;
      _records = data.records;
    }

    _loading = false;
    notifyListeners();
  }

  // ── Filament operations ──
  Future<String?> addFilament({
    required String code,
    required String material,
    required String colorName,
    required String colorHex,
    String? colorImage,
    String? brand,
    double diameter = 1.75,
    int quantity = 0,
    int minQuantity = 1,
  }) async {
    if (_filaments.any((f) => f.code == code)) return '耗材编号已存在';

    final now = DateTime.now();
    final f = Filament(
      id: _uuid(),
      code: code,
      material: material,
      colorName: colorName,
      colorHex: colorHex,
      colorImage: colorImage,
      brand: brand,
      diameter: diameter,
      quantity: quantity,
      minQuantity: minQuantity,
      createdAt: now,
      updatedAt: now,
    );

    _filaments = _service.addFilament(_filaments, f);

    // Save material to history
    await _storage.addMaterialToHistory(material);
    _materialHistory = _storage.loadMaterialHistory();

    if (quantity > 0) {
      final record = InventoryRecord(
        id: _uuid(),
        filamentId: f.id,
        type: InventoryType.stockIn,
        quantity: quantity,
        reason: '新购入',
        createdAt: now,
      );
      _records = [record, ..._records];
    }

    await _service.persist(_filaments, _records);
    notifyListeners();
    return null;
  }

  Future<String?> updateFilament(Filament updated) async {
    _filaments = _service.updateFilament(_filaments, updated.copyWith(updatedAt: DateTime.now()));
    await _service.persist(_filaments, _records);
    notifyListeners();
    return null;
  }

  Future<void> deleteFilament(String id, {bool keepRecords = true}) async {
    _filaments = _service.deleteFilament(_filaments, id);
    if (!keepRecords) {
      _records = _records.where((r) => r.filamentId != id).toList();
    }
    await _service.persist(_filaments, _records);
    notifyListeners();
  }

  // ── Stock In ──
  Future<String?> stockIn({
    required String filamentId,
    required int quantity,
    String reason = '新购入',
    String? remark,
  }) async {
    final result = _service.stockIn(
      filaments: _filaments,
      records: _records,
      filamentId: filamentId,
      quantity: quantity,
      reason: reason,
      remark: remark,
    );

    if (result.error != null) return result.error;

    _filaments = result.filaments;
    _records = result.records;
    await _service.persist(_filaments, _records);
    notifyListeners();
    return null;
  }

  // ── Stock Out ──
  Future<String?> stockOut({
    required String filamentId,
    required int quantity,
    String reason = '打印使用',
    String? remark,
  }) async {
    final result = _service.stockOut(
      filaments: _filaments,
      records: _records,
      filamentId: filamentId,
      quantity: quantity,
      reason: reason,
      remark: remark,
    );

    if (result.error != null) return result.error;

    _filaments = result.filaments;
    _records = result.records;
    await _service.persist(_filaments, _records);
    notifyListeners();
    return null;
  }

  // ── Helpers ──
  Filament? getFilament(String id) {
    final list = _filaments.where((f) => f.id == id);
    return list.isEmpty ? null : list.first;
  }

  /// 导出耗材库为 CSV 文本（表头：编号、颜色名称、色值、数量、品牌、材质、预警数量）
  String exportFilamentsCsv() {
    final buf = StringBuffer();
    buf.writeln('编号,颜色名称,色值,数量,品牌,材质,预警数量');
    for (final f in _filaments) {
      buf.writeln('${f.code},${_csvEscape(f.colorName)},${f.colorHex},${f.quantity},${_csvEscape(f.brand ?? '')},${_csvEscape(f.material)},${f.minQuantity}');
    }
    return buf.toString();
  }

  String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  List<InventoryRecord> recordsForFilament(String id) =>
      _records.where((r) => r.filamentId == id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Filament> search(String query) {
    if (query.isEmpty) return _filaments;
    final q = query.toLowerCase();
    return _filaments.where((f) {
      return f.code.toLowerCase().contains(q) ||
          f.colorName.toLowerCase().contains(q) ||
          f.material.toLowerCase().contains(q) ||
          (f.brand?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Filament> byMaterial(String material) {
    if (material == '全部') return _filaments;
    return _filaments.where((f) => f.material == material).toList();
  }

  // ── Settings ──
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDefaultMinQuantity(int value) async {
    _defaultMinQuantity = value;
    await _storage.setDefaultMinQuantity(value);
    notifyListeners();
  }

  /// 从 JSON 字符串导入耗材库，返回 (导入数量, 错误信息)
  Future<({int count, String? error})> importFilamentsFromJson(String jsonStr) async {
    final result = await _storage.importFilamentsJson(jsonStr);
    if (result.count > 0) {
      final data = await _service.loadData();
      _filaments = data.filaments;
      _records = data.records;
      notifyListeners();
    }
    return result;
  }

  /// 从 Excel 字节数据导入耗材库，返回 (导入数量, 错误信息)
  Future<({int count, String? error})> importFilamentsFromExcel(List<int> bytes) async {
    final result = await _storage.importFilamentsExcel(bytes);
    if (result.count > 0) {
      final data = await _service.loadData();
      _filaments = data.filaments;
      _records = data.records;
      notifyListeners();
    }
    return result;
  }

  /// 从 CSV / 制表符分隔文本导入耗材库，返回 (导入数量, 错误信息)
  Future<({int count, String? error})> importFilamentsFromDelimited(String text) async {
    final result = await _storage.importFilamentsDelimited(text);
    if (result.count > 0) {
      final data = await _service.loadData();
      _filaments = data.filaments;
      _records = data.records;
      notifyListeners();
    }
    return result;
  }

  /// 清空所有数据并重新生成演示数据。
  Future<void> resetAllData() async {
    _loading = true;
    notifyListeners();

    await _storage.clearAllData();
    _filaments = _service.generateDemoFilaments();
    _records = _service.generateDemoRecords(_filaments);
    await _service.persist(_filaments, _records);
    await _storage.markInitialized();
    _materialHistory = _storage.loadMaterialHistory();

    _loading = false;
    notifyListeners();
  }

  // ── Statistics ──
  Map<String, int> quantityByColor() {
    final m = <String, int>{};
    for (final f in _filaments) {
      m[f.colorName] = (m[f.colorName] ?? 0) + f.quantity;
    }
    final list = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(list);
  }

  Map<String, int> quantityByMaterial() {
    final m = <String, int>{};
    for (final f in _filaments) {
      m[f.material] = (m[f.material] ?? 0) + f.quantity;
    }
    return m;
  }

  Map<String, int> countByMaterial() => materialCounts;

  ({int inQty, int outQty}) recordsInRange(DateTime start, DateTime end) {
    int inQ = 0, outQ = 0;
    for (final r in _records) {
      if (r.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          r.createdAt.isBefore(end.add(const Duration(seconds: 1)))) {
        if (r.type == InventoryType.stockIn) {
          inQ += r.quantity;
        } else {
          outQ += r.quantity;
        }
      }
    }
    return (inQty: inQ, outQty: outQ);
  }

  String _uuid() => DateTime.now().microsecondsSinceEpoch.toString();
}
