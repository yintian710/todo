import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/todo_provider.dart';
import 'pages/board_floating_window.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== 子窗口启动 ===');
  print('args: $args');
  print('args.length: ${args.length}');

  // 初始化 sqflite_ffi for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 初始化窗口管理器
  try {
    await windowManager.ensureInitialized();
    print('子窗口 window_manager 初始化成功');
  } catch (e) {
    print('警告: 子窗口的 window_manager 初始化失败: $e');
  }

  // 从参数中获取工作板信息
  // desktop_multi_window 参数格式: ["multi_window", windowId, jsonArgs]
  final windowId = args.length > 1 ? int.tryParse(args[1].toString()) ?? 0 : 0;
  final arguments = args.length > 2 ? jsonDecode(args[2]) as Map<String, dynamic> : <String, dynamic>{};

  print('windowId: $windowId');
  print('arguments: $arguments');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()..loadData()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BoardFloatingWindow(arguments: arguments),
      ),
    ),
  );
}
