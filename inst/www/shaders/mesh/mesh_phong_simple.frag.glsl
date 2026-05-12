precision mediump float;
uniform vec3 u_light_dir;
uniform float u_ambient;
uniform float u_diffuse;
uniform float u_specular;
varying vec3 v_normal;
varying vec4 v_color;
void main() {
  vec3 normal = normalize(v_normal);
  vec3 light = normalize(u_light_dir);
  float lambert = max(dot(normal, light), 0.0);
  vec3 half_dir = normalize(light + vec3(0.0, 0.0, 1.0));
  float spec = pow(max(dot(normal, half_dir), 0.0), 18.0) * u_specular;
  gl_FragColor = vec4(v_color.rgb * clamp(u_ambient + u_diffuse * lambert, 0.0, 1.8) + vec3(spec), v_color.a);
}
