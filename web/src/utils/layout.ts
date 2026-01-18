// 默认配置 (仅当在浏览器里没有 Swift 信号时作为保底)
export const DEFAULT_CONFIG = {
  head: { width: 40, height: 40, radius: '50%', name: 'Default Head' },
  body: { width: 150, height: 158, radius: '12px', name: 'Default Body' },
};

export interface ViewportConfig {
  width: number;
  height: number;
  radius: string;
  name: string;
}

export function calculateLayout(
  // [修改] 第一个参数不再是简单的 mode string，而是具体的配置对象
  config: ViewportConfig,
  windowWidth: number,
  windowHeight: number
) {
  // 缩放比例：让模拟框占据屏幕的 60%
  const scale = Math.min(
    (windowWidth * 0.6) / config.width,
    (windowHeight * 0.6) / config.height
  );

  const width = config.width * scale;
  const height = config.height * scale;

  const x = (windowWidth - width) / 2;
  const y = (windowHeight - height) / 2;

  return {
    width,
    height,
    x,
    y,
    scale,
    radius: config.radius,
    name: config.name,
  };
}
