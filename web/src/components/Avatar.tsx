import { useEffect, useRef } from 'react'
import { useFrame, useThree, useLoader } from '@react-three/fiber'
import { GLTFLoader } from 'three-stdlib'
import * as THREE from 'three'
import { VRMLoaderPlugin, VRM } from '@pixiv/three-vrm'
import { VRMAnimationLoaderPlugin, createVRMAnimationClip } from '@pixiv/three-vrm-animation'
import type { AgentPerformance, AgentState, CameraConfig } from '../hooks/useBridge'

interface AvatarProps {
  mouseRef: React.MutableRefObject<{ x: number; y: number }>
  mode: 'head' | 'body'
  headNodeRef?: React.MutableRefObject<THREE.Object3D | null>
  agentState?: AgentState
  performance?: AgentPerformance | null
  cameraConfig?: CameraConfig | null
}

export function Avatar({ mouseRef, mode, headNodeRef, performance, cameraConfig }: AvatarProps) {
  const { scene } = useThree()
  const vrmRef = useRef<VRM | null>(null)
  const mixerRef = useRef<THREE.AnimationMixer | null>(null)
  const actionsRef = useRef<{
    current: THREE.AnimationAction | null,
    next: THREE.AnimationAction | null
  }>({ current: null, next: null })

  const currentYaw = useRef(0)
  const currentPitch = useRef(0)
  const lookAtTargetRef = useRef<THREE.Object3D>(new THREE.Object3D())

  const currentExpressionRef = useRef<string>('neutral')
  const targetWeightRef = useRef(0)
  const currentWeightRef = useRef(0)
  const expressionTimerRef = useRef<number | null>(null)

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
      mixerRef.current = mixer
      const clip1 = createVRMAnimationClip(animUserData.vrmAnimations[0], vrm)
      const clip2 = clip1.clone()
      const action1 = mixer.clipAction(clip1)
      const action2 = mixer.clipAction(clip2)
      action1.setLoop(THREE.LoopOnce, 1)
      action1.clampWhenFinished = true
      action2.setLoop(THREE.LoopOnce, 1)
      action2.clampWhenFinished = true
      action1.play()
      actionsRef.current = { current: action1, next: action2 }
    }

    return () => {
        scene.remove(lookAtTargetRef.current)
    }
  }, [userData, animUserData, scene, headNodeRef])

  useEffect(() => {
    if (!performance || !vrmRef.current) return
    
    if (performance.face) {
        if (expressionTimerRef.current) clearTimeout(expressionTimerRef.current)
        if (currentExpressionRef.current !== performance.face) {
            if (vrmRef.current.expressionManager) {
                vrmRef.current.expressionManager.setValue(currentExpressionRef.current, 0)
            }
            currentExpressionRef.current = performance.face
        }
        targetWeightRef.current = performance.intensity ?? 1.0
        const duration = (performance.duration ?? 5.0) * 1000
        expressionTimerRef.current = window.setTimeout(() => {
            targetWeightRef.current = 0
        }, duration)
    }
  }, [performance])

  useFrame((_, delta) => {
    const vrm = vrmRef.current
    if (!vrm) return

    if (mixerRef.current && actionsRef.current.current && actionsRef.current.next) {
        mixerRef.current.update(delta)
        const activeAction = actionsRef.current.current
        const nextAction = actionsRef.current.next
        const clipDuration = activeAction.getClip().duration
        const fadeDuration = Math.min(1.0, clipDuration * 0.4)
        if (activeAction.time > (clipDuration - fadeDuration) && !nextAction.isRunning()) {
            nextAction.reset()
            nextAction.play()
            activeAction.crossFadeTo(nextAction, fadeDuration, true)
            actionsRef.current.current = nextAction
            actionsRef.current.next = activeAction
        }
    }

    if (vrm.expressionManager) {
        const lerpSpeed = 3.0 * delta
        currentWeightRef.current = THREE.MathUtils.lerp(currentWeightRef.current, targetWeightRef.current, lerpSpeed)
        const presetName = currentExpressionRef.current
        if (currentWeightRef.current < 0.01) currentWeightRef.current = 0
        vrm.expressionManager.setValue(presetName, currentWeightRef.current)
        vrm.expressionManager.update()
    }
    
    vrm.update(delta)

    // === [核心] 鼠标跟随控制逻辑 ===
    // 默认关闭 (false)，除非 API 或设置中显式开启
    const shouldFollow = cameraConfig?.followMouse ?? false
    
    // 如果跟随开启，使用真实鼠标坐标；否则使用 (0,0) 即正中心
    const { x: mouseX, y: mouseY } = shouldFollow ? mouseRef.current : { x: 0, y: 0 }
    
    const isClosedMode = (mode === 'head')
    const trackingIntensity = isClosedMode ? 0.25 : 1.0
    const sensitivity = 0.002
    const maxYaw = THREE.MathUtils.degToRad(50)
    const maxPitch = THREE.MathUtils.degToRad(30)
    
    const targetYaw = THREE.MathUtils.clamp(mouseX * sensitivity * trackingIntensity, -maxYaw, maxYaw)
    const targetPitch = THREE.MathUtils.clamp(mouseY * sensitivity * trackingIntensity, -maxPitch, maxPitch)
    
    currentYaw.current = THREE.MathUtils.lerp(currentYaw.current, targetYaw, 0.1)
    currentPitch.current = THREE.MathUtils.lerp(currentPitch.current, targetPitch, 0.1)

    const head = vrm.humanoid.getRawBoneNode('head')
    const neck = vrm.humanoid.getRawBoneNode('neck')
    const spine = vrm.humanoid.getRawBoneNode('upperChest') || vrm.humanoid.getRawBoneNode('chest')
    if (spine) { spine.rotation.y += currentYaw.current * 0.2; spine.rotation.x += currentPitch.current * 0.2 }
    if (neck) { neck.rotation.y += currentYaw.current * 0.3; neck.rotation.x += currentPitch.current * 0.3 }
    if (head) { head.rotation.y += currentYaw.current * 0.5; head.rotation.x += currentPitch.current * 0.5 }

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
