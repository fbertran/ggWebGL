precision mediump float;
uniform sampler2D u_texture;
varying vec2 v_texcoord;
void main() {
  vec4 color = texture2D(u_texture, v_texcoord);
  float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
  float keep = step(0.50, luminance);
  gl_FragColor = vec4(mix(vec3(0.88, 0.92, 0.96), color.rgb, keep), color.a * mix(0.18, 1.0, keep));
}
