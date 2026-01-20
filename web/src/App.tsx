import { useRef, useMemo } from 'react'
import { Canvas } from '@react-three/fiber'
import { Avatar } from './components/Avatar'
import { CameraRig } from './components/CameraRig'
import { ScissorDirector } from './components/ScissorDirector'
import { useNativeBridge } from './hooks/useBridge'
import { DEFAULT_CONFIG } from './utils/layout'
import * as THREE from 'three'

function App() {
  // [修改] 解构出 cameraConfig
  const { mouseRef, cameraMode: nativeMode, windowSize: swiftSize, agentState, performance, cameraConfig } = useNativeBridge()
  
  // 生产环境不再需要 Web 端的 debugMode，全部由 Native 驱动
  // 如果尚未收到 Native 配置，cameraConfig 为 null，Rig 会等待
  
  const activeConfig = useMemo(() => {
      const base = DEFAULT_CONFIG[nativeMode]
      let dynamicWidth = base.width
      let dynamicHeight = base.height
      
      if (swiftSize && swiftSize.width > 0) {
          dynamicWidth = swiftSize.width
          dynamicHeight = swiftSize.height
      }

      return {
          ...base,
          width: dynamicWidth,
          height: dynamicHeight,
          name: swiftSize ? "[Swift Sync] " + base.name : base.name
      }
  }, [nativeMode, swiftSize])

  const headNodeRef = useRef<THREE.Object3D | null>(null)

  return (
    <div style={{ width: '100vw', height: '100vh', background: 'transparent' }}>
      <Canvas
        gl={{ alpha: true, antialias: true }}
      >
        <ScissorDirector config={activeConfig} active={true} />

        <directionalLight position={[1, 1, 1]} intensity={1.2} />
        <ambientLight intensity={0.8} />

        <Avatar 
            mouseRef={mouseRef} 
            mode={nativeMode} 
            headNodeRef={headNodeRef} 
            agentState={agentState} 
            performance={performance}
        />
        {/* [修改] 传入 cameraConfig */}
        <CameraRig mode={nativeMode} config={cameraConfig} headNodeRef={headNodeRef} />
      </Canvas>
    </div>
  )
}

export default App
