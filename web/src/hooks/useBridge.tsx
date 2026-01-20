import { useEffect, useRef, useState } from 'react'

// === 类型定义 ===
export interface Vector3 { x: number; y: number; z: number }

export interface CameraSetting {
    position: Vector3
    target: Vector3
    fov: number
}

export interface CameraConfig {
    head: CameraSetting
    body: CameraSetting
    lerpSpeed: number
}

export interface AgentPerformance {
  face: 'neutral' | 'joy' | 'angry' | 'sorrow' | 'fun' | 'surprise';
  intensity?: number;
  action?: string;
  audio_url?: string;
  duration?: number;
}

export type AgentState = 'idle' | 'listening' | 'thinking';

declare global {
  interface Window {
    updateMouseParams?: (dx: number, dy: number) => void;
    setCameraMode?: (mode: string) => void;
    updateSize?: (w: number, h: number) => void;
    triggerPerformance?: (data: AgentPerformance) => void;
    setAgentState?: (state: AgentState) => void;
    // [新增] 接收相机配置
    updateCameraConfig?: (config: CameraConfig) => void;
  }
}

export function useNativeBridge() {
  const mouseRef = useRef({ x: 0, y: 0 })
  const [cameraMode, setCameraModeState] = useState<'head' | 'body'>('head')
  const [windowSize, setWindowSize] = useState<{ width: number, height: number } | null>(null)
  const [agentState, setAgentState] = useState<AgentState>('idle')
  const [performance, setPerformance] = useState<AgentPerformance | null>(null)
  
  // [新增] 相机配置状态
  const [cameraConfig, setCameraConfig] = useState<CameraConfig | null>(null)

  useEffect(() => {
    window.updateMouseParams = (dx, dy) => {
      mouseRef.current = { x: dx, y: dy }
    }

    window.setCameraMode = (mode) => {
      if (mode === 'head' || mode === 'body') {
        setCameraModeState(mode)
      }
    }
    
    window.updateSize = (w, h) => {
      setWindowSize({ width: w, height: h })
    }

    window.triggerPerformance = (data) => {
      // console.log("[Bridge] Performance:", data)
      setPerformance({ ...data, intensity: data.intensity ?? 1.0 })
    }

    window.setAgentState = (state) => {
      // console.log("[Bridge] State:", state)
      setAgentState(state)
    }

    // [新增] 监听配置更新
    window.updateCameraConfig = (config) => {
        // console.log("[Bridge] Config Updated:", config)
        setCameraConfig(config)
    }

    return () => {
      delete window.updateMouseParams
      delete window.setCameraMode
      delete window.updateSize
      delete window.triggerPerformance
      delete window.setAgentState
      delete window.updateCameraConfig
    }
  }, [])

  return { mouseRef, cameraMode, windowSize, agentState, performance, cameraConfig }
}
