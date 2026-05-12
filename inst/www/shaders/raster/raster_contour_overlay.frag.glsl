precision mediump float;
uniform sampler2D u_texture;
varying vec2 v_texcoord;
void main() {
  vec4 color = texture2D(u_texture, v_texcoord);
  float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
  float band = abs(fract(luminance * 8.0) - 0.5);
  float contour = smoothstep(0.055, 0.0, band);
  gl_FragColor = vec4(mix(color.rgb, vec3(0.05, 0.09, 0.16), contour * 0.85), max(color.a, contour * 0.9));
}
