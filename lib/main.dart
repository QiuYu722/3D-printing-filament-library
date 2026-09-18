// Filament Hub — 3D 打印耗材库管理系统
// 源码仓库：github.com/QiuYu722/3D-printing-filament-library
// 请勿用于商业用途
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'app/theme.dart';
import 'services/inventory_service.dart';
import 'services/storage_service.dart';
import 'providers/inventory_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final service = InventoryService(storage);
  final provider = InventoryProvider(service, storage);
  await provider.init();
  runApp(FilamentApp(provider: provider));
}

class FilamentApp extends StatelessWidget {
  final InventoryProvider provider;
  const FilamentApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InventoryProvider>.value(value: provider),
      ],
      child: Consumer<InventoryProvider>(
        builder: (context, p, _) => MaterialApp(
          title: 'Filament Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: p.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const RootScaffold(),
        ),
      ),
    );
  }
}
