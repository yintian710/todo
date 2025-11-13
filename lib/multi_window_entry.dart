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

  // 初始化 sqflite_ffi for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 从参数中获取工作板信息
  final windowId = args.isNotEmpty ? int.tryParse(args.first) ?? 0 : 0;
  final arguments = args.length > 1 ? jsonDecode(args[1]) as Map<String, dynamic> : <String, dynamic>{};

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
