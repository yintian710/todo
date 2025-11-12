import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'providers/todo_provider.dart';
import 'services/database_service.dart';
import 'pages/board_floating_window.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 sqflite_ffi for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 从参数中获取工作板信息
  final windowId = int.parse(args.first);
  final arguments = args.length > 1 ? jsonDecode(args[1]) : <String, dynamic>{};

  // 初始化数据库
  await DatabaseService.instance.initialize();

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
