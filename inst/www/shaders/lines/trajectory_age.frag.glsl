precision mediump float;
varying vec4 v_color;
varying float v_age;
void main() {
  float age = clamp(v_age, 0.0, 1.0);
  gl_FragColor = vec4(mix(v_color.rgb * 0.35, v_color.rgb * 1.05, age), max(0.6, v_color.a));
}
