precision mediump float;
varying vec4 v_color;
varying float v_age;
void main() {
  float age = clamp(v_age, 0.0, 1.0);
  float head = smoothstep(0.75, 1.0, age);
  vec3 rgb = mix(v_color.rgb * 0.28, v_color.rgb * 1.15, age) + vec3(0.10) * head;
  gl_FragColor = vec4(rgb, v_color.a * (0.20 + 0.80 * age));
}
