precision mediump float;
varying vec4 v_color;
void main() {
  vec2 centered = gl_PointCoord - vec2(0.5, 0.5);
  float radius = length(centered) * 2.0;
  if (radius > 1.0) discard;
  float glow = smoothstep(1.0, 0.0, radius);
  float core = smoothstep(0.52, 0.0, radius);
  vec3 boosted = min(vec3(1.0), v_color.rgb * 1.85 + vec3(0.10, 0.12, 0.16));
  gl_FragColor = vec4(mix(v_color.rgb * 0.50, boosted, core),
                      max(v_color.a * glow, 0.16 * smoothstep(1.0, 0.68, radius)));
}
