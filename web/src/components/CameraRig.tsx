import { useEffect, useRef, forwardRef, useImperativeHandle } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import * as THREE from 'three'
import type { CameraConfig } from '../hooks/useBridge'

interface CameraRigProps {
    mode: 'head' | 'body'
    debug?: boolean
    headNodeRef?: React.MutableRefObject<THREE.Object3D | null>
    // [新增] 接收外部配置
    config: CameraConfig | null
}

export const CameraRig = forwardRef(({ mode, debug = false, headNodeRef, config }: CameraRigProps, ref) => {
  const { camera } = useThree()
  
  const targetPos = useRef(new THREE.Vector3(0, 1.4, 0.6))
  const ZHTargetLookAt = useRef(new THREE.Vector3(0, 1.4, 0)) 
  const currentLookAt = useRef(new THREE.Vector3(0, 1.4, 0))
  const controlsRef = useRef<any>(null)

  const VISUAL_OFFSET_X = 0.05

  useImperativeHandle(ref, () => controlsRef.current)

  // [修改] 响应 config 变化，不再 fetch json
  useEffect(() => {
    if (!config || debug) return 

    const setting = mode === 'head' ? config.head : config.body
    
    // 初始化相机位置（当骨骼未加载或非动态追踪状态时使用）
    if (mode !== 'head' || !headNodeRef?.current) {
        const rawPos = new THREE.Vector3(setting.position.x, setting.position.y, setting.position.z)
        const rawTarget = new THREE.Vector3(setting.target.x, setting.target.y, setting.target.z)

        if (mode === 'head') {
            rawPos.x += VISUAL_OFFSET_X
            rawTarget.x += VISUAL_OFFSET_X
        }

        targetPos.current.copy(rawPos)
        ZHTargetLookAt.current.copy(rawTarget)
    }
    
    if (camera instanceof THREE.PerspectiveCamera) {
        camera.fov = setting.fov
        camera.updateProjectionMatrix()
    }
  }, [mode, config, camera, debug, headNodeRef])

  useFrame((state) => {
    if (debug) return 

    if (mode === 'head' && headNodeRef?.current) {
        const headPos = headNodeRef.current.getWorldPosition(new THREE.Vector3())
        const offsetX = headPos.x + VISUAL_OFFSET_X
        ZHTargetLookAt.current.set(offsetX, headPos.y + 0.05, headPos.z)
        targetPos.current.set(offsetX, headPos.y + 0.05, headPos.z + 0.55)
    }

    const speed = config?.lerpSpeed || 0.05
    state.camera.position.lerp(targetPos.current, speed)
    currentLookAt.current.lerp(ZHTargetLookAt.current, speed)
    state.camera.lookAt(currentLookAt.current)
  })

  // 移除了 Debug 模式下的 OrbitControls 和 helper，因为现在要在 Native 端配置
  return null
})
