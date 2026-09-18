# Filament Hub - 3D打印耗材库管理系统

## 运行前提

1. **安装 Flutter SDK** (>=3.4.0)
   - 下载地址: https://docs.flutter.dev/get-started/install
   - 将 `flutter/bin` 添加到系统 PATH

2. **安装 Android Studio** (用于 Android 开发)
   - 包含 Android SDK 和命令行工具

3. **验证安装**
   ```bash
   flutter doctor
   ```

## 运行步骤

```bash
# 1. 进入项目目录
cd APP

# 2. 获取依赖
flutter pub get

# 3. 运行项目 (连接 Android 设备或模拟器)
flutter run

# 或运行在 Web 上
flutter run -d chrome

# 或运行在 Windows 上
flutter run -d windows
```

## 构建发布版本

```bash
# Android APK
flutter build apk

# Web
flutter build web

# Windows
flutter build windows
```

## 项目结构

```
lib/
├── main.dart              # 入口文件
├── app/
│   ├── app.dart           # 根 Scaffold + 底部导航
│   ├── theme.dart         # 亮/暗主题定义
│   └── routes.dart        # 路由表
├── models/
│   ├── filament.dart      # 耗材数据模型
│   └── inventory_record.dart  # 出入库记录模型
├── services/
│   ├── storage_service.dart    # 本地持久化
│   └── inventory_service.dart  # 业务逻辑
├── providers/
│   └── inventory_provider.dart  # 状态管理 (ChangeNotifier)
├── pages/
│   ├── home_page.dart
│   ├── inventory_page.dart
│   ├── filament_detail_page.dart
│   ├── add_filament_page.dart
│   ├── stock_in_page.dart
│   ├── stock_out_page.dart
│   ├── color_wall_page.dart
│   ├── statistics_page.dart
│   ├── records_page.dart
│   ├── warnings_page.dart
│   ├── scan_page.dart
│   └── settings_page.dart
├── widgets/
│   ├── filament_card.dart
│   ├── filament_color_view.dart
│   ├── warning_card.dart
│   ├── record_tile.dart
│   ├── statistic_card.dart
│   ├── custom_search_bar.dart
│   ├── filter_chip_group.dart
│   ├── bottom_nav.dart
│   ├── floating_operation_button.dart
│   └── empty_state.dart
└── utils/
    └── color_utils.dart
```

## 技术栈

- Flutter + Dart 3
- Material 3 Design
- Provider (状态管理)
- fl_chart (图表)
- shared_preferences (本地持久化)
- mobile_scanner (扫码，预留)
- drift (数据库，预留)

## 首次运行

首次启动会自动生成 21 卷模拟耗材数据，包含：
- PLA (12卷) / PETG (5卷) / ABS (2卷) / TPU (2卷)
- 正常/偏低/不足 三种库存状态
- 15 条历史出入库记录

数据保存在本地，可通过设置 > 数据备份进行管理。
