precision mediump float;
varying vec4 v_color;
varying float v_age;
void main() {
  vec2 centered = gl_PointCoord - vec2(0.5, 0.5);
  float radius = length(centered) * 2.0;
  if (radius > 1.0) discard;
  float body = smoothstep(1.0, 0.62, radius);
  float uncertainty = clamp(1.0 - v_age, 0.0, 1.0);
  vec3 color = mix(v_color.rgb, vec3(0.06, 0.16, 0.28), 0.28 * uncertainty);
  gl_FragColor = vec4(color, clamp(v_color.a * body * (1.0 - 0.72 * uncertainty), 0.02, 0.92));
}
