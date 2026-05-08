precision mediump float;

varying vec4 v_color;

void main() {
  gl_FragColor = vec4(clamp(v_color.rgb, 0.0, 1.0), clamp(v_color.a, 0.0, 1.0));
}
