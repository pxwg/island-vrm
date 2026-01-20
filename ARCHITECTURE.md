# Interactive Configuration System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      IslandVRM App                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐         ┌──────────────────┐        │
│  │   SettingsView   │         │   NotchWindow    │        │
│  │                  │         │                  │        │
│  │  - Head Config   │         │  - NotchView     │        │
│  │  - Body Config   │         │  - VRMWebView    │        │
│  │  - Sliders       │         │  - Avatar        │        │
│  └────────┬─────────┘         └────────┬─────────┘        │
│           │                            │                   │
│           │    ┌──────────────────┐   │                   │
│           └───>│   globalVM       │<──┘                   │
│                │ (NotchViewModel) │                       │
│                └──────────────────┘                       │
│                         │                                  │
│                         v                                  │
│                ┌──────────────────┐                       │
│                │ overrideState    │                       │
│                │ (Force Expanded/ │                       │
│                │  Closed)         │                       │
│                └──────────────────┘                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

```
User Action (Settings)
    │
    v
┌─────────────────────┐
│ CameraConfigStore   │
│ - config: Published │
│ - save()            │
│ - sendToWeb()       │
└──────┬──────────────┘
       │
       │ (didSet)
       v
┌─────────────────────┐
│   UserDefaults      │ ← Persistent Storage
└─────────────────────┘

       │
       │ (simultaneously)
       v
┌─────────────────────┐
│ SharedWebViewHelper │
│ .updateCameraConfig │
└──────┬──────────────┘
       │
       │ (JavaScript Bridge)
       v
┌─────────────────────────────┐
│ window.updateCameraConfig() │ ← Web Side
└──────┬──────────────────────┘
       │
       v
┌─────────────────────┐
│ useBridge Hook      │
│ - cameraConfig      │
│ (React State)       │
└──────┬──────────────┘
       │
       v
┌─────────────────────┐
│    CameraRig        │
│ - config prop       │
│ - Updates camera    │
└─────────────────────┘
```

## Component Relationships

### Swift Side

```
IslandApp.swift
    │
    ├─> globalVM (NotchViewModel) ─┐
    │                               │
    └─> Settings                    │
         │                          │
         └─> SettingsView ──────────┘
              │
              └─> CameraConfigStore.shared
                   │
                   ├─> save() → UserDefaults
                   └─> sendToWeb() → SharedWebViewHelper
```

### React Side

```
App.tsx
    │
    └─> useNativeBridge()
         │
         ├─> cameraMode
         ├─> windowSize
         ├─> agentState
         ├─> performance
         └─> cameraConfig ──┐
                            │
                            v
                        CameraRig
                            │
                            └─> Updates THREE.Camera
```

## State Management

### NotchViewModel States

```
┌──────────────────────────────────────┐
│        NotchViewModel                │
├──────────────────────────────────────┤
│  state: .closed | .expanded          │
│  overrideState: nil | .closed | .exp │
│                                      │
│  effectiveState = overrideState ?? state
└──────────────────────────────────────┘

Normal Mode:
  overrideState = nil
  → state controls appearance

Settings Mode:
  overrideState = .closed (Head tab)
  overrideState = .expanded (Body tab)
  → overrideState forces appearance
  → Hover/Auto-collapse disabled
```

## Configuration Structure

```typescript
interface CameraConfig {
  head: {
    position: { x, y, z }
    target: { x, y, z }
    fov: number
  }
  body: {
    position: { x, y, z }
    target: { x, y, z }
    fov: number
  }
  lerpSpeed: number
}
```

## Lifecycle

### App Startup
```
1. AppDelegate.applicationDidFinishLaunching
2. Create globalVM (NotchViewModel)
3. Create NotchWindow with globalVM
4. Load VRMWebView
5. WebView didFinish → Send initial config
6. React app receives config
7. CameraRig applies config
```

### Settings Flow
```
1. User opens Settings (Cmd+,)
2. SettingsView appears
3. onAppear → updateOverrideState()
4. Switch tabs → onChange → updateOverrideState()
   - Head tab → vm.overrideState = .closed
   - Body tab → vm.overrideState = .expanded
5. Slider adjusted → CameraConfigStore updates
6. Config sent to WebView immediately
7. React receives and applies
8. User closes Settings
9. onDisappear → vm.overrideState = nil
```

## Key Features

### Real-time Preview
- Configuration changes immediately reflected in 3D view
- No need to restart app or reload page

### Automatic State Switching
- Head tab → Island closes (better view of head)
- Body tab → Island expands (better view of body)

### Persistent Storage
- UserDefaults saves configuration
- Auto-load on next launch
- Reset to defaults option

### Type Safety
- Shared data structures between Swift and TypeScript
- Codable on Swift side
- TypeScript interfaces on React side
