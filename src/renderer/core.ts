import { Renderer, TRenderingContext } from './types'

export const createRenderingContext = (canvas: HTMLCanvasElement): TRenderingContext => {
  const gl = canvas.getContext('webgl2', { alpha: false }) as WebGL2RenderingContext

  // gl.getExtension('OES_element_index_uint') // WebGL1

  gl.viewport(0, 0, canvas.width, canvas.height)
  gl.enable(gl.DEPTH_TEST)

  let renderer!: Renderer

  return {
    setRenderer(initializer) {
      renderer?.dispose()
      renderer = initializer(gl)
    },
    configure(config) {
      renderer!.configure(config)
    },

    clear() {
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    },
    render() {
      renderer!.render()
    },
    flush() {
      gl.flush()
    }
  }
}
