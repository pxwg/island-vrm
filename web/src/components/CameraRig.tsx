import { useEffect, useRef, useState, forwardRef, useImperativeHandle } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'
import { OrbitControls } from '@react-three/drei'

interface CameraSetting {
    position: { x: number; y: number; z: number }
    target: { x: number; y: number; z: number }
    fov: number
  }
  
  interface CameraConfig {
    head: CameraSetting
    body: CameraSetting
    lerpSpeed: number
  }
  
  interface CameraRigProps {
    mode: 'head' | 'body'
    debug?: boolean
  }

// 使用 forwardRef 暴露 OrbitControls
export const CameraRig = forwardRef(({ mode, debug = false }: CameraRigProps, ref) => {
  const { camera } = useThree()
  const [config, setConfig] = useState<CameraConfig | null>(null)
  
  const targetPos = useRef(new THREE.Vector3(0, 1.4, 0.6))
  const targetLookAt = useRef(new THREE.Vector3(0, 1.4, 0))
  const currentLookAt = useRef(new THREE.Vector3(0, 1.4, 0))
  const controlsRef = useRef<any>(null)

  // 暴露 controls 给父组件
  useImperativeHandle(ref, () => controlsRef.current)

  // 1. 加载配置 (仅在非 debug 模式或初始加载时有用)
  useEffect(() => {
    fetch('./camera.json')
      .then((res) => res.json())
      .then((data) => {
        setConfig(data)
        // 初始加载时应用一次配置
        const setting = mode === 'head' ? data.head : data.body
        if (debug && camera instanceof THREE.PerspectiveCamera) {
             // Debug 模式下，初始化位置，但不锁定 update
             camera.position.set(setting.position.x, setting.position.y, setting.position.z)
             camera.fov = setting.fov
             camera.updateProjectionMatrix()
             if (controlsRef.current) {
                 controlsRef.current.target.set(setting.target.x, setting.target.y, setting.target.z)
                 controlsRef.current.update()
             }
        }
      })
      .catch(console.error)
  }, [debug]) // 依赖项改少一点

  // 2. 运行模式 (非 Debug)：自动平滑运镜
  useEffect(() => {
    if (!config || debug) return // Debug 模式下不自动覆盖目标

    const setting = mode === 'head' ? config.head : config.body
    targetPos.current.set(setting.position.x, setting.position.y, setting.position.z)
    targetLookAt.current.set(setting.target.x, setting.target.y, setting.target.z)
    
    if (camera instanceof THREE.PerspectiveCamera) {
        camera.fov = setting.fov
        camera.updateProjectionMatrix()
    }
  }, [mode, config, camera, debug])

  useFrame((state) => {
    if (debug) return // Debug 模式下完全停止自动运镜

    const speed = config?.lerpSpeed || 0.05
    state.camera.position.lerp(targetPos.current, speed)
    currentLookAt.current.lerp(targetLookAt.current, speed)
    state.camera.lookAt(currentLookAt.current)
  })

  // 3. Debug 模式：启用 OrbitControls
  if (debug) {
    return (
        <>
            <OrbitControls ref={controlsRef} makeDefault />
            {/* 视觉辅助球：当前注视点 */}
            <mesh position={currentLookAt.current} scale={0.05} visible={false}>
                <sphereGeometry />
                <meshBasicMaterial color="hotpink" wireframe />
            </mesh>
        </>
    )
  }

  return null
})
