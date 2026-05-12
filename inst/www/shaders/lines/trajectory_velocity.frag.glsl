precision mediump float;
varying vec4 v_color;
varying float v_metric;
vec3 velocity_color(float t) {
  t = clamp(t, 0.0, 1.0);
  return mix(mix(vec3(0.08, 0.23, 0.62), vec3(0.08, 0.68, 0.62), smoothstep(0.0, 0.55, t)),
             vec3(0.98, 0.72, 0.18), smoothstep(0.45, 1.0, t));
}
void main() {
  gl_FragColor = vec4(mix(v_color.rgb, velocity_color(v_metric), 0.86), max(0.55, v_color.a));
}
