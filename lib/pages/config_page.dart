import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/config_service.dart';
import '../services/database_service.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  String? _databasePath;
  bool _isLoading = false;
  String? _error;
  bool _useLocalDatabase = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    if (_useLocalDatabase) {
      final defaultPath = await DatabaseService.getDefaultDatabasePath();
      if (mounted) {
        setState(() {
          _databasePath = defaultPath;
        });
      }
    }
  }

  Future<void> _selectDatabaseFile() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择数据库保存位置',
        fileName: 'todo.db',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null) {
        setState(() {
          _databasePath = result;
        });
      }
    } catch (e) {
      setState(() {
        _error = '选择文件失败: $e';
      });
    }
  }

  Future<void> _selectDatabaseFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择数据库保存文件夹',
      );

      if (result != null) {
        setState(() {
          _databasePath = '$result${Platform.pathSeparator}todo.db';
        });
      }
    } catch (e) {
      setState(() {
        _error = '选择文件夹失败: $e';
      });
    }
  }

  Future<void> _testAndSaveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 测试数据库连接
      final dbService = DatabaseService.instance;
      final success = await dbService.testConnection(_databasePath!);

      if (!success) {
        setState(() {
          _error = '无法连接到数据库，请检查路径是否正确';
          _isLoading = false;
        });
        return;
      }

      // 保存配置
      final configService = await ConfigService.getInstance();
      await configService.setDatabasePath(_databasePath!);
      await DatabaseService.setDatabasePath(_databasePath!);

      if (mounted) {
        // 跳转到主页
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _error = '配置失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库配置'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.storage,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  '配置数据库',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '请选择数据库文件的保存位置。默认使用本地 SQLite 数据库。',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SwitchListTile(
                  title: const Text('使用本地数据库'),
                  subtitle: const Text('存储在本地文件系统'),
                  value: _useLocalDatabase,
                  onChanged: (value) {
                    setState(() {
                      _useLocalDatabase = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_useLocalDatabase) ...[
                  TextFormField(
                    initialValue: _databasePath,
                    decoration: const InputDecoration(
                      labelText: '数据库路径',
                      hintText: '选择数据库文件保存位置',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择数据库路径';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _databasePath = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectDatabaseFolder,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('选择文件夹'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadDefaultPath,
                          icon: const Icon(Icons.refresh),
                          label: const Text('使用默认路径'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_error != null) const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAndSaveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '测试并保存配置',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
