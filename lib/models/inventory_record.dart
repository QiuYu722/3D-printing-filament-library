import 'dart:convert';

enum InventoryType { stockIn, stockOut }

extension InventoryTypeX on InventoryType {
  String get label => switch (this) {
        InventoryType.stockIn => '入库',
        InventoryType.stockOut => '取走',
      };

  String get arrow => switch (this) {
        InventoryType.stockIn => '↑',
        InventoryType.stockOut => '↓',
      };
}

class InventoryRecord {
  final String id;
  final String filamentId;
  final InventoryType type;
  final int quantity;
  final String reason;
  final String? remark;
  final DateTime createdAt;

  InventoryRecord({
    required this.id,
    required this.filamentId,
    required this.type,
    required this.quantity,
    this.reason = '',
    this.remark,
    required this.createdAt,
  });

  String get quantityDisplay =>
      '${type == InventoryType.stockIn ? '+' : '-'}$quantity';

  Map<String, dynamic> toMap() => {
        'id': id,
        'filamentId': filamentId,
        'type': type.name,
        'quantity': quantity,
        'reason': reason,
        'remark': remark,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InventoryRecord.fromMap(Map<String, dynamic> m) => InventoryRecord(
        id: m['id'] as String,
        filamentId: m['filamentId'] as String,
        type: InventoryType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => InventoryType.stockIn,
        ),
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        reason: (m['reason'] as String?) ?? '',
        remark: m['remark'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );

  String toJson() => json.encode(toMap());
  factory InventoryRecord.fromJson(String s) =>
      InventoryRecord.fromMap(json.decode(s) as Map<String, dynamic>);
}
