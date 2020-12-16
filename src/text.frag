#version 300 es

in highp vec2 uv;

layout(location = 0) out highp vec4 color;

void main() {
  color = vec4(uv, 0.0, 1.0);
}
