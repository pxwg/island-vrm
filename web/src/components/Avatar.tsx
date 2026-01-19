import { useEffect, useRef } from 'react'
import { useFrame, useThree, useLoader } from '@react-three/fiber'
import {GLTFLoader} from 'three-stdlib'
import * as THREE from 'three'
import { VRMLoaderPlugin, VRM } from '@pixiv/three-vrm'
import { VRMAnimationLoaderPlugin, createVRMAnimationClip } from '@pixiv/three-vrm-animation'

interface AvatarProps {
  mouseRef: React.MutableRefObject<{ x: number; y: number }>
  mode: 'head' | 'body'
  // [新增]
  headNodeRef?: React.MutableRefObject<THREE.Object3D | null>
}

export function Avatar({ mouseRef, mode, headNodeRef }: AvatarProps) {
  const { scene } = useThree()
  const vrmRef = useRef<VRM | null>(null)
  const mixerRef = useRef<THREE.AnimationMixer | null>(null)
  
  const currentYaw = useRef(0)
  const currentPitch = useRef(0)
  const lookAtTargetRef = useRef<THREE.Object3D>(new THREE.Object3D())

  const gltf = useLoader(GLTFLoader, './avatar.vrm', (loader) => {
    (loader as any).register((parser: any) => new VRMLoaderPlugin(parser))
  })
  const { userData } = gltf
  const vrmScene = gltf.scene
  
  const gltfAnim = useLoader(GLTFLoader, './idle.vrma', (loader) => {
    (loader as any).register((parser: any) => new VRMAnimationLoaderPlugin(parser))
  })
  const { userData: animUserData } = gltfAnim

  useEffect(() => {
    const vrm = userData.vrm as VRM
    if (!vrm) return
    vrmRef.current = vrm

    vrm.scene.rotation.y = Math.PI

    // [新增] 保存头部节点引用供 CameraRig 使用
    if (headNodeRef) {
        const head = vrm.humanoid.getRawBoneNode('head')
        if (head) headNodeRef.current = head
    }
    
    scene.add(lookAtTargetRef.current)
    if (vrm.lookAt) {
        vrm.lookAt.target = lookAtTargetRef.current
    }

    if (animUserData.vrmAnimations && animUserData.vrmAnimations[0]) {
      const mixer = new THREE.AnimationMixer(vrm.scene)
      const clip = createVRMAnimationClip(animUserData.vrmAnimations[0], vrm)
      mixer.clipAction(clip).play()
      mixerRef.current = mixer
    }

    return () => {
        scene.remove(lookAtTargetRef.current)
    }
  }, [userData, animUserData, scene, headNodeRef])

  useFrame((_, delta) => {
    const vrm = vrmRef.current
    if (!vrm) return

    if (mixerRef.current) mixerRef.current.update(delta)
    vrm.update(delta)

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

    const head = vrm.humanoid.getRawBoneNode('head')
    const ZYNeck = vrm.humanoid.getRawBoneNode('neck')
    const spine = vrm.humanoid.getRawBoneNode('upperChest') || vrm.humanoid.getRawBoneNode('chest')

    if (spine) {
        spine.rotation.y += currentYaw.current * 0.2
        spine.rotation.x += currentPitch.current * 0.2
    }
    if (ZYNeck) { // 这里原代码变量名可能是 neck
        ZYNeck.rotation.y += currentYaw.current * 0.3
        ZYNeck.rotation.x += currentPitch.current * 0.3
    }
    if (head) {
        head.rotation.y += currentYaw.current * 0.5
        head.rotation.x += currentPitch.current * 0.5
    }

    if (lookAtTargetRef.current && head) {
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
