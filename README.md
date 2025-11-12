# Flutter Todo 应用

一个功能完整的全平台 Todo 应用，使用 Flutter 开发。

## 功能特性

### 1. 工作板管理
- ✅ 创建多个工作板
- ✅ 任意排序工作板
- ✅ 为工作板设定不同的底色
- ✅ 添加和管理任务
- ✅ 工作板可以单独展示窗口（桌面平台，默认置顶）
- ✅ 单独展示时只可勾选任务完成
- ✅ 按时间排序按钮，将所有存在倒计时的未完成任务提至最前

### 2. 任务管理
- ✅ 任意拖动排序（可跨工作板）
- ✅ 未完成任务自动置顶
- ✅ 任务完成后排序自动变化至下面
- ✅ 可被标记为已完成（任务栏最前方有方框可勾选）
- ✅ 右键弹出管理菜单
  - 定时：设定一个时间（或倒计时），在任务栏后方添加倒计时显示
  - 超过时间后任务变红，倒计时变为已超时
  - 删除任务
  - 查看详情（首次完成时间、完成时间、创建时间）

### 3. 导出功能
- ✅ 通过创建时间/完成时间两个时间范围+工作板筛选任务
- ✅ 可勾选筛选出的任务
- ✅ 生成用于让 AI 生成工作报告的提示词
- ✅ 导出所有工作任务数据（工作板、任务）

### 4. 导入功能
- ✅ 导入之前导出的数据

### 5. 配置
- ✅ 使用 SQLite 进行数据管理
- ✅ 可配置数据库路径
- ✅ 默认使用本地生成的 SQLite
- ✅ 若无数据库配置，则进入配置页面

## 技术栈

- **Flutter**: 跨平台 UI 框架
- **Provider**: 状态管理
- **SQLite**: 本地数据库（sqflite + sqflite_common_ffi）
- **window_manager**: 桌面窗口管理
- **file_picker**: 文件选择
- **flutter_colorpicker**: 颜色选择器

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── models/                            # 数据模型
│   ├── board.dart                    # 工作板模型
│   └── task.dart                     # 任务模型
├── providers/                         # 状态管理
│   └── todo_provider.dart            # Todo Provider
├── services/                          # 服务层
│   ├── config_service.dart           # 配置服务
│   ├── database_service.dart         # 数据库服务
│   └── export_import_service.dart    # 导入导出服务
├── pages/                             # 页面
│   ├── config_page.dart              # 配置页面
│   ├── home_page.dart                # 主页面
│   ├── board_window_page.dart        # 工作板独立窗口
│   ├── export_page.dart              # 导出页面
│   └── import_page.dart              # 导入页面
└── widgets/                           # 组件
    ├── board_card.dart               # 工作板卡片
    ├── task_item.dart                # 任务项
    ├── add_board_dialog.dart         # 添加工作板对话框
    ├── add_task_dialog.dart          # 添加任务对话框
    ├── set_deadline_dialog.dart      # 设置倒计时对话框
    └── task_detail_dialog.dart       # 任务详情对话框
```

## 使用说明

### 首次启动
1. 应用首次启动会进入配置页面
2. 选择数据库保存位置（可使用默认路径）
3. 点击"测试并保存配置"

### 工作板管理
- 点击右下角 "+" 按钮创建新工作板
- 长按并拖动工作板可重新排序
- 点击工作板右上角菜单可以更改颜色、编辑名称或删除

### 任务管理
- 在工作板内点击"添加任务"按钮创建任务
- 勾选方框标记任务完成
- 右键点击任务（桌面）或长按任务（移动）打开菜单
- 可以设置倒计时、查看详情或删除任务
- 拖动任务可以重新排序或移动到其他工作板

### 倒计时功能
- 右键菜单选择"设置倒计时"
- 可以选择具体日期时间，或设置倒计时（天、小时、分钟）
- 有倒计时的任务会显示剩余时间
- 超时的任务会变红并显示"已超时"
- 点击工作板的时钟图标可按倒计时排序

### 导出导入
- 点击主页右上角导出图标进入导出页面
- 设置筛选条件，选择要导出的任务
- 可以生成 AI 提示词（复制到剪贴板）或导出 JSON 文件
- 点击导入图标可以导入之前导出的 JSON 文件

### 桌面平台特性
- 工作板可以单独打开新窗口（点击工作板标题栏的窗口图标）
- 单独窗口中只能勾选任务完成，不能进行其他操作

## 构建和运行

### 前置要求
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)

### 安装依赖
```bash
flutter pub get
```

### 运行应用

#### 桌面平台
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

#### 移动平台
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

### 构建发布版本
```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux

# Android
flutter build apk

# iOS
flutter build ios
```

## 数据库结构

### boards 表
- id: 主键
- name: 工作板名称
- color: 颜色值
- sort_order: 排序顺序
- created_at: 创建时间

### tasks 表
- id: 主键
- board_id: 所属工作板ID
- title: 任务内容
- is_completed: 是否完成
- sort_order: 排序顺序
- deadline: 截止时间（可选）
- created_at: 创建时间
- first_completed_at: 首次完成时间（可选）
- completed_at: 最近完成时间（可选）

## 许可证

MIT License
