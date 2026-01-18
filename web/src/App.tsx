import { Suspense, useState, useRef, useMemo } from 'react'
import { Canvas } from '@react-three/fiber'
import { Avatar } from './components/Avatar'
import { CameraRig } from './components/CameraRig'
import { CameraConfigurator } from './components/CameraConfigurator'
import { ScissorDirector } from './components/ScissorDirector'
import { useNativeBridge } from './hooks/useBridge'
import { DEFAULT_CONFIG } from './utils/layout'
import type { ViewportConfig } from './utils/layout'
import * as THREE from 'three'

function Loader() {
  return (
    <mesh>
      <boxGeometry args={[0.5, 0.5, 0.5]} />
      <meshStandardMaterial color="red" wireframe />
    </mesh>
  )
}

function App() {
  // 1. 获取 Swift 传来的状态
  const { mouseRef, cameraMode: nativeMode, windowSize: swiftSize } = useNativeBridge()
  
  const IS_DEBUG_MODE = false
  
  const [debugMode, setDebugMode] = useState<'head' | 'body'>('head')
  const activeMode = IS_DEBUG_MODE ? debugMode : nativeMode

  // 2. 本地 override 配置 (允许用户在 Configurator 里手动改尺寸)
  const [manualOverride, setManualOverride] = useState<Partial<ViewportConfig>>({})

  // 3. 计算最终生效的 Viewport Config
  const activeConfig = useMemo(() => {
      // 优先级：手动输入 > Swift 实时数据 > 默认写死数据
      
      const base = DEFAULT_CONFIG[activeMode]
      
      // 如果 Swift 传来了数据，且我们在对应的模式下 (简单的启发式判断)
      // 注意：Swift 传来的只是 w/h，不知道是 head 还是 body，需要配合 nativeMode 判断
      // 但在 Debug 模式下，如果我们强制切到了 head，而 Swift 处于 body，可能会尺寸不匹配。
      // 所以策略是：
      // 如果 swiftSize 存在，且看起来合理（比如 head 模式下 < 100px），则自动采纳
      
      let dynamicWidth = base.width
      let dynamicHeight = base.height
      
      // 只有当 nativeMode 和 debugMode 一致时，才信任 Swift 的尺寸
      // 或者你可以选择总是信任 Swift 尺寸（如果你总是在 Swift App 里调试当前模式）
      if (swiftSize && swiftSize.width > 0) {
          // 这里可以加更复杂的逻辑，比如只在 nativeMode == activeMode 时应用
          dynamicWidth = swiftSize.width
          dynamicHeight = swiftSize.height
      }

      return {
          ...base,
          width: manualOverride.width ?? dynamicWidth,
          height: manualOverride.height ?? dynamicHeight,
          // 如果手动改了配置，名字加个 *
          name: (swiftSize ? "[Swift Sync] " : "[Manual] ") + base.name
      }
  }, [activeMode, swiftSize, manualOverride])

  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null)
  const orbitRef = useRef<any>(null)

  return (
    <div style={{ width: '100vw', height: '100vh', background: IS_DEBUG_MODE ? '#111' : 'transparent' }}>
      
      {IS_DEBUG_MODE && (
        <CameraConfigurator 
            currentMode={activeMode} 
            currentConfig={activeConfig} // 传入计算好的配置
            onConfigChange={(newConf) => setManualOverride(prev => ({...prev, ...newConf}))}
            onModeChange={setDebugMode}
            cameraRef={cameraRef}
            orbitRef={orbitRef}
        />
      )}

      <Canvas
        onCreated={({ camera }) => {
            cameraRef.current = camera as THREE.PerspectiveCamera
        }}
        gl={{ alpha: true, antialias: true }}
      >
        {/* 剪裁器使用动态配置 */}
        <ScissorDirector config={activeConfig} active={IS_DEBUG_MODE} />

        <directionalLight position={[1, 1, 1]} intensity={1.2} />
        <ambientLight intensity={0.8} />

        <Suspense fallback={<Loader />}>
          <Avatar mouseRef={mouseRef} mode={activeMode} />
          <CameraRig ref={orbitRef} mode={activeMode} debug={IS_DEBUG_MODE} />
        </Suspense>
      </Canvas>
    </div>
  )
}

export default App
