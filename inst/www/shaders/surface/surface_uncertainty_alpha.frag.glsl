precision mediump float;
uniform vec3 u_light_dir;
varying vec3 v_normal;
varying vec4 v_color;
varying float v_uncertainty;
void main() {
  float lambert = max(dot(normalize(v_normal), normalize(u_light_dir)), 0.0);
  gl_FragColor = vec4(v_color.rgb * (0.35 + 0.75 * lambert), v_color.a * (1.0 - 0.75 * clamp(v_uncertainty, 0.0, 1.0)));
}
