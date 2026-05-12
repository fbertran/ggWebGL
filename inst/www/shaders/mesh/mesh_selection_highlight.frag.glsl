precision mediump float;
uniform vec3 u_light_dir;
varying vec3 v_normal;
varying vec4 v_color;
void main() {
  float lambert = max(dot(normalize(v_normal), normalize(u_light_dir)), 0.0);
  vec3 selected = mix(v_color.rgb, vec3(1.0, 0.70, 0.12), 0.45);
  gl_FragColor = vec4(selected * (0.42 + 0.72 * lambert), max(v_color.a, 0.95));
}
