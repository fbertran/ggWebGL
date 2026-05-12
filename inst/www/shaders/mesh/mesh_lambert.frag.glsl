precision mediump float;
uniform vec3 u_light_dir;
uniform float u_ambient;
uniform float u_diffuse;
varying vec3 v_normal;
varying vec4 v_color;
void main() {
  float lambert = max(dot(normalize(v_normal), normalize(u_light_dir)), 0.0);
  gl_FragColor = vec4(v_color.rgb * clamp(u_ambient + u_diffuse * lambert, 0.0, 1.8), v_color.a);
}
