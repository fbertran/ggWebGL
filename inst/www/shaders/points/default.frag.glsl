precision mediump float;
varying vec4 v_color;
void main() {
  vec2 centered = gl_PointCoord - vec2(0.5, 0.5);
  float radius = length(centered) * 2.0;
  if (radius > 1.0) discard;
  gl_FragColor = v_color;
}
