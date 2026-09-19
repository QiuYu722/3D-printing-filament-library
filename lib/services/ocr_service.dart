import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 识别结果：材质、耗材编号、颜色名称。
class OcrResult {
  final String? material;
  final String? code;
  final String? colorName;
  const OcrResult({this.material, this.code, this.colorName});

  bool get isEmpty => material == null && code == null && colorName == null;
}

/// 拍照后从标签图片中识别文字，并解析出耗材关键字段。
class OcrService {
  static final RegExp _materialRe = RegExp(
    r'\b(?:PETG|PLA|ABS|ASA|TPU|TPE|PET|PCTG|PC|PA|NYLON|PVA|HIPS|PEEK|PEI|POM|PVB|CARBON|WOOD)\b',
  );
  static final RegExp _colorRe = RegExp(
    r'\b(?:GREEN|RED|BLACK|WHITE|BLUE|YELLOW|ORANGE|PURPLE|PINK|GRAY|GREY|BROWN|CYAN|GOLD|SILVER|TURQUOISE|BEIGE)\b',
    caseSensitive: false,
  );
  static const List<String> _chineseColors = [
    '绿', '红', '黑', '白', '蓝', '黄', '橙', '紫', '粉', '灰', '棕', '青', '金', '银',
  ];

  Future<OcrResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      final lines = <String>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final t = line.text.trim();
          if (t.isNotEmpty) lines.add(t);
        }
      }
      return _parse(lines);
    } catch (_) {
      return const OcrResult();
    } finally {
      recognizer.close();
    }
  }

  OcrResult _parse(List<String> lines) {
    String? material;
    String? code;
    String? colorName;

    for (final line in lines) {
      final up = line.toUpperCase();

      if (material == null && _materialRe.hasMatch(up)) {
        material = _clean(line);
      }

      if (code == null && RegExp(r'^\d{3,8}$').hasMatch(line.trim())) {
        code = line.trim();
      }

      if (colorName == null &&
          (_colorRe.hasMatch(up) || _chineseColors.any(up.contains))) {
        colorName = _clean(line);
      }
    }

    return OcrResult(material: material, code: code, colorName: colorName);
  }

  String _clean(String s) =>
      s.replaceAll(RegExp(r'^[:\-\s]+|[:\-\s]+$'), '').trim();
}