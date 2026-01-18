import { useEffect, useRef, useState } from 'react'

declare global {
  interface Window {
    updateMouseParams?: (dx: number, dy: number) => void;
    setCameraMode?: (mode: string) => void;
    updateSize?: (w: number, h: number) => void;
  }
}

export function useNativeBridge() {
  const mouseRef = useRef({ x: 0, y: 0 })
  const [cameraMode, setCameraModeState] = useState<'head' | 'body'>('head')
  // [新增] 存储 Swift 传来的真实窗口尺寸
  const [windowSize, setWindowSize] = useState<{ width: number, height: number } | null>(null)

  useEffect(() => {
    window.updateMouseParams = (dx, dy) => {
      mouseRef.current = { x: dx, y: dy }
    }

    window.setCameraMode = (mode) => {
      if (mode === 'head' || mode === 'body') {
        setCameraModeState(mode)
      }
    }
    
    // [修改] 捕获尺寸并更新 State
    window.updateSize = (w, h) => {
      console.log(`Swift Resized to ${w}x${h}`)
      setWindowSize({ width: w, height: h })
    }

    return () => {
      delete window.updateMouseParams
      delete window.setCameraMode
      delete window.updateSize
    }
  }, [])

  return { mouseRef, cameraMode, windowSize }
}
