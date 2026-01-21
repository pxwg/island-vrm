# Native First Configuration System

## Overview

This implementation transforms the island-vrm-test project from a developer-focused hardcoded configuration system to a user-friendly native macOS experience.

## Key Features

### 1. Zero-Code Entry (零代码门槛)
Users can now configure the camera without touching code:
- **Keyboard Shortcut**: Press `Cmd + ,` to open preferences
- **Menu Bar**: Click the menu bar icon → "Preferences..."
- All settings are immediately editable through native macOS UI

### 2. Native Persistence (原生数据持久化)
Camera configurations are stored in macOS UserDefaults:
- Settings persist across app restarts
- No manual "Save" button needed - changes are auto-saved
- Gracefully falls back to camera.json if UserDefaults is empty

### 3. Real-Time Feedback (毫秒级实时反馈)
Swift ↔ WebGL high-speed IPC bridge:
- Every slider adjustment instantly reflects in the VRM model
- No page refresh required
- Smooth camera transitions with configurable lerp speed

### 4. God Mode (上帝视角)
Context-aware Dynamic Island behavior:
- When **Body Mode** tab is selected in settings:
  - Dynamic Island automatically expands
  - Stays locked (no auto-collapse)
  - Mouse hover events are ignored
- When settings panel closes or switches to Head Mode:
  - Returns to normal "civilian mode"
  - Auto-collapse and hover behavior resume

## Architecture

### Swift Layer
- `CameraSettings.swift`: Singleton managing UserDefaults persistence
- `SettingsView.swift`: SwiftUI settings panel with Head/Body tabs
- `NotchViewModel.swift`: Enhanced with God Mode state management
- `VRMWebView.swift`: Injects config on page load, updates in real-time

### Web Layer
- `useBridge.tsx`: Extended with camera config state
- `CameraRig.tsx`: Listens for native config updates
- Real-time updates via `window.updateCameraConfig()`

## Data Flow

```
User adjusts slider in SettingsView
    ↓
CameraSettings.shared.save() → UserDefaults
    ↓
SharedWebViewHelper.shared.updateCameraConfig()
    ↓
JavaScript window.updateCameraConfig() called
    ↓
React state update in useBridge
    ↓
CameraRig re-renders with new config
    ↓
THREE.js camera updates position/target/FOV
```

## Usage

### Opening Settings
```swift
// Automatically handled by IslandVRMApp
// User presses Cmd+, or clicks menu
```

### Accessing Settings Programmatically
```swift
// Get current configuration
let config = CameraSettings.shared.config

// Update Head mode position
CameraSettings.shared.updateHead(
    position: CameraPosition(x: 0.1, y: 1.5, z: 2.0)
)

// Reset to defaults
CameraSettings.shared.reset()
```

### God Mode Control
```swift
// In NotchViewModel
viewModel.enterGodMode()  // Force expand, lock island
viewModel.exitGodMode()   // Return to normal behavior
```

## Configuration Structure

```json
{
  "head": {
    "position": { "x": 0.05, "y": 1.45, "z": 2.15 },
    "target": { "x": 0.05, "y": 1.45, "z": 0 },
    "fov": 40
  },
  "body": {
    "position": { "x": 0, "y": 1.4, "z": 0.6 },
    "target": { "x": 0, "y": 1.4, "z": 0 },
    "fov": 40
  },
  "lerpSpeed": 0.05
}
```

## Migration Notes

- **Backward Compatible**: Falls back to `camera.json` if UserDefaults is empty
- **First Launch**: Initializes UserDefaults with default values
- **Debug Mode**: Still works independently for developers

## Future Enhancements

- [ ] Export/Import settings presets
- [ ] Per-model configuration profiles
- [ ] Animation curve editor for camera transitions
- [ ] Visual preview in settings panel
