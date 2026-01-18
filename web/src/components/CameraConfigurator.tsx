import { useState, useEffect } from 'react'
import * as THREE from 'three'
import { calculateLayout } from '../utils/layout'
import type { ViewportConfig } from '../utils/layout'

interface CameraConfiguratorProps {
  currentMode: 'head' | 'body'
  currentConfig: ViewportConfig // [新增] 接收当前生效的配置
  onConfigChange: (newConfig: Partial<ViewportConfig>) => void // [新增] 允许修改配置
  onModeChange: (mode: 'head' | 'body') => void
  cameraRef: React.MutableRefObject<THREE.PerspectiveCamera | null>
  orbitRef: React.MutableRefObject<any>
}

export function CameraConfigurator({ 
    currentMode, currentConfig, onConfigChange, onModeChange, 
    cameraRef, orbitRef 
}: CameraConfiguratorProps) {
    
  const [fov, setFov] = useState(40)
  const [windowSize, setWindowSize] = useState({ w: window.innerWidth, h: window.innerHeight })

  useEffect(() => {
    const handleResize = () => setWindowSize({ w: window.innerWidth, h: window.innerHeight })
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  useEffect(() => {
    if (cameraRef.current) {
        cameraRef.current.fov = fov
        cameraRef.current.updateProjectionMatrix()
    }
  }, [fov, cameraRef])

  const copyConfig = () => {
    if (!cameraRef.current || !orbitRef.current) return
    const cam = cameraRef.current
    const target = orbitRef.current.target
    const configStr = `
    "${currentMode}": {
      "position": { "x": ${cam.position.x.toFixed(3)}, "y": ${cam.position.y.toFixed(3)}, "z": ${cam.position.z.toFixed(3)} },
      "target": { "x": ${target.x.toFixed(3)}, "y": ${target.y.toFixed(3)}, "z": ${target.z.toFixed(3)} },
      "fov": ${fov}
    },`
    navigator.clipboard.writeText(configStr)
    alert(`Copied ${currentMode} config!`)
    console.log(configStr)
  }

  const layout = calculateLayout(currentConfig, windowSize.w, windowSize.h)

  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
      pointerEvents: 'none', zIndex: 10
    }}>
      {/* 1. 蒙版框 */}
      <div style={{
        position: 'absolute',
        left: layout.x, bottom: layout.y, width: layout.width, height: layout.height,
        borderRadius: layout.radius,
        boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.9)',
        border: '2px solid #00ff00',
        pointerEvents: 'none', overflow: 'hidden'
      }}>
        <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: 1, background: 'rgba(0,255,0,0.5)' }} />
        <div style={{ position: 'absolute', left: '50%', top: 0, bottom: 0, width: 1, background: 'rgba(0,255,0,0.5)' }} />
        {/* 显示当前实际生效的尺寸 */}
        <div style={{ position: 'absolute', top: 0, width: '100%', textAlign: 'center', color: '#0f0', fontSize: '10px', background: 'rgba(0,0,0,0.5)' }}>
            {currentConfig.width} x {currentConfig.height}
        </div>
      </div>

      {/* 2. 控制面板 */}
      <div style={{
        position: 'absolute', bottom: 30, left: '50%', transform: 'translateX(-50%)',
        backgroundColor: '#222', padding: 20, borderRadius: 12, pointerEvents: 'auto',
        display: 'flex', gap: 20, color: 'white', border: '1px solid #444'
      }}>
        {/* 模式切换 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
            <div style={{ display: 'flex', gap: 10 }}>
                <button onClick={() => onModeChange('head')} style={{ background: currentMode === 'head' ? '#0A84FF' : '#444', border: 'none', padding: '5px 10px', borderRadius: 4, color: 'white' }}>Head</button>
                <button onClick={() => onModeChange('body')} style={{ background: currentMode === 'body' ? '#0A84FF' : '#444', border: 'none', padding: '5px 10px', borderRadius: 4, color: 'white' }}>Body</button>
            </div>
            
            {/* [新增] 尺寸手动覆写 */}
            <div style={{display:'flex', gap: 5, marginTop: 5}}>
                <label style={{fontSize:10, color:'#888'}}>W:</label>
                <input 
                    type="number" 
                    value={currentConfig.width} 
                    onChange={(e) => onConfigChange({ width: Number(e.target.value) })}
                    style={{width: 50, background:'#333', border:'none', color:'white', fontSize:12}} 
                />
                <label style={{fontSize:10, color:'#888'}}>H:</label>
                <input 
                    type="number" 
                    value={currentConfig.height} 
                    onChange={(e) => onConfigChange({ height: Number(e.target.value) })}
                    style={{width: 50, background:'#333', border:'none', color:'white', fontSize:12}} 
                />
            </div>
        </div>
          {/* FOV & Copy */}
          <label style={{ fontSize: 12 }}>FOV: {fov}</label>
          <input type="range" min="10" max="100" value={fov} onChange={(e) => setFov(Number(e.target.value))} />
          <button onClick={copyConfig} style={{ background: '#30D158', border: 'none', borderRadius: 8, padding: '0 20px', fontWeight: 'bold' }}>Copy JSON</button>
      </div>
    </div>
  )
}
