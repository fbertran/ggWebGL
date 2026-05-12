attribute vec3 a_position3;
attribute vec3 a_normal;
attribute vec4 a_color;
attribute float a_uncertainty;
uniform mat4 u_view_projection;
varying vec3 v_normal;
varying vec4 v_color;
varying float v_z;
varying float v_uncertainty;
void main() {
  gl_Position = u_view_projection * vec4(a_position3, 1.0);
  v_normal = normalize(a_normal);
  v_color = a_color;
  v_z = a_position3.z;
  v_uncertainty = a_uncertainty;
}
