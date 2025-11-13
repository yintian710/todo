import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'providers/todo_provider.dart';
import 'services/config_service.dart';
import 'services/database_service.dart';
import 'pages/config_page.dart';
import 'pages/home_page.dart';
import 'multi_window_entry.dart' as multi_window_entry;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== 启动参数 ===');
  print('args: $args');
  print('args.length: ${args.length}');

  // 检查是否是子窗口
  // desktop_multi_window 的参数格式: ["multi_window", windowId, jsonArgs]
  if (args.isNotEmpty && args.first == 'multi_window') {
    print('检测到 desktop_multi_window 标识，启动子窗口');
    multi_window_entry.main(args);
    return;
  }

  print('启动主窗口');

  // 桌面平台窗口初始化
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      print('警告: window_manager 初始化失败: $e');
      print('应用将继续运行，但窗口管理功能可能不可用');
      // 继续运行应用，即使 window_manager 初始化失败
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider(),
      child: MaterialApp(
        title: 'Todo 应用',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/config': (context) => const ConfigPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 加载配置
      final configService = await ConfigService.getInstance();

      // 等待一下，显示启动画面
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      if (!configService.isConfigured) {
        // 未配置，跳转到配置页面
        Navigator.of(context).pushReplacementNamed('/config');
      } else {
        // 已配置，设置数据库路径并跳转到主页
        final dbPath = configService.databasePath;
        if (dbPath != null) {
          await DatabaseService.setDatabasePath(dbPath);
        }
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;

      // 显示错误
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('初始化失败'),
          content: Text('错误: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeApp(); // 重试
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Todo 应用',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
