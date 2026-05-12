precision mediump float;
uniform vec3 u_light_dir;
uniform vec2 u_z_range;
varying vec3 v_normal;
varying vec4 v_color;
varying float v_z;
vec3 height_color(float t) {
  t = clamp(t, 0.0, 1.0);
  return mix(mix(vec3(0.10, 0.34, 0.62), vec3(0.12, 0.64, 0.52), smoothstep(0.0, 0.55, t)),
             vec3(0.96, 0.76, 0.25), smoothstep(0.45, 1.0, t));
}
void main() {
  float zt = (v_z - u_z_range.x) / max(1e-6, u_z_range.y - u_z_range.x);
  float lambert = max(dot(normalize(v_normal), normalize(u_light_dir)), 0.0);
  vec3 color = height_color(zt) * (0.42 + 0.72 * lambert);
  gl_FragColor = vec4(color, v_color.a);
}
