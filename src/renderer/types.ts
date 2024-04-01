export interface TRenderingContext {
  setRenderer: (initializer: RendererInitializer) => void
  configure: (config: RendererConfiguration) => void

  clear: () => void
  render: () => void
  flush: () => void
}

export type RendererInitializer = (gl: WebGL2RenderingContext) => Renderer

export interface Renderer {
  render: () => void
  configure: (config: RendererConfiguration) => void
  dispose: () => void
}

export interface RendererConfiguration {
  
}

export type RendererConfigurationProperty = keyof RendererConfiguration
