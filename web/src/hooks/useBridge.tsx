import { useEffect, useRef, useState } from 'react'

export interface AgentPerformance {
  face: 'neutral' | 'happy' | 'angry' | 'sorrow' | 'fun' | 'surprise';
  intensity?: number;
  action?: string;
  audio_url?: string;
  duration?: number;
}

export type AgentState = 'idle' | 'listening' | 'thinking';

export interface CameraConfig {
  head: CameraSetting;
  body: CameraSetting;
  lerpSpeed: number;
  // [新增]
  followMouse: boolean;
}

interface CameraSetting {
  position: { x: number; y: number; z: number };
  target: { x: number; y: number; z: number };
  fov: number;
}

declare global {
  interface Window {
    updateMouseParams?: (dx: number, dy: number) => void;
    setCameraMode?: (mode: string) => void;
    updateSize?: (w: number, h: number) => void;
    triggerPerformance?: (data: AgentPerformance) => void;
    setAgentState?: (state: AgentState) => void;
    setCameraConfig?: (config: CameraConfig) => void;
    updateCameraConfig?: (config: CameraConfig) => void;
    __pendingCameraConfig?: CameraConfig;
  }
}

export function useNativeBridge() {
  const mouseRef = useRef({ x: 0, y: 0 })
  const [cameraMode, setCameraModeState] = useState<'head' | 'body'>('head')
  const [windowSize, setWindowSize] = useState<{ width: number, height: number } | null>(null)
  
  const [agentState, setAgentState] = useState<AgentState>('idle')
  const [performance, setPerformance] = useState<AgentPerformance | null>(null)
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
      setPerformance({ ...data, intensity: data.intensity ?? 1.0 })
    }

    window.setAgentState = (state) => {
      setAgentState(state)
    }
    
    window.setCameraConfig = (config) => {
      setCameraConfig(config)
    }
    
    window.updateCameraConfig = (config) => {
      setCameraConfig(config)
    }
    
    if (window.__pendingCameraConfig) {
      setCameraConfig(window.__pendingCameraConfig)
      delete window.__pendingCameraConfig
    }

    return () => {
      delete window.updateMouseParams
      delete window.setCameraMode
      delete window.updateSize
      delete window.triggerPerformance
      delete window.setAgentState
      delete window.setCameraConfig
      delete window.updateCameraConfig
    }
  }, [])

  return { mouseRef, cameraMode, windowSize, agentState, performance, cameraConfig }
}
