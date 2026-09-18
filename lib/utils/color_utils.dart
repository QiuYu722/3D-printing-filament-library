import 'package:flutter/painting.dart' show Color, HSLColor;

/// Classifies a hex color into a named color group for the Color Wall.
String classifyColor(String hex) {
  final color = _parseColor(hex);
  final hsl = HSLColor.fromColor(color);
  final hue = hsl.hue;
  final sat = hsl.saturation;
  final light = hsl.lightness;

  if (light < 0.1) return '黑色';
  if (light > 0.92) return '白色';
  if (sat < 0.12) return '灰色';

  if (hue < 15 || hue >= 345) return '红色';
  if (hue < 40) return '橙色';
  if (hue < 70) return '黄色';
  if (hue < 160) return '绿色';
  if (hue < 200) return '青色';
  if (hue < 260) return '蓝色';
  if (hue < 290) return '紫色';
  if (hue < 345) return '粉色';
  return '其他';
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

/// Predefined color group display colors
Color groupColor(String name) {
  switch (name) {
    case '黑色': return const Color(0xFF1A1A1A);
    case '白色': return const Color(0xFFF5F5F5);
    case '红色': return const Color(0xFFE53935);
    case '橙色': return const Color(0xFFFB8C00);
    case '黄色': return const Color(0xFFFDD835);
    case '绿色': return const Color(0xFF43A047);
    case '青色': return const Color(0xFF00ACC1);
    case '蓝色': return const Color(0xFF1E88E5);
    case '紫色': return const Color(0xFF8E24AA);
    case '粉色': return const Color(0xFFEC407A);
    case '灰色': return const Color(0xFF9E9E9E);
    default: return const Color(0xFF5B67F1);
  }
}

const colorGroupOrder = [
  '黑色', '白色', '红色', '橙色', '黄色',
  '绿色', '青色', '蓝色', '紫色', '粉色', '灰色', '其他',
];
