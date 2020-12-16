#version 300 es

in highp vec2 uv;

layout(location = 0) out highp vec4 color;

uniform sampler2D fontTexture;

void main() {
  color = texture(fontTexture, uv);
}
