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
    // [新增]
    headNodeRef?: React.MutableRefObject<THREE.Object3D | null>
  }

export const CameraRig = forwardRef(({ mode, debug = false, headNodeRef }: CameraRigProps, ref) => {
  const { camera } = useThree()
  const [config, setConfig] = useState<CameraConfig | null>(null)
  
  const targetPos = useRef(new THREE.Vector3(0, 1.4, 0.6))
  const ZHTargetLookAt = useRef(new THREE.Vector3(0, 1.4, 0)) // 原变量名 targetLookAt
  const currentLookAt = useRef(new THREE.Vector3(0, 1.4, 0))
  const controlsRef = useRef<any>(null)

  useImperativeHandle(ref, () => controlsRef.current)

  useEffect(() => {
    fetch('./camera.json')
      .then((res) => res.json())
      .then((data) => {
        setConfig(data)
        const setting = mode === 'head' ? data.head : data.body
        if (debug && camera instanceof THREE.PerspectiveCamera) {
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
  }, [debug]) 

  // 当模式切换或配置加载时，设置一个初始的“静态”目标，防止在 HeadNode 还没准备好时相机乱飞
  useEffect(() => {
    if (!config || debug) return 

    const setting = mode === 'head' ? config.head : config.body
    
    // 只有当不是 Head 模式或者 HeadNode 还没准备好时，才使用静态配置
    // 如果是 Head 模式，useFrame 会接管
    if (mode !== 'head' || !headNodeRef?.current) {
        targetPos.current.set(setting.position.x, setting.position.y, setting.position.z)
        ZHTargetLookAt.current.set(setting.target.x, setting.target.y, setting.target.z)
    }
    
    if (camera instanceof THREE.PerspectiveCamera) {
        camera.fov = setting.fov
        camera.updateProjectionMatrix()
    }
  }, [mode, config, camera, debug, headNodeRef])

  useFrame((state) => {
    if (debug) return 

    // [新增] Head 模式下的动态追踪逻辑
    if (mode === 'head' && headNodeRef?.current) {
        const headPos = headNodeRef.current.getWorldPosition(new THREE.Vector3())
        
        // 参考代码的逻辑:
        // targetLookAt.set(headPos.x, headPos.y + 0.05, headPos.z);
        // targetCamPos.set(headPos.x, headPos.y + 0.05, headPos.z + 0.55);
        
        ZHTargetLookAt.current.set(headPos.x, headPos.y + 0.05, headPos.z)
        targetPos.current.set(headPos.x, headPos.y + 0.05, headPos.z + 0.55)
    }

    const speed = config?.lerpSpeed || 0.05
    state.camera.position.lerp(targetPos.current, speed)
    currentLookAt.current.lerp(ZHTargetLookAt.current, speed)
    state.camera.lookAt(currentLookAt.current)
  })

  if (debug) {
    return (
        <>
            <OrbitControls ref={controlsRef} makeDefault />
            <mesh position={currentLookAt.current} scale={0.05} visible={false}>
                <sphereGeometry />
                <meshBasicMaterial color="hotpink" wireframe />
            </mesh>
        </>
    )
  }

  return null
})
