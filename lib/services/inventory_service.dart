import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/filament.dart';
import '../models/inventory_record.dart';
import 'storage_service.dart';

class InventoryService {
  final StorageService _storage;
  final _uuid = Uuid();

  InventoryService(this._storage);

  // ── Load ──
  Future<({List<Filament> filaments, List<InventoryRecord> records})> loadData() async {
    final filaments = await _storage.loadFilaments();
    final records = await _storage.loadRecords();
    return (filaments: filaments, records: records);
  }

  // ── Save ──
  Future<void> persist(List<Filament> filaments, List<InventoryRecord> records) async {
    await _storage.saveFilaments(filaments);
    await _storage.saveRecords(records);
  }

  // ── Filament CRUD ──
  List<Filament> addFilament(List<Filament> existing, Filament f) {
    return [...existing, f];
  }

  List<Filament> updateFilament(List<Filament> existing, Filament updated) {
    return existing.map((f) => f.id == updated.id ? updated : f).toList();
  }

  List<Filament> deleteFilament(List<Filament> existing, String id) {
    return existing.where((f) => f.id != id).toList();
  }

  // ── Stock In ──
  ({List<Filament> filaments, List<InventoryRecord> records, String? error}) stockIn({
    required List<Filament> filaments,
    required List<InventoryRecord> records,
    required String filamentId,
    required int quantity,
    String reason = '新购入',
    String? remark,
  }) {
    final idx = filaments.indexWhere((f) => f.id == filamentId);
    if (idx < 0) return (filaments: filaments, records: records, error: '耗材不存在');

    final f = filaments[idx];
    final newQty = f.quantity + quantity;
    final newFilaments = List<Filament>.from(filaments);
    newFilaments[idx] = f.copyWith(quantity: newQty, updatedAt: DateTime.now());

    final record = InventoryRecord(
      id: _uuid.v4(),
      filamentId: filamentId,
      type: InventoryType.stockIn,
      quantity: quantity,
      reason: reason,
      remark: remark,
      createdAt: DateTime.now(),
    );

    return (
      filaments: newFilaments,
      records: [record, ...records],
      error: null,
    );
  }

  // ── Stock Out ──
  ({List<Filament> filaments, List<InventoryRecord> records, String? error}) stockOut({
    required List<Filament> filaments,
    required List<InventoryRecord> records,
    required String filamentId,
    required int quantity,
    String reason = '打印使用',
    String? remark,
  }) {
    final idx = filaments.indexWhere((f) => f.id == filamentId);
    if (idx < 0) return (filaments: filaments, records: records, error: '耗材不存在');

    final f = filaments[idx];
    if (quantity > f.quantity) {
      return (filaments: filaments, records: records, error: '库存不足');
    }

    final newQty = max(0, f.quantity - quantity);
    final newFilaments = List<Filament>.from(filaments);
    newFilaments[idx] = f.copyWith(quantity: newQty, updatedAt: DateTime.now());

    final record = InventoryRecord(
      id: _uuid.v4(),
      filamentId: filamentId,
      type: InventoryType.stockOut,
      quantity: quantity,
      reason: reason,
      remark: remark,
      createdAt: DateTime.now(),
    );

    return (
      filaments: newFilaments,
      records: [record, ...records],
      error: null,
    );
  }

  // ── Seed Demo Data (from user's filament management system) ──
  List<Filament> generateDemoFilaments() {
    final now = DateTime.now();
    // Data imported from user's filament inventory screenshot
    // (code, material, colorName, colorHex, brand, quantity, minQuantity)
    final raw = <(String, String, String, String, String, int, int)>[
      ('10300', 'PLA', '橘色', '#FF8C00', '拓竹', 1, 1),
      ('10800', 'PLA', '棕色', '#795548', '拓竹', 1, 1),
      ('35600', 'PETG', '淡蓝色', '#81D4FA', '拓竹', 1, 1),
      ('230061', 'PETG', '透明粉', '#F8BBD0', '彩格', 2, 1),
      ('16401', 'PLA', '向日葵色', '#FDD835', '拓竹', 0, 1),
      ('35700', 'PETG', '粉色', '#F48FB1', '拓竹', 1, 1),
      ('35501', 'PETG', '抹茶绿', '#AED581', '拓竹', 0, 1),
    ];

    return raw.asMap().entries.map((e) {
      final i = e.key;
      final v = e.value;
      return Filament(
        id: _uuid.v4(),
        code: v.$1,
        material: v.$2,
        colorName: v.$3,
        colorHex: v.$4,
        brand: v.$5,
        diameter: 1.75,
        quantity: v.$6,
        minQuantity: v.$7,
        createdAt: now.subtract(Duration(days: 30 - i)),
        updatedAt: now.subtract(Duration(days: i)),
      );
    }).toList();
  }

  List<InventoryRecord> generateDemoRecords(List<Filament> filaments) {
    final now = DateTime.now();
    final reasons = ['打印使用', '新购入', '损耗', '样品', '打印使用', '新购入'];
    final records = <InventoryRecord>[];
    final rng = Random(42);

    for (var i = 0; i < 10; i++) {
      final f = filaments[rng.nextInt(filaments.length)];
      final isOut = rng.nextBool();
      final qty = [1, 1, 2, 1, 1][rng.nextInt(5)];
      records.add(InventoryRecord(
        id: _uuid.v4(),
        filamentId: f.id,
        type: isOut ? InventoryType.stockOut : InventoryType.stockIn,
        quantity: qty,
        reason: reasons[rng.nextInt(reasons.length)],
        remark: null,
        createdAt: now.subtract(Duration(days: i, hours: rng.nextInt(24))),
      ));
    }

    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }
}
