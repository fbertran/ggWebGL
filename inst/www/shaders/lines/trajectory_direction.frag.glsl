precision mediump float;
varying vec4 v_color;
varying float v_metric;
vec3 direction_color(float t) {
  t = fract(clamp(t, 0.0, 1.0));
  return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.00, 0.33, 0.67)));
}
void main() {
  gl_FragColor = vec4(mix(v_color.rgb, direction_color(v_metric), 0.82), max(0.55, v_color.a));
}
