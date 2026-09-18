import 'package:flutter/material.dart';
import '../pages/filament_detail_page.dart';
import '../pages/add_filament_page.dart';
import '../pages/stock_in_page.dart';
import '../pages/stock_out_page.dart';
import '../pages/color_wall_page.dart';
import '../pages/records_page.dart';
import '../pages/warnings_page.dart';
import '../pages/scan_page.dart';

class AppRoutes {
  static const detail = '/detail';
  static const addFilament = '/add';
  static const stockIn = '/stock-in';
  static const stockOut = '/stock-out';
  static const colorWall = '/color-wall';
  static const records = '/records';
  static const warnings = '/warnings';
  static const scan = '/scan';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case detail:
        final id = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => FilamentDetailPage(filamentId: id));
      case addFilament:
        return MaterialPageRoute(builder: (_) => const AddFilamentPage());
      case stockIn:
        return MaterialPageRoute(builder: (_) => const StockInPage());
      case stockOut:
        return MaterialPageRoute(builder: (_) => const StockOutPage());
      case colorWall:
        return MaterialPageRoute(builder: (_) => const ColorWallPage());
      case records:
        return MaterialPageRoute(builder: (_) => const RecordsPage());
      case warnings:
        return MaterialPageRoute(builder: (_) => const WarningsPage());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanPage());
      default:
        return null;
    }
  }
}
