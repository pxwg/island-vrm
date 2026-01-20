# Interactive Configuration System Guide

## 概述

本项目已从静态 camera.json 配置迁移到交互式配置系统。配置现在由 Native Swift 应用管理，并通过 bridge 实时发送到 Web 端。

## 主要变化

### Web 前端 (React)
- ✅ 移除了对 `camera.json` 的 fetch 请求
- ✅ 通过 `window.updateCameraConfig()` 接收 Native 端的配置
- ✅ CameraRig 组件现在接收 config 作为 props
- ✅ 配置通过 `useBridge` hook 管理

### Native 后端 (Swift)
- ✅ `CameraConfigStore` - 配置数据管理，使用 UserDefaults 持久化
- ✅ `SettingsView` - 可视化配置面板
- ✅ `NotchViewModel.overrideState` - 支持配置模式下的强制状态
- ✅ 全局 ViewModel 实例，在 App 和 Settings 间共享

## 使用方法

### 1. 构建项目

```bash
./build.sh
```

### 2. 打开设置面板

运行 `IslandVRM.app` 后：
- 按 `Cmd + ,` (macOS 标准快捷键)
- 或点击菜单栏 `IslandVRM -> Settings...`

### 3. 配置相机

设置面板有两个标签页：
- **Head Mode** - 配置头部模式的相机参数
- **Body Mode** - 配置身体模式的相机参数

每个模式可以调整：
- **Position** (x, y, z) - 相机位置
- **Target** (x, y, z) - 观察目标点
- **FOV** - 视野角度

### 4. 实时预览

- 切换到 **Body Mode** 标签时，灵动岛会自动展开，方便查看身体位置
- 切换到 **Head Mode** 标签时，灵动岛会自动收起，方便查看头部位置
- 拖动滑块时，模型会实时移动

### 5. 保存配置

配置会自动保存到 UserDefaults，下次启动时自动加载。

### 6. 重置为默认值

点击 "Reset to Defaults" 按钮恢复默认配置。

## 默认配置值

```swift
Head Mode:
- Position: (0, 1.4, 0.6)
- Target: (0, 1.4, 0)
- FOV: 40°

Body Mode:
- Position: (0, 1.25, 1.3)
- Target: (0, 1.15, 0)
- FOV: 35°

Lerp Speed: 0.05
```

## 技术细节

### 数据流

1. 用户在 SettingsView 中调整滑块
2. CameraConfigStore 更新并保存配置
3. 配置通过 `updateCameraConfig()` 发送到 WebView
4. Web 端的 useBridge hook 接收并更新 state
5. CameraRig 使用新配置更新相机位置

### 文件结构

```
Core/
├── CameraConfigStore.swift  # 配置数据模型和持久化
├── SettingsView.swift       # 设置 UI 界面
├── NotchViewModel.swift     # 增加了 overrideState 支持
├── VRMWebView.swift        # 增加了 updateCameraConfig 方法
└── NotchWindow.swift       # 使用全局 ViewModel

web/src/
├── hooks/useBridge.tsx      # 增加了 CameraConfig 类型和监听
├── components/CameraRig.tsx # 接收 config props，移除 fetch
└── App.tsx                  # 传递 cameraConfig 给 CameraRig
```

## 故障排除

### 配置未生效
- 确保 Web 端已构建：`cd web && npm run build`
- 检查 WebResources 目录是否包含最新的构建文件
- 重启 IslandVRM.app

### 设置窗口无法打开
- 确保使用的是最新构建的应用
- 检查 Console.app 中的错误日志

### 模型位置不正确
- 尝试点击 "Reset to Defaults" 恢复默认值
- 调整 Position 和 Target 的 x, y, z 值
- FOV 值建议保持在 30-50 度之间
