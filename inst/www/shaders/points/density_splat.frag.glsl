precision mediump float;
uniform float u_density_alpha_boost;
uniform float u_density_alpha_ceiling;
varying vec4 v_color;
void main() {
  vec2 centered = gl_PointCoord - vec2(0.5, 0.5);
  float radius = length(centered) * 2.0;
  if (radius > 1.0) discard;
  float w = exp(-(radius * radius) / (2.0 * 0.42 * 0.42));
  gl_FragColor = vec4(clamp(v_color.rgb, 0.0, 1.0),
                      clamp(v_color.a * w * u_density_alpha_boost, 0.0, u_density_alpha_ceiling));
}
