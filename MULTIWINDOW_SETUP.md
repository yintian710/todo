# 多窗口功能设置指南

## 常见问题

### 问题 1: MissingPluginException - window_manager 未注册
**错误信息**：
```
MissingPluginException(No implementation found for method ensureInitialized on channel window_manager)
```

**原因**：Flutter 桌面插件未正确注册到原生代码中。

**解决方案**：
```bash
# 1. 清理构建缓存
flutter clean

# 2. 重新获取依赖（会自动生成插件注册文件）
flutter pub get

# 3. 如果插件注册文件仍未生成，强制重新创建平台代码
flutter create --platforms=windows,linux,macos .

# 4. 再次获取依赖
flutter pub get

# 5. 重新运行应用
flutter run -d windows  # 或 linux/macos
```

**验证插件注册**：
检查以下文件是否包含 `WindowManagerPlugin` 和 `DesktopMultiWindowPlugin`：
- Windows: `windows/flutter/generated_plugin_registrant.cc`
- Linux: `linux/flutter/generated_plugin_registrant.cc`
- macOS: `macos/Flutter/GeneratedPluginRegistrant.swift`

### 问题 2: desktop_multi_window 包未安装
**错误信息**：
```
Undefined name 'DesktopMultiWindow'
```

**原因**：依赖包未成功安装。

## 完整设置步骤

### 步骤 1：安装依赖
在项目根目录运行：
```bash
flutter pub get
```

### 步骤 2：验证安装
检查 `pubspec.lock` 文件中是否包含 `desktop_multi_window` 条目。

### 步骤 3：清理并重新构建
```bash
flutter clean
flutter pub get
flutter build windows  # 或 linux/macos
```

## 如果依赖安装失败

### 尝试不同版本
编辑 `pubspec.yaml`，尝试以下版本：
- `desktop_multi_window: ^0.1.0`
- `desktop_multi_window: ^0.2.0`
- `desktop_multi_window: any` （最新版本）

### 检查平台兼容性
确保你的 Flutter SDK 版本支持桌面开发：
```bash
flutter doctor
flutter config --enable-windows-desktop  # 或 linux/macos
```

## 替代方案：使用 window_manager 创建对话框窗口

如果多窗口包无法使用，可以使用 `window_manager`（已安装）创建浮动对话框：

```dart
// 在 board_card.dart 中修改 _openFloatingWindow 方法
Future<void> _openFloatingWindow() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: Container(
        width: 300,
        height: 450,
        child: BoardFloatingWindow(arguments: {
          'boardId': widget.board.id,
          'boardName': widget.board.name,
          'boardColor': widget.board.color.value,
        }),
      ),
    ),
  );
}
```

注：这不是真正的独立窗口，只是一个浮动对话框。
