precision mediump float;
uniform vec3 u_light_dir;
uniform vec2 u_scalar_range;
varying vec3 v_normal;
varying vec4 v_color;
varying float v_scalar;
vec3 scalar_color(float t) {
  t = clamp(t, 0.0, 1.0);
  return mix(vec3(0.12, 0.26, 0.68), vec3(0.94, 0.72, 0.18), smoothstep(0.0, 1.0, t));
}
void main() {
  float t = (v_scalar - u_scalar_range.x) / max(1e-6, u_scalar_range.y - u_scalar_range.x);
  float lambert = max(dot(normalize(v_normal), normalize(u_light_dir)), 0.0);
  gl_FragColor = vec4(scalar_color(t) * (0.38 + 0.72 * lambert), v_color.a);
}
