import 'dart:convert';
import 'dart:ui';

enum StockStatus { normal, low, critical }

extension StockStatusX on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.normal:
        return '库存正常';
      case StockStatus.low:
        return '库存偏低';
      case StockStatus.critical:
        return '库存不足';
    }
  }

  String get dot => switch (this) {
        StockStatus.normal => '🟢',
        StockStatus.low => '🟡',
        StockStatus.critical => '🔴',
      };
}

class Filament {
  final String id;
  final String code;
  final String material;
  final String colorName;
  final String colorHex;
  final String? colorImage;
  final String? brand;
  final double diameter;
  final int quantity;
  final int minQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Filament({
    required this.id,
    required this.code,
    required this.material,
    required this.colorName,
    required this.colorHex,
    this.colorImage,
    this.brand,
    this.diameter = 1.75,
    this.quantity = 0,
    this.minQuantity = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  StockStatus get status {
    if (quantity <= 0) return StockStatus.critical;
    if (quantity <= minQuantity) return StockStatus.critical;
    if (quantity <= minQuantity + 1) return StockStatus.low;
    return StockStatus.normal;
  }

  Color get colorValue => _parseColor(colorHex);

  String get displayQuantity => '$quantity';

  String get typeName {
    final parts = <String>[];
    if (brand != null && brand!.isNotEmpty) parts.add(brand!);
    parts.add(material);
    return parts.join(' ');
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'material': material,
        'colorName': colorName,
        'colorHex': colorHex,
        'colorImage': colorImage,
        'brand': brand,
        'diameter': diameter,
        'quantity': quantity,
        'minQuantity': minQuantity,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Filament.fromMap(Map<String, dynamic> m) => Filament(
        id: m['id'] as String,
        code: m['code'] as String,
        material: m['material'] as String,
        colorName: m['colorName'] as String,
        colorHex: m['colorHex'] as String,
        colorImage: m['colorImage'] as String?,
        brand: m['brand'] as String?,
        diameter: (m['diameter'] as num?)?.toDouble() ?? 1.75,
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        minQuantity: (m['minQuantity'] as num?)?.toInt() ?? 1,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  String toJson() => json.encode(toMap());
  factory Filament.fromJson(String s) => Filament.fromMap(json.decode(s) as Map<String, dynamic>);

  Filament copyWith({
    String? id,
    String? code,
    String? material,
    String? colorName,
    String? colorHex,
    String? colorImage,
    String? brand,
    double? diameter,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Filament(
        id: id ?? this.id,
        code: code ?? this.code,
        material: material ?? this.material,
        colorName: colorName ?? this.colorName,
        colorHex: colorHex ?? this.colorHex,
        colorImage: colorImage ?? this.colorImage,
        brand: brand ?? this.brand,
        diameter: diameter ?? this.diameter,
        quantity: quantity ?? this.quantity,
        minQuantity: minQuantity ?? this.minQuantity,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
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
