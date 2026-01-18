import { useEffect, useRef } from 'react'
import { useFrame, useThree, useLoader } from '@react-three/fiber'
import { GLTFLoader } from 'three-stdlib'
import * as THREE from 'three'
import { VRMLoaderPlugin, VRM } from '@pixiv/three-vrm'
import { VRMAnimationLoaderPlugin, createVRMAnimationClip } from '@pixiv/three-vrm-animation'

interface AvatarProps {
  mouseRef: React.MutableRefObject<{ x: number; y: number }>
  mode: 'head' | 'body'
}

export function Avatar({ mouseRef, mode }: AvatarProps) {
  const { scene } = useThree() // 移除了 camera，因为它现在由 CameraRig 接管
  const vrmRef = useRef<VRM | null>(null)
  const mixerRef = useRef<THREE.AnimationMixer | null>(null)
  
  // === 状态 Refs ===
  const currentYaw = useRef(0)
  const currentPitch = useRef(0)
  // 眼球追踪的目标物体
  const lookAtTargetRef = useRef<THREE.Object3D>(new THREE.Object3D())

  // 1. 加载资源
  const gltf = useLoader(GLTFLoader, './avatar.vrm', (loader) => {
    (loader as any).register((parser: any) => new VRMLoaderPlugin(parser))
  })
  const { userData } = gltf
  const vrmScene = gltf.scene
  
  const gltfAnim = useLoader(GLTFLoader, './idle.vrma', (loader) => {
    (loader as any).register((parser: any) => new VRMAnimationLoaderPlugin(parser))
  })
  const { userData: animUserData } = gltfAnim

  // 2. 初始化逻辑
  useEffect(() => {
    const vrm = userData.vrm as VRM
    if (!vrm) return
    vrmRef.current = vrm

    // (A) 模型初始化
    vrm.scene.rotation.y = Math.PI // 转身面向镜头
    
    // (B) 设置眼球追踪目标
    scene.add(lookAtTargetRef.current)
    if (vrm.lookAt) {
        vrm.lookAt.target = lookAtTargetRef.current
    }

    // (C) 播放动画
    if (animUserData.vrmAnimations && animUserData.vrmAnimations[0]) {
      const mixer = new THREE.AnimationMixer(vrm.scene)
      const clip = createVRMAnimationClip(animUserData.vrmAnimations[0], vrm)
      mixer.clipAction(clip).play()
      mixerRef.current = mixer
    }

    return () => {
        scene.remove(lookAtTargetRef.current)
    }
  }, [userData, animUserData, scene])

  // 3. 核心渲染循环
  // [修复] 将 state 改为 _，避免 TS 报错未使用
  useFrame((_, delta) => {
    const vrm = vrmRef.current
    if (!vrm) return

    // A. 更新基础动画
    if (mixerRef.current) mixerRef.current.update(delta)
    vrm.update(delta)

    // B. 鼠标跟随计算
    const { x: mouseX, y: mouseY } = mouseRef.current
    const isClosedMode = (mode === 'head')
    
    const trackingIntensity = isClosedMode ? 0.25 : 1.0
    const sensitivity = 0.002
    const maxYaw = THREE.MathUtils.degToRad(50)
    const maxPitch = THREE.MathUtils.degToRad(30)

    const targetYaw = THREE.MathUtils.clamp(
      mouseX * sensitivity * trackingIntensity,
      -maxYaw * trackingIntensity,
      maxYaw * trackingIntensity
    )
    const targetPitch = THREE.MathUtils.clamp(
      mouseY * sensitivity * trackingIntensity,
      -maxPitch * trackingIntensity,
      maxPitch * trackingIntensity
    )

    currentYaw.current = THREE.MathUtils.lerp(currentYaw.current, targetYaw, 0.1)
    currentPitch.current = THREE.MathUtils.lerp(currentPitch.current, targetPitch, 0.1)

    // C. 驱动骨骼旋转
    const head = vrm.humanoid.getRawBoneNode('head')
    const neck = vrm.humanoid.getRawBoneNode('neck')
    const spine = vrm.humanoid.getRawBoneNode('upperChest') || vrm.humanoid.getRawBoneNode('chest')

    if (spine) {
        spine.rotation.y += currentYaw.current * 0.2
        spine.rotation.x += currentPitch.current * 0.2
    }
    if (neck) {
        neck.rotation.y += currentYaw.current * 0.3
        neck.rotation.x += currentPitch.current * 0.3
    }
    if (head) {
        head.rotation.y += currentYaw.current * 0.5
        head.rotation.x += currentPitch.current * 0.5
    }

    // E. 眼球追踪
    if (lookAtTargetRef.current && head) {
        // 强制更新矩阵以获取准确位置
        vrm.scene.updateMatrixWorld()
        const headPos = head.getWorldPosition(new THREE.Vector3())
        
        lookAtTargetRef.current.position.set(
            headPos.x + Math.sin(currentYaw.current),
            headPos.y + Math.tan(currentPitch.current),
            headPos.z + Math.cos(currentYaw.current)
        )
    }
  })

  return <primitive object={vrmScene} />
}
