#version 300 es

precision mediump float;

in vec2 a_position;

out vec3 v_position;

void main(void) {
    gl_Position = vec4(a_position, 0.0, 1.0);
    v_position = vec3(a_position, 0.0);
}
