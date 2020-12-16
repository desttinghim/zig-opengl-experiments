#version 300 es

in highp vec2 uv;

layout(location = 0) out highp vec4 color;

uniform sampler2D msdf;
// uniform pxRange;

mediump float median(mediump float r, mediump float g, mediump float b) {
  return max(min(r, g), min(max(r, g), b));
}

void main() {
  mediump vec2 msdfUnit = 1.0 / vec2(textureSize(msdf, 0));
  mediump vec3 samp = texture(msdf, uv).rgb;
  mediump float sigDist = median(samp.r, samp.g, samp.b) - 0.5;
  sigDist *= dot(msdfUnit, 0.5/fwidth(uv));
  mediump float opacity = clamp(sigDist + 0.5, 0.0, 1.0);
  color = mix(vec4(0.0, 0.0, 0.0, 0.0), vec4(1.0, 1.0, 1.0, 1.0), opacity);
}
