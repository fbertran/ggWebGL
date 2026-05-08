attribute vec3 a_position3;
attribute float a_size;
attribute vec4 a_color;
attribute float a_age;

uniform mat4 u_view_projection;
uniform float u_point_scale;
uniform float u_min_point_size;

varying vec4 v_color;
varying float v_age;

void main() {
  gl_Position = u_view_projection * vec4(a_position3, 1.0);
  gl_PointSize = max(u_min_point_size, a_size * u_point_scale);
  v_color = a_color;
  v_age = a_age;
}
