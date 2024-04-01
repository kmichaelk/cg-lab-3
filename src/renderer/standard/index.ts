import { Renderer, RendererInitializer } from '../types'
import { createBuffers, createProgram } from '../utils'
import { BaseRenderer } from '../base'

import shaderSourceVertex from './shaders/vertex.glsl'
import shaderSourceFragment from './shaders/fragment.glsl'

export const StandardRenderer: RendererInitializer = (gl: WebGL2RenderingContext): Renderer => {
  const { program, attribs, uniforms, shaders } = createProgram(
    gl, {
    shaders: [
      { type: gl.VERTEX_SHADER, source: shaderSourceVertex },
      { type: gl.FRAGMENT_SHADER, source: shaderSourceFragment }
    ],
    attribs: {
      position: 'a_position',
    },
    uniforms: {
    }
  })

  // prettier-ignore
  const buffers = createBuffers(gl, [
    'position',
  ])

  const verticesCount = 6
  const vertices = new Float32Array([
    -1, -1,   1, -1,   -1, 1,
    -1,  1,   1, -1,    1, 1,
  ])

  return BaseRenderer({
    render(state) {
      gl.bindBuffer(gl.ARRAY_BUFFER, buffers.position)
      gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW)
      gl.vertexAttribPointer(attribs.position, 2, gl.FLOAT, false, 0, 0)
      gl.enableVertexAttribArray(attribs.position)

      gl.useProgram(program)

      gl.drawArrays(gl.TRIANGLES, 0, verticesCount)
    },
    dispose() {
      gl.deleteProgram(program)
      shaders.forEach((shader) => gl.deleteShader(shader))
      Object.values(buffers).forEach((buf) => gl.deleteBuffer(buf))
    }
  })
}
