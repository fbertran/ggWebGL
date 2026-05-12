attribute vec2 a_position;
attribute vec2 a_texcoord;
uniform vec4 u_domain;
varying vec2 v_texcoord;
void main() {
  float x_span = max(1e-6, u_domain.y - u_domain.x);
  float y_span = max(1e-6, u_domain.w - u_domain.z);
  gl_Position = vec4(((a_position.x - u_domain.x) / x_span) * 2.0 - 1.0,
                     ((a_position.y - u_domain.z) / y_span) * 2.0 - 1.0,
                     0.0, 1.0);
  v_texcoord = a_texcoord;
}
