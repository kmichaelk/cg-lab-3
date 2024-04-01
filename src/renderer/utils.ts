export const initShader = (gl: WebGLRenderingContext, type: GLenum, source: string) => {
  const shader = gl.createShader(type)
  if (!shader) {
    throw new Error('Failed to create shader')
  }

  gl.shaderSource(shader, source)
  gl.compileShader(shader)

  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.error(source)
    console.error(gl.getShaderInfoLog(shader))
    gl.deleteShader(shader)
    throw new Error('Failed to compile shader')
  }

  return shader
}

export const createProgram = <A extends string, U extends string>(
  gl: WebGLRenderingContext,
  { shaders, attribs, uniforms }: {
    shaders: {
      type: GLenum
      source: string
    }[]
    attribs: Record<A, string>,
    uniforms: Record<U, string>
  }
) => {
  const program = gl.createProgram()!
  const compiledShaders = shaders.map(({ type, source }) => initShader(gl, type, source))
  compiledShaders.forEach((shader) => gl.attachShader(program, shader))
  gl.linkProgram(program)

  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.error(gl.getProgramInfoLog(program))
    throw new Error('Failed to link program')
  }

  return {
    program,
    attribs: (Object.keys(attribs) as A[]).reduce((acc, key) =>
      ((acc[key] = gl.getAttribLocation(program, attribs[key])!), acc),
      <Record<A, number>>{}
    ),
    uniforms: (Object.keys(uniforms) as U[]).reduce((acc, key) =>
      ((acc[key] = gl.getUniformLocation(program, uniforms[key])!), acc),
      <Record<U, WebGLUniformLocation>>{}
    ),
    shaders: compiledShaders
  }
}

export const createBuffers = <K extends string>(gl: WebGLRenderingContext, keys: K[]): Record<K, WebGLBuffer> =>
  keys.reduce((acc, cur) => ((acc[cur] = gl.createBuffer()!), acc), <Record<K, WebGLBuffer>>{})
