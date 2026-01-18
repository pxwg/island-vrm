// web/src/components/ScissorDirector.tsx
import { useThree, useFrame } from '@react-three/fiber'
import { useEffect } from 'react'
import { calculateLayout } from '../utils/layout'
import type { ViewportConfig } from '../utils/layout'

interface ScissorDirectorProps {
  config: ViewportConfig // [修改] 接收完整配置对象
  active: boolean
}

export function ScissorDirector({ config, active }: ScissorDirectorProps) {
  const { gl, camera, size } = useThree()

  useEffect(() => {
    return () => {
      gl.setScissorTest(false)
      gl.setViewport(0, 0, size.width, size.height)
      gl.setScissor(0, 0, size.width, size.height)
    }
  }, [gl, size])

  useFrame(() => {
    if (!active) {
       gl.setScissorTest(false)
       gl.setViewport(0, 0, size.width, size.height)
       return 
    }

    // 使用传入的 config 计算
    const layout = calculateLayout(config, size.width, size.height)

    gl.setScissorTest(true)
    gl.setScissor(layout.x, layout.y, layout.width, layout.height)
    gl.setViewport(layout.x, layout.y, layout.width, layout.height)

    if ((camera as any).aspect !== undefined) {
        (camera as any).aspect = layout.width / layout.height;
        (camera as any).updateProjectionMatrix()
    }
  })

  return null
}
