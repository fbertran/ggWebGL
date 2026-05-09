HTMLWidgets.widget({
  name: "ggWebGL",
  type: "output",

  factory: function(el, width, height) {
    var TIMELINE_UPDATE_MESSAGE_TYPE = "ggWebGL:updateTimeline";
    var state = {
      root: null,
      title: null,
      subtitle: null,
      meta: null,
      stage: null,
      canvas: null,
      panelOverlayBack: null,
	  panelOverlayFront: null,
      selectionOverlay: null,
      selectionControls: null,
      selectionStatus: null,
      empty: null,
      tooltip: null,
      axes: null,
      notes: null,
      gl: null,
      programs: null,
      x: null,
      baseDomains: {},
      viewDomains: {},
      hover: {
        clientX: 0,
        clientY: 0,
        panelId: null
      },
      drag: {
        active: false,
        panelId: null,
        pointerId: null,
        lastClientX: 0,
        lastClientY: 0
      },
      selection: {
        active: false,
        mode: null,
        panelId: null,
        pointerId: null,
        points: [],
        startClientX: 0,
        startClientY: 0,
        currentClientX: 0,
        currentClientY: 0,
        modePreference: "brush",
        result: null
      },
      timeline: {
        values: [],
        value: null,
        index: 0,
        source: "frame",
        filter: "exact",
        playing: false,
        speed: 1,
        loop: false,
        fps: null,
        enabled: false,
        controls: false,
        lastTick: null
      },
      camera: {
        yaw: 0,
        pitch: 0,
        distance: 2.8,
        target: [0, 0, 0],
        rotation: [0, 0, 0, 1],
        up: [0, 1, 0],
        fov: 45,
        near: 0.01,
        far: 1000
      }
    };

    function getStageRect() {
      if (!state.stage) {
        return { left: 0, top: 0, width: 0, height: 0 };
      }

      return state.stage.getBoundingClientRect();
    }

    function multiplyQuaternion(a, b) {
      return normalizeQuaternion([
        a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1],
        a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0],
        a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3],
        a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2]
      ]);
    }

    function axisAngleQuaternion(axis, angle) {
      var len = Math.sqrt(axis[0] * axis[0] + axis[1] * axis[1] + axis[2] * axis[2]);
      if (!(len > 0) || !isFinite(angle)) {
        return [0, 0, 0, 1];
      }
      var half = angle * 0.5;
      var s = Math.sin(half) / len;
      return normalizeQuaternion([axis[0] * s, axis[1] * s, axis[2] * s, Math.cos(half)]);
    }

    function orbitQuaternion(yaw, pitch) {
      return multiplyQuaternion(
        axisAngleQuaternion([0, 1, 0], yaw || 0),
        axisAngleQuaternion([1, 0, 0], pitch || 0)
      );
    }

    function rotateByQuaternion(vector, q) {
      var x = vector[0], y = vector[1], z = vector[2];
      var qx = q[0], qy = q[1], qz = q[2], qw = q[3];
      var ix = qw * x + qy * z - qz * y;
      var iy = qw * y + qz * x - qx * z;
      var iz = qw * z + qx * y - qy * x;
      var iw = -qx * x - qy * y - qz * z;
      return [
        ix * qw + iw * -qx + iy * -qz - iz * -qy,
        iy * qw + iw * -qy + iz * -qx - ix * -qz,
        iz * qw + iw * -qz + ix * -qy - iy * -qx
      ];
    }

    function applyTrackballDrag(dx, dy) {
      var amount = Math.sqrt(dx * dx + dy * dy);
      if (!(amount > 0)) {
        return;
      }
      var qx = axisAngleQuaternion([0, 1, 0], dx * 0.012);
      var qy = axisAngleQuaternion([1, 0, 0], dy * 0.012);
      state.camera.rotation = multiplyQuaternion(multiplyQuaternion(qx, qy), state.camera.rotation || [0, 0, 0, 1]);
      el.ggwebglLastCameraController = "trackball";
      el.ggwebglLastCameraState = {
        rotation: state.camera.rotation.slice(),
        target: state.camera.target.slice(),
        distance: state.camera.distance
      };
    }

    function panCameraTarget(dx, dy, box) {
      var scale = state.camera.distance / Math.max(1, Math.min(box.plotWidth || 1, box.plotHeight || 1));
      state.camera.target[0] -= dx * scale;
      state.camera.target[1] += dy * scale;
      el.ggwebglLastCameraPan = state.camera.target.slice();
    }

    function getCanvasClientMetrics() {
      var rect = getStageRect();
      var width = Math.max(1, Math.round(rect.width));
      var height = Math.max(1, Math.round(rect.height));

      return {
        rect: rect,
        width: width,
        height: height
      };
    }


    function getCanvasScale() {
      var metrics = getCanvasClientMetrics();
      return {
        rect: metrics.rect,
        cssWidth: metrics.width,
        cssHeight: metrics.height,
        scaleX: state.canvas ? (state.canvas.width / Math.max(1, metrics.width)) : 1,
        scaleY: state.canvas ? (state.canvas.height / Math.max(1, metrics.height)) : 1
      };
    }

    function currentRenderingMode() {
      return state.x && state.x.webgl && state.x.webgl.rendering
        ? state.x.webgl.rendering
        : "visualization";
    }

    function ensureWidgetLayout() {
      var publication = currentRenderingMode() === "publication";

      if (!el.style.display) {
        el.style.display = "block";
      }
      if (!el.style.position) {
        el.style.position = "relative";
      }
      el.style.boxSizing = "border-box";

      if (state.root) {
        state.root.style.position = "relative";
        state.root.style.width = "100%";
        state.root.style.height = "100%";
        state.root.style.boxSizing = "border-box";
        state.root.style.display = "grid";
        state.root.style.gridTemplateRows = publication
          ? "minmax(0, 1fr)"
          : "auto minmax(0, 1fr) auto auto auto auto auto";
      }

      if (state.stage) {
        state.stage.style.position = "relative";
        state.stage.style.width = "100%";
        state.stage.style.overflow = "hidden";
        state.stage.style.boxSizing = "border-box";
        state.stage.style.minHeight = publication ? "0px" : "320px";
      }

      if (state.canvas) {
        state.canvas.style.position = "absolute";
        state.canvas.style.inset = "0";
        state.canvas.style.left = "0";
        state.canvas.style.top = "0";
        state.canvas.style.display = "block";
      }
    }

    function applyWidgetSize(targetWidth, targetHeight) {
      var resolvedWidth = Number(targetWidth);
      var resolvedHeight = Number(targetHeight);
      var publication = currentRenderingMode() === "publication";

      if (isFinite(resolvedWidth) && resolvedWidth > 0) {
        el.style.width = resolvedWidth + "px";
      } else if (!el.style.width) {
        el.style.width = "100%";
      }

      if (isFinite(resolvedHeight) && resolvedHeight > 0) {
        el.style.height = (publication ? resolvedHeight : Math.max(320, resolvedHeight)) + "px";
      } else if (!el.style.height) {
        el.style.height = publication ? "480px" : "640px";
      }

      ensureWidgetLayout();
    }


    var primitiveVertexShaderSource = [
      "attribute vec2 a_position;",
      "attribute float a_size;",
      "attribute vec4 a_color;",
      "attribute float a_age;",
      "attribute float a_metric;",
      "uniform vec4 u_domain;",
      "uniform float u_point_scale;",
      "uniform float u_min_point_size;",
      "varying vec4 v_color;",
      "varying float v_age;",
      "varying float v_metric;",
      "void main() {",
      "  float xSpan = max(1e-6, u_domain.y - u_domain.x);",
      "  float ySpan = max(1e-6, u_domain.w - u_domain.z);",
      "  float clipX = ((a_position.x - u_domain.x) / xSpan) * 2.0 - 1.0;",
      "  float clipY = ((a_position.y - u_domain.z) / ySpan) * 2.0 - 1.0;",
      "  gl_Position = vec4(clipX, clipY, 0.0, 1.0);",
      "  gl_PointSize = max(u_min_point_size, a_size * u_point_scale);",
      "  v_color = a_color;",
      "  v_age = a_age;",
      "  v_metric = a_metric;",
      "}"
    ].join("\n");

    var primitive3dVertexShaderSource = [
      "attribute vec3 a_position3;",
      "attribute float a_size;",
      "attribute vec4 a_color;",
      "attribute float a_age;",
      "attribute float a_metric;",
      "uniform mat4 u_view_projection;",
      "uniform float u_point_scale;",
      "uniform float u_min_point_size;",
      "varying vec4 v_color;",
      "varying float v_age;",
      "varying float v_metric;",
      "void main() {",
      "  gl_Position = u_view_projection * vec4(a_position3, 1.0);",
      "  gl_PointSize = max(u_min_point_size, a_size * u_point_scale);",
      "  v_color = a_color;",
      "  v_age = a_age;",
      "  v_metric = a_metric;",
      "}"
    ].join("\n");

	var primitiveFragmentShaderSource = [
	  "precision mediump float;",
	  "uniform float u_shader_mode;",
	  "uniform float u_is_point_layer;",
	  "uniform float u_density_alpha_boost;",
	  "uniform float u_density_alpha_ceiling;",
	  "varying vec4 v_color;",
	  "varying float v_age;",
	  "varying float v_metric;",
	  "vec3 trajectoryVelocityColor(float t) {",
	  "  t = clamp(t, 0.0, 1.0);",
	  "  vec3 low = vec3(0.08, 0.23, 0.62);",
	  "  vec3 mid = vec3(0.08, 0.68, 0.62);",
	  "  vec3 high = vec3(0.98, 0.72, 0.18);",
	  "  return mix(mix(low, mid, smoothstep(0.0, 0.55, t)), high, smoothstep(0.45, 1.0, t));",
	  "}",
	  "vec3 trajectoryDirectionColor(float t) {",
	  "  t = fract(clamp(t, 0.0, 1.0));",
	  "  return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.00, 0.33, 0.67)));",
	  "}",
	  "void main() {",
	  "  vec4 color = v_color;",
	  "",
	  "  if (u_is_point_layer > 0.5) {",
	  "    vec2 centered = gl_PointCoord - vec2(0.5, 0.5);",
	  "    float radius = length(centered) * 2.0;",
	  "    if (radius > 1.0) {",
	  "      discard;",
	  "    }",
	  "",
	  "    if (u_shader_mode > 0.5 && u_shader_mode < 1.5) {",
	  "      float sigma = 0.42;",
	  "      float r2 = radius * radius;",
	  "      float w = exp(-r2 / (2.0 * sigma * sigma));",
	  "      float sourceAlpha = clamp(color.a, 0.0, 1.0);",
	  "      color.rgb = clamp(color.rgb, 0.0, 1.0);",
	  "      color.a = clamp(sourceAlpha * w * u_density_alpha_boost, 0.0, u_density_alpha_ceiling);",
	  "      if (color.a < 0.003) discard;",
	  "    } else {",
	  "      color.rgb = clamp(color.rgb, 0.0, 1.0);",
	  "      float body = smoothstep(1.0, 0.65, radius);",
	  "      float edge = smoothstep(1.0, 0.85, radius);",
	  "      float alphaBody = max(color.a, 0.92) * body;",
	  "      float alphaEdge = max(color.a, 0.30) * edge;",
	  "      color.a = max(alphaBody, alphaEdge);",
	  "      if (color.a < 0.01) discard;",
	  "    }",
	  "",
	  "    gl_FragColor = color;",
	  "    return;",
	  "  }",
	  "",
	  "  if (u_shader_mode > 4.5) {",
	  "    color.rgb = mix(color.rgb, trajectoryDirectionColor(v_metric), 0.82);",
	  "    color.a = max(0.55, color.a);",
	  "  } else if (u_shader_mode > 3.5) {",
	  "    color.rgb = mix(color.rgb, trajectoryVelocityColor(v_metric), 0.86);",
	  "    color.a = max(0.55, color.a);",
	  "  } else if (u_shader_mode > 2.5) {",
	  "    float age = clamp(v_age, 0.0, 1.0);",
	  "    float head = smoothstep(0.75, 1.0, age);",
	  "    color.rgb = mix(color.rgb * 0.28, color.rgb * 1.15, age);",
	  "    color.rgb += vec3(0.10, 0.10, 0.10) * head;",
	  "    color.a *= 0.20 + 0.80 * age;",
	  "  } else if (u_shader_mode > 1.5) {",
	  "    float age = clamp(v_age, 0.0, 1.0);",
	  "    color.rgb = mix(color.rgb * 0.35, color.rgb * 1.05, age);",
	  "    color.a = max(0.6, color.a);",
	  "  }",
	  "",
	  "  gl_FragColor = color;",
	  "}"
	].join("\n");

    var surfaceVertexShaderSource = [
      "attribute vec3 a_position3;",
      "attribute vec3 a_normal;",
      "attribute vec4 a_color;",
      "attribute float a_uncertainty;",
      "uniform mat4 u_view_projection;",
      "varying vec3 v_normal;",
      "varying vec4 v_color;",
      "varying float v_z;",
      "varying float v_uncertainty;",
      "void main() {",
      "  gl_Position = u_view_projection * vec4(a_position3, 1.0);",
      "  v_normal = normalize(a_normal);",
      "  v_color = a_color;",
      "  v_z = a_position3.z;",
      "  v_uncertainty = a_uncertainty;",
      "}"
    ].join("\n");

    var surfaceFragmentShaderSource = [
      "precision mediump float;",
      "uniform float u_shading_mode;",
      "uniform vec3 u_light_dir;",
      "uniform vec2 u_z_range;",
      "varying vec3 v_normal;",
      "varying vec4 v_color;",
      "varying float v_z;",
      "varying float v_uncertainty;",
      "vec3 heightColor(float t) {",
      "  vec3 low = vec3(0.11, 0.37, 0.33);",
      "  vec3 mid = vec3(0.92, 0.72, 0.34);",
      "  vec3 high = vec3(0.95, 0.97, 0.99);",
      "  return mix(mix(low, mid, smoothstep(0.0, 0.62, t)), high, smoothstep(0.56, 1.0, t));",
      "}",
      "void main() {",
      "  vec4 color = v_color;",
      "  if (u_shading_mode > 1.5 && u_shading_mode < 2.5) {",
      "    float t = clamp((v_z - u_z_range.x) / max(1e-6, u_z_range.y - u_z_range.x), 0.0, 1.0);",
      "    color.rgb = heightColor(t);",
      "  }",
      "  if (u_shading_mode > 0.5 && u_shading_mode < 1.5) {",
      "    float diffuse = max(dot(normalize(v_normal), normalize(u_light_dir)), 0.0);",
      "    color.rgb *= 0.34 + 0.76 * diffuse;",
      "  }",
      "  if (u_shading_mode > 2.5) {",
      "    color.a *= 1.0 - clamp(v_uncertainty, 0.0, 0.92);",
      "  }",
      "  gl_FragColor = color;",
      "}"
    ].join("\n");

    var meshVertexShaderSource = [
      "attribute vec3 a_position3;",
      "attribute vec3 a_normal;",
      "attribute vec4 a_color;",
      "attribute float a_scalar;",
      "uniform mat4 u_view_projection;",
      "varying vec3 v_normal;",
      "varying vec4 v_color;",
      "varying float v_scalar;",
      "varying float v_z;",
      "void main() {",
      "  gl_Position = u_view_projection * vec4(a_position3, 1.0);",
      "  v_normal = normalize(a_normal);",
      "  v_color = a_color;",
      "  v_scalar = a_scalar;",
      "  v_z = a_position3.z;",
      "}"
    ].join("\n");

    var meshFragmentShaderSource = [
      "precision mediump float;",
      "uniform float u_shading_mode;",
      "uniform vec3 u_light_dir;",
      "uniform vec2 u_scalar_range;",
      "uniform float u_ambient;",
      "uniform float u_diffuse;",
      "uniform float u_specular;",
      "varying vec3 v_normal;",
      "varying vec4 v_color;",
      "varying float v_scalar;",
      "varying float v_z;",
      "vec3 meshScalarColor(float t) {",
      "  vec3 low = vec3(0.12, 0.22, 0.52);",
      "  vec3 mid = vec3(0.10, 0.68, 0.58);",
      "  vec3 high = vec3(0.97, 0.75, 0.22);",
      "  return mix(mix(low, mid, smoothstep(0.0, 0.58, t)), high, smoothstep(0.45, 1.0, t));",
      "}",
      "void main() {",
      "  vec4 color = v_color;",
      "  if (u_shading_mode > 2.5 && u_shading_mode < 3.5) {",
      "    float t = clamp((v_scalar - u_scalar_range.x) / max(1e-6, u_scalar_range.y - u_scalar_range.x), 0.0, 1.0);",
      "    color.rgb = meshScalarColor(t);",
      "  }",
      "  if (u_shading_mode > 0.5 && u_shading_mode < 2.5) {",
      "    vec3 normal = normalize(v_normal);",
      "    vec3 light = normalize(u_light_dir);",
      "    float lambert = max(dot(normal, light), 0.0);",
      "    float shade = clamp(u_ambient + u_diffuse * lambert, 0.0, 1.8);",
      "    if (u_shading_mode > 1.5) {",
      "      vec3 viewDir = vec3(0.0, 0.0, 1.0);",
      "      vec3 halfDir = normalize(light + viewDir);",
      "      float spec = pow(max(dot(normal, halfDir), 0.0), 18.0) * u_specular;",
      "      color.rgb = color.rgb * shade + vec3(spec);",
      "    } else {",
      "      color.rgb *= shade;",
      "    }",
      "  }",
      "  if (u_shading_mode > 3.5) {",
      "    color.rgb = mix(color.rgb, vec3(0.04, 0.08, 0.14), 0.22);",
      "    color.a = max(color.a, 0.95);",
      "  }",
      "  gl_FragColor = color;",
      "}"
    ].join("\n");

    var meshPickVertexShaderSource = [
      "attribute vec3 a_position3;",
      "attribute vec4 a_pick_color;",
      "uniform mat4 u_view_projection;",
      "varying vec4 v_pick_color;",
      "void main() {",
      "  gl_Position = u_view_projection * vec4(a_position3, 1.0);",
      "  v_pick_color = a_pick_color;",
      "}"
    ].join("\n");

    var meshPickFragmentShaderSource = [
      "precision mediump float;",
      "varying vec4 v_pick_color;",
      "void main() {",
      "  gl_FragColor = v_pick_color;",
      "}"
    ].join("\n");

    var rasterVertexShaderSource = [
      "attribute vec2 a_position;",
      "attribute vec2 a_texcoord;",
      "uniform vec4 u_domain;",
      "varying vec2 v_texcoord;",
      "void main() {",
      "  float xSpan = max(1e-6, u_domain.y - u_domain.x);",
      "  float ySpan = max(1e-6, u_domain.w - u_domain.z);",
      "  float clipX = ((a_position.x - u_domain.x) / xSpan) * 2.0 - 1.0;",
      "  float clipY = ((a_position.y - u_domain.z) / ySpan) * 2.0 - 1.0;",
      "  gl_Position = vec4(clipX, clipY, 0.0, 1.0);",
      "  v_texcoord = a_texcoord;",
      "}"
    ].join("\n");

    var rasterFragmentShaderSource = [
      "precision mediump float;",
      "uniform sampler2D u_texture;",
      "varying vec2 v_texcoord;",
      "void main() {",
      "  gl_FragColor = texture2D(u_texture, v_texcoord);",
      "}"
    ].join("\n");

    function escapeHtml(value) {
      return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
    }

    function normalizeStringArray(values) {
      if (Array.isArray(values)) {
        return values
          .map(function(value) { return String(value); })
          .filter(function(value) { return value.length > 0; });
      }

      if (typeof values === "string" && values.length) {
        return [values];
      }

      return [];
    }

    function normalizeNumberArray(values) {
      if (!Array.isArray(values)) {
        return [];
      }
      return values.map(Number).filter(function(value) { return isFinite(value); });
    }

    function normalizeCameraState(source) {
      source = source && typeof source === "object" ? source : {};
      var target = normalizeNumberArray(source.target);
      var rotation = normalizeNumberArray(source.rotation);
      var up = normalizeNumberArray(source.up);
      while (target.length < 3) {
        target.push(0);
      }
      while (rotation.length < 4) {
        rotation.push(rotation.length === 3 ? 1 : 0);
      }
      while (up.length < 3) {
        up.push(up.length === 1 ? 1 : 0);
      }
      if (!Array.isArray(source.rotation) && (source.yaw !== undefined || source.pitch !== undefined)) {
        rotation = orbitQuaternion(Number(source.yaw) || 0, Number(source.pitch) || 0);
      } else {
        rotation = normalizeQuaternion(rotation.slice(0, 4));
      }
      return {
        yaw: isFinite(Number(source.yaw)) ? Number(source.yaw) : 0,
        pitch: isFinite(Number(source.pitch)) ? Number(source.pitch) : 0,
        distance: isFinite(Number(source.distance)) ? Math.max(0.1, Number(source.distance)) : 2.8,
        target: target.slice(0, 3),
        rotation: rotation,
        up: up.slice(0, 3),
        fov: isFinite(Number(source.fov)) ? Number(source.fov) : 45,
        near: isFinite(Number(source.near)) ? Number(source.near) : 0.01,
        far: isFinite(Number(source.far)) ? Number(source.far) : 1000
      };
    }

    function normalizeQuaternion(values) {
      var x = Number(values[0]) || 0;
      var y = Number(values[1]) || 0;
      var z = Number(values[2]) || 0;
      var w = Number(values[3]);
      if (!isFinite(w)) {
        w = 1;
      }
      var norm = Math.sqrt(x * x + y * y + z * z + w * w);
      if (!(norm > 0)) {
        return [0, 0, 0, 1];
      }
      return [x / norm, y / norm, z / norm, w / norm];
    }

    function normalizeView(source, legacy) {
      source = source && typeof source === "object" ? source : {};
      legacy = legacy && typeof legacy === "object" ? legacy : {};
      var dimension = String(source.dimension || legacy.dimension || "2d").toLowerCase();
      if (["2d", "3d"].indexOf(dimension) === -1) {
        dimension = "2d";
      }
      var projection = String(source.projection || legacy.projection || "orthographic").toLowerCase();
      if (["orthographic", "perspective"].indexOf(projection) === -1) {
        projection = "orthographic";
      }
      var controller = String(source.controller || source.camera || legacy.camera || (dimension === "3d" ? "orbit" : "panzoom")).toLowerCase();
      if (["panzoom", "orbit", "trackball"].indexOf(controller) === -1) {
        controller = dimension === "3d" ? "orbit" : "panzoom";
      }
      if (dimension === "2d") {
        controller = "panzoom";
      }
      return {
        dimension: dimension,
        projection: projection,
        controller: controller,
        state: normalizeCameraState(source.state || source.camera_state || legacy.camera_state)
      };
    }

    function normalizeSelection(source, interactions) {
      source = source && typeof source === "object" ? source : {};
      interactions = normalizeStringArray(interactions);
      var mode = String(source.mode || "").toLowerCase().replace("-", "_");
      if (!mode) {
        var brush = interactions.indexOf("brush") !== -1;
        var lasso = interactions.indexOf("lasso") !== -1;
        mode = brush && lasso ? "brush_lasso" : (brush ? "brush" : (lasso ? "lasso" : "none"));
      }
      if (mode === "both") {
        mode = "brush_lasso";
      }
      if (["none", "brush", "lasso", "brush_lasso"].indexOf(mode) === -1) {
        mode = "none";
      }
      return {
        mode: mode,
        highlight: source.highlight !== false,
        emit: source.emit !== false
      };
    }

    function normalizeTimeline(source) {
      if (!source || typeof source !== "object") {
        return null;
      }
      var frames = normalizeNumberArray(source.frames).map(function(value) { return Math.round(value); });
      var times = normalizeNumberArray(source.time);
      var sourceValues = normalizeNumberArray(source.values);
      var sourceName = String(source.source || (times.length ? "time" : "frame")).toLowerCase();
      if (["frame", "time"].indexOf(sourceName) === -1) {
        sourceName = times.length ? "time" : "frame";
      }
      if (!frames.length && !times.length && sourceValues.length) {
        if (sourceName === "time") {
          times = sourceValues.slice();
        } else {
          frames = sourceValues.map(function(value) { return Math.round(value); });
        }
      }
      var values = times.length ? times.slice() : frames.slice();
      sourceName = times.length ? "time" : (frames.length ? "frame" : sourceName);
      var filter = String(source.mode || source.filter || "exact").toLowerCase() === "cumulative" ? "cumulative" : "exact";
      return {
        frames: frames,
        time: times,
        values: values,
        source: sourceName,
        duration: isFinite(Number(source.duration)) ? Math.max(0.1, Number(source.duration)) : Math.max(1, frames.length || times.length || 1),
        loop: source.loop !== false,
        autoplay: source.autoplay === true,
        speed: isFinite(Number(source.speed)) ? Math.max(0.05, Number(source.speed)) : 1,
        controls: source.controls !== false,
        filter: filter,
        mode: filter,
        fps: isFinite(Number(source.fps)) ? Math.max(0.05, Number(source.fps)) : null
      };
    }

    function normalizeWebglOptions(webgl) {
      var source = webgl && typeof webgl === "object" ? webgl : {};
      var extra = source.extra && typeof source.extra === "object" ? source.extra : {};
      var shader = String(source.shader || "default").toLowerCase();

      if (shader === "density" || shader === "splat") {
        shader = "density_splat";
      } else if (shader === "trajectory" || shader === "age") {
        shader = "trajectory_age";
      } else if (shader === "trajectory-glow" || shader === "glow") {
        shader = "trajectory_age_glow";
      } else if (shader === "trajectory-velocity" || shader === "velocity") {
        shader = "trajectory_velocity";
      } else if (shader === "trajectory-direction" || shader === "direction") {
        shader = "trajectory_direction";
      }

      var lineMode = String(source.line_mode || extra.line_mode || "auto").toLowerCase();
      var lineJoin = String(source.line_join || extra.line_join || "bevel").toLowerCase();
      var lineCap = String(source.line_cap || extra.line_cap || "round").toLowerCase();
      var rendering = String(source.rendering || "visualization").toLowerCase();
      var panelOverlay = String(source.panel_overlay || "auto").toLowerCase();
      var view = normalizeView(source.view, source);
      var dimension = view.dimension;
      var camera = view.controller === "panzoom" ? "orbit" : view.controller;
      var projection = view.projection;
      var depthTest = source.depth_test === undefined ? dimension === "3d" : source.depth_test !== false;
      var blendMode = String(source.blend_mode || extra.blend_mode || "auto").toLowerCase();
      var interactions = normalizeStringArray(source.interactions);
      var selection = normalizeSelection(source.selection, interactions);

      if (["visualization", "publication"].indexOf(rendering) === -1) {
        rendering = "visualization";
      }

      if (!interactions.length && rendering === "visualization") {
        interactions = ["pan", "zoom"];
      }

      if (["auto", "show", "hide"].indexOf(panelOverlay) === -1) {
        panelOverlay = "auto";
      }
      if (selection.mode === "brush" && interactions.indexOf("brush") === -1) {
        interactions.push("brush");
      } else if (selection.mode === "lasso" && interactions.indexOf("lasso") === -1) {
        interactions.push("lasso");
      } else if (selection.mode === "brush_lasso") {
        if (interactions.indexOf("brush") === -1) interactions.push("brush");
        if (interactions.indexOf("lasso") === -1) interactions.push("lasso");
      }

      return {
        shader: shader,
        antialias: source.antialias !== false,
        transparent: source.transparent !== undefined ? source.transparent !== false : rendering !== "publication",
        buffer_size: Number(source.buffer_size) || 65536,
        interactions: interactions,
        rendering: rendering,
        panel_overlay: panelOverlay,
        view: view,
        selection: selection,
        dimension: dimension,
        camera: camera,
        projection: projection,
        camera_state: view.state,
        depth_test: depthTest,
        blend_mode: ["auto", "alpha", "additive", "premultiplied"].indexOf(blendMode) !== -1 ? blendMode : "auto",
        timeline: normalizeTimeline(source.timeline),
        line_mode: ["auto", "native", "quad"].indexOf(lineMode) !== -1 ? lineMode : "auto",
        line_join: ["bevel", "round"].indexOf(lineJoin) !== -1 ? lineJoin : "bevel",
        line_cap: ["round", "butt"].indexOf(lineCap) !== -1 ? lineCap : "round",
        extra: extra
      };
    }

    function normalizeMessages(messages, singularMessage) {
      var out = normalizeStringArray(messages);

      if (!out.length && typeof singularMessage === "string" && singularMessage.length) {
        out = [singularMessage];
      }

      return out;
    }

    function normalizeLinePath(path) {
      var source = path && typeof path === "object" ? path : {};
      var xs = Array.isArray(source.x) ? source.x.map(Number) : [];
      var ys = Array.isArray(source.y) ? source.y.map(Number) : [];
      var zs = Array.isArray(source.z) ? source.z.map(Number) : [];
      var ages = Array.isArray(source.age) ? source.age.map(Number) : [];
      var frames = Array.isArray(source.frame) ? source.frame.map(Number) : [];
      var times = Array.isArray(source.time) ? source.time.map(Number) : [];
      var rgba = Array.isArray(source.rgba) ? source.rgba.map(Number) : [];
      var rows = Number(source.rows);
      var count = Math.min(
        isFinite(rows) && rows > 0 ? rows : Number.MAX_SAFE_INTEGER,
        xs.length,
        ys.length
      );

      if (!isFinite(count) || count < 0) {
        count = 0;
      }

      return {
        rows: count,
        group: source.group ? String(source.group) : "",
        x: xs.slice(0, count),
        y: ys.slice(0, count),
        z: zs.slice(0, count),
        width: isFinite(Number(source.width)) ? Number(source.width) : 1,
        age: ages.slice(0, count),
        frame: frames.slice(0, count),
        time: times.slice(0, count),
        rgba: rgba.slice(0, count * 4)
      };
    }

    function normalizeVector3(values, fallback) {
      var out = normalizeNumberArray(values);
      while (out.length < 3) {
        out.push(fallback[out.length] || 0);
      }
      return out.slice(0, 3);
    }

    function normalizeMaterial(source, legacyWireframe) {
      source = source && typeof source === "object" ? source : {};
      var shading = String(source.shading || "flat").toLowerCase();
      var cull = String(source.cull || "back").toLowerCase();
      if (["flat", "lambert", "mesh_flat", "mesh_lambert", "mesh_phong_simple", "mesh_scalar_colormap", "mesh_selection_highlight"].indexOf(shading) === -1) {
        shading = "flat";
      }
      if (["back", "none"].indexOf(cull) === -1) {
        cull = "back";
      }
      return {
        shading: shading,
        ambient: isFinite(Number(source.ambient)) ? Number(source.ambient) : 0.35,
        diffuse: isFinite(Number(source.diffuse)) ? Number(source.diffuse) : 0.75,
        specular: isFinite(Number(source.specular)) ? Number(source.specular) : 0,
        light_dir: normalizeVector3(source.light_dir, [0.35, 0.45, 0.82]),
        wireframe: source.wireframe === true || legacyWireframe === true,
        cull: cull
      };
    }

    function normalizeLayer(layer) {
      var source = layer && typeof layer === "object" ? layer : {};
      var type = source.type ? String(source.type) : "";

      if (type === "points") {
        var pointRows = Number(source.rows);
        var pointX = Array.isArray(source.x) ? source.x.map(Number) : [];
        var pointY = Array.isArray(source.y) ? source.y.map(Number) : [];
        var pointSize = Array.isArray(source.size) ? source.size.map(Number) : [];
        var pointAge = Array.isArray(source.age) ? source.age.map(Number) : [];
        var pointRgba = Array.isArray(source.rgba) ? source.rgba.map(Number) : [];
        var pointLabel = Array.isArray(source.label) ? source.label.map(String) : [];
        var pointId = Array.isArray(source.id) ? source.id.map(String) : [];
        var pointZ = Array.isArray(source.z) ? source.z.map(Number) : [];
        var pointFrame = Array.isArray(source.frame) ? source.frame.map(Number) : [];
        var pointTime = Array.isArray(source.time) ? source.time.map(Number) : [];
        var pointCount = Math.min(
          isFinite(pointRows) && pointRows > 0 ? pointRows : Number.MAX_SAFE_INTEGER,
          pointX.length,
          pointY.length
        );

        if (!isFinite(pointCount) || pointCount < 0) {
          pointCount = 0;
        }

        return {
          type: "points",
          geom: source.geom ? String(source.geom) : null,
          rows: pointCount,
          x: pointX.slice(0, pointCount),
          y: pointY.slice(0, pointCount),
          z: pointZ.slice(0, pointCount),
          size: pointSize.slice(0, pointCount),
          age: pointAge.slice(0, pointCount),
          label: pointLabel.slice(0, pointCount),
          id: pointId.slice(0, pointCount),
          frame: pointFrame.slice(0, pointCount),
          time: pointTime.slice(0, pointCount),
          rgba: pointRgba.slice(0, pointCount * 4)
        };
      }

      if (type === "vectors") {
        var vectorRows = Number(source.rows);
        var vectorX = Array.isArray(source.x) ? source.x.map(Number) : [];
        var vectorY = Array.isArray(source.y) ? source.y.map(Number) : [];
        var vectorZ = Array.isArray(source.z) ? source.z.map(Number) : [];
        var vectorXend = Array.isArray(source.xend) ? source.xend.map(Number) : [];
        var vectorYend = Array.isArray(source.yend) ? source.yend.map(Number) : [];
        var vectorZend = Array.isArray(source.zend) ? source.zend.map(Number) : [];
        var vectorWidth = Array.isArray(source.width) ? source.width.map(Number) : [];
        var vectorHead = Array.isArray(source.head_size) ? source.head_size.map(Number) : [];
        var vectorRgba = Array.isArray(source.rgba) ? source.rgba.map(Number) : [];
        var vectorId = Array.isArray(source.id) ? source.id.map(String) : [];
        var vectorFrame = Array.isArray(source.frame) ? source.frame.map(Number) : [];
        var vectorTime = Array.isArray(source.time) ? source.time.map(Number) : [];
        var vectorCount = Math.min(
          isFinite(vectorRows) && vectorRows > 0 ? vectorRows : Number.MAX_SAFE_INTEGER,
          vectorX.length,
          vectorY.length,
          vectorXend.length,
          vectorYend.length
        );

        if (!isFinite(vectorCount) || vectorCount < 0) {
          vectorCount = 0;
        }

        return {
          type: "vectors",
          geom: source.geom ? String(source.geom) : null,
          rows: vectorCount,
          x: vectorX.slice(0, vectorCount),
          y: vectorY.slice(0, vectorCount),
          z: vectorZ.slice(0, vectorCount),
          xend: vectorXend.slice(0, vectorCount),
          yend: vectorYend.slice(0, vectorCount),
          zend: vectorZend.slice(0, vectorCount),
          width: vectorWidth.slice(0, vectorCount),
          head_size: vectorHead.slice(0, vectorCount),
          id: vectorId.slice(0, vectorCount),
          frame: vectorFrame.slice(0, vectorCount),
          time: vectorTime.slice(0, vectorCount),
          rgba: vectorRgba.slice(0, vectorCount * 4)
        };
      }

      if (type === "lines") {
        var paths = linePathList(source.paths).map(normalizeLinePath).filter(function(pathSpec) {
          return pathSpec.rows >= 2;
        });

        return {
          type: "lines",
          geom: source.geom ? String(source.geom) : null,
          rows: paths.reduce(function(total, pathSpec) { return total + pathSpec.rows; }, 0),
          path_count: paths.length,
          paths: paths
        };
      }

      if (type === "raster") {
        return {
          type: "raster",
          geom: source.geom ? String(source.geom) : null,
          rows: isFinite(Number(source.rows)) ? Number(source.rows) : 0,
          width: isFinite(Number(source.width)) ? Number(source.width) : 0,
          height: isFinite(Number(source.height)) ? Number(source.height) : 0,
          xmin: Number(source.xmin),
          xmax: Number(source.xmax),
          ymin: Number(source.ymin),
          ymax: Number(source.ymax),
          interpolate: !!source.interpolate,
          rgba: Array.isArray(source.rgba) ? source.rgba.map(Number) : []
        };
      }

      if (type === "mesh") {
        var meshX = Array.isArray(source.x) ? source.x.map(Number) : [];
        var meshY = Array.isArray(source.y) ? source.y.map(Number) : [];
        var meshZ = Array.isArray(source.z) ? source.z.map(Number) : [];
        var meshNormal = Array.isArray(source.normal) ? source.normal.map(Number) : [];
        var meshIndices = Array.isArray(source.indices) ? source.indices.map(function(value) { return Math.max(0, Math.floor(Number(value))); }) : [];
        var meshWireIndices = Array.isArray(source.wire_indices) ? source.wire_indices.map(function(value) { return Math.max(0, Math.floor(Number(value))); }) : [];
        var meshRgba = Array.isArray(source.rgba) ? source.rgba.map(Number) : [];
        var meshScalar = Array.isArray(source.scalar) ? source.scalar.map(Number) : [];
        var meshVertexCount = Math.min(
          isFinite(Number(source.vertex_count)) ? Number(source.vertex_count) : Number.MAX_SAFE_INTEGER,
          meshX.length,
          meshY.length
        );
        var meshTriangleCount = Math.floor(meshIndices.length / 3);

        if (!isFinite(meshVertexCount) || meshVertexCount < 0) {
          meshVertexCount = 0;
        }

        return {
          type: "mesh",
          geom: source.geom ? String(source.geom) : null,
          rows: meshTriangleCount,
          vertex_count: meshVertexCount,
          triangle_count: meshTriangleCount,
          x: meshX.slice(0, meshVertexCount),
          y: meshY.slice(0, meshVertexCount),
          z: meshZ.slice(0, meshVertexCount),
          indices: meshIndices.slice(0, meshTriangleCount * 3),
          wire_indices: meshWireIndices,
          normal: meshNormal.slice(0, meshVertexCount * 3),
          rgba: meshRgba.slice(0, meshVertexCount * 4),
          scalar: meshScalar.slice(0, meshVertexCount),
          scalar_range: Array.isArray(source.scalar_range) ? source.scalar_range.map(Number).slice(0, 2) : [],
          id: Array.isArray(source.id) ? source.id.map(String).slice(0, meshVertexCount) : [],
          pick_id: Array.isArray(source.pick_id) ? source.pick_id.map(String).slice(0, meshTriangleCount) : [],
          material: normalizeMaterial(source.material, source.wireframe),
          wireframe: source.wireframe === true || (source.material && source.material.wireframe === true),
          bbox3d: source.bbox3d && typeof source.bbox3d === "object" ? source.bbox3d : null
        };
      }

      if (type === "surface") {
        var surfacePositions = Array.isArray(source.positions) ? source.positions.map(Number) : [];
        var surfaceNormals = Array.isArray(source.normals) ? source.normals.map(Number) : [];
        var surfaceColors = Array.isArray(source.colors) ? source.colors.map(Number) : [];
        var surfaceIndices = Array.isArray(source.indices) ? source.indices.map(function(value) { return Math.max(0, Math.floor(Number(value))); }) : [];
        var surfaceWireIndices = Array.isArray(source.wire_indices) ? source.wire_indices.map(function(value) { return Math.max(0, Math.floor(Number(value))); }) : [];
        var surfaceUncertainty = Array.isArray(source.uncertainty) ? source.uncertainty.map(Number) : [];
        var surfaceVertexCount = Math.min(
          isFinite(Number(source.vertex_count)) ? Number(source.vertex_count) : Number.MAX_SAFE_INTEGER,
          Math.floor(surfacePositions.length / 3)
        );
        var surfaceTriangleCount = Math.floor(surfaceIndices.length / 3);
        var surfaceMeta = source.surface_meta && typeof source.surface_meta === "object" ? source.surface_meta : {};

        if (!isFinite(surfaceVertexCount) || surfaceVertexCount < 0) {
          surfaceVertexCount = 0;
        }

        return {
          type: "surface",
          geom: source.geom ? String(source.geom) : null,
          rows: surfaceVertexCount,
          vertex_count: surfaceVertexCount,
          triangle_count: surfaceTriangleCount,
          positions: surfacePositions.slice(0, surfaceVertexCount * 3),
          normals: surfaceNormals.slice(0, surfaceVertexCount * 3),
          colors: surfaceColors.slice(0, surfaceVertexCount * 4),
          indices: surfaceIndices.slice(0, surfaceTriangleCount * 3),
          wire_indices: surfaceWireIndices,
          contours: Array.isArray(source.contours) ? source.contours.map(normalizeLinePath).filter(function(pathSpec) { return pathSpec.rows >= 2; }) : [],
          uncertainty: surfaceUncertainty.slice(0, surfaceVertexCount),
          material: normalizeMaterial(source.material, source.wireframe),
          pick_id: Array.isArray(source.pick_id) ? source.pick_id.map(String).slice(0, surfaceTriangleCount) : [],
          wireframe: source.wireframe === true || (source.material && source.material.wireframe === true),
          bbox3d: source.bbox3d && typeof source.bbox3d === "object" ? source.bbox3d : null,
          surface_meta: {
            nrow: Number(surfaceMeta.nrow) || 0,
            ncol: Number(surfaceMeta.ncol) || 0,
            x: Array.isArray(surfaceMeta.x) ? surfaceMeta.x.map(Number) : [],
            y: Array.isArray(surfaceMeta.y) ? surfaceMeta.y.map(Number) : [],
            z_range: Array.isArray(surfaceMeta.z_range) ? surfaceMeta.z_range.map(Number).slice(0, 2) : [],
            shading: surfaceMeta.shading ? String(surfaceMeta.shading) : "surface_lambert",
            triangulation: surfaceMeta.triangulation ? String(surfaceMeta.triangulation) : "regular_grid"
          }
        };
      }

      return null;
    }

    function panelBoundsFromGrid(panel, grid) {
      return {
        left: (panel.col - 1) / grid.cols,
        right: panel.col / grid.cols,
        top: (panel.row - 1) / grid.rows,
        bottom: panel.row / grid.rows
      };
    }

    function normalizePanel(panel, index) {
      var source = panel && typeof panel === "object" ? panel : {};
      var layers = Array.isArray(source.layers) ? source.layers.map(normalizeLayer).filter(Boolean) : [];
      var pointCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "points"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.rows; }, 0);
      var lineVertexCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "lines"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.rows; }, 0);
      var pathCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "lines"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.path_count; }, 0);
      var rasterCellCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "raster"; })
        .reduce(function(total, layerSpec) { return total + (layerSpec.width * layerSpec.height); }, 0);
      var vectorCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "vectors"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.rows; }, 0);
      var meshVertexCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "mesh"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.vertex_count; }, 0);
      var meshTriangleCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "mesh"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.triangle_count; }, 0);
      var surfaceVertexCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "surface"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.vertex_count; }, 0);
      var surfaceTriangleCount = layers
        .filter(function(layerSpec) { return layerSpec.type === "surface"; })
        .reduce(function(total, layerSpec) { return total + layerSpec.triangle_count; }, 0);

      return {
        panel_id: source.panel_id !== undefined ? source.panel_id : (index + 1),
        row: Math.max(1, Number(source.row) || 1),
        col: Math.max(1, Number(source.col) || 1),
        label: source.label ? String(source.label) : null,
        bounds: source.bounds && typeof source.bounds === "object" ? source.bounds : null,
        viewport: {
          x: normaliseAxisRange(source.viewport && source.viewport.x, [0, 1]),
          y: normaliseAxisRange(source.viewport && source.viewport.y, [0, 1])
        },
        primitives: layers.map(function(layerSpec) { return layerSpec.type; }).filter(function(value, idx, arr) {
          return arr.indexOf(value) === idx;
        }),
        point_count: pointCount,
        line_vertex_count: lineVertexCount,
        path_count: pathCount,
        raster_cell_count: rasterCellCount,
        vector_count: vectorCount,
        mesh_vertex_count: meshVertexCount,
        mesh_triangle_count: meshTriangleCount,
        surface_vertex_count: surfaceVertexCount,
        surface_triangle_count: surfaceTriangleCount,
        layers: layers
      };
    }

    function normalizeLegacyPanels(render) {
      var layers = Array.isArray(render.layers) ? render.layers.map(normalizeLayer).filter(Boolean) : [];

      if (!layers.length) {
        return [];
      }

      return [{
        panel_id: render.panel !== undefined ? render.panel : 1,
        row: 1,
        col: 1,
        label: null,
        bounds: null,
        viewport: {
          x: normaliseAxisRange(render.viewport && render.viewport.x, [0, 1]),
          y: normaliseAxisRange(render.viewport && render.viewport.y, [0, 1])
        },
        primitives: layers.map(function(layerSpec) { return layerSpec.type; }).filter(function(value, idx, arr) {
          return arr.indexOf(value) === idx;
        }),
        point_count: layers.filter(function(layerSpec) { return layerSpec.type === "points"; }).reduce(function(total, layerSpec) { return total + layerSpec.rows; }, 0),
        line_vertex_count: layers.filter(function(layerSpec) { return layerSpec.type === "lines"; }).reduce(function(total, layerSpec) { return total + layerSpec.rows; }, 0),
        path_count: layers.filter(function(layerSpec) { return layerSpec.type === "lines"; }).reduce(function(total, layerSpec) { return total + layerSpec.path_count; }, 0),
        raster_cell_count: layers.filter(function(layerSpec) { return layerSpec.type === "raster"; }).reduce(function(total, layerSpec) { return total + (layerSpec.width * layerSpec.height); }, 0),
        vector_count: layers.filter(function(layerSpec) { return layerSpec.type === "vectors"; }).reduce(function(total, layerSpec) { return total + layerSpec.rows; }, 0),
        mesh_vertex_count: layers.filter(function(layerSpec) { return layerSpec.type === "mesh"; }).reduce(function(total, layerSpec) { return total + layerSpec.vertex_count; }, 0),
        mesh_triangle_count: layers.filter(function(layerSpec) { return layerSpec.type === "mesh"; }).reduce(function(total, layerSpec) { return total + layerSpec.triangle_count; }, 0),
        surface_vertex_count: layers.filter(function(layerSpec) { return layerSpec.type === "surface"; }).reduce(function(total, layerSpec) { return total + layerSpec.vertex_count; }, 0),
        surface_triangle_count: layers.filter(function(layerSpec) { return layerSpec.type === "surface"; }).reduce(function(total, layerSpec) { return total + layerSpec.triangle_count; }, 0),
        layers: layers
      }];
    }

    function normalizeGrid(render, panels) {
      var grid = render.grid && typeof render.grid === "object" ? render.grid : {};
      var rows = Number(grid.rows) || panels.reduce(function(maxValue, panel) {
        return Math.max(maxValue, panel.row || 1);
      }, 1);
      var cols = Number(grid.cols) || panels.reduce(function(maxValue, panel) {
        return Math.max(maxValue, panel.col || 1);
      }, 1);

      return {
        rows: Math.max(1, rows),
        cols: Math.max(1, cols)
      };
    }

    function normalizeRenderPayload(render) {
      var source = render && typeof render === "object" ? render : {};
      var panels = Array.isArray(source.panels) && source.panels.length
        ? source.panels.map(normalizePanel)
        : normalizeLegacyPanels(source);
      var grid = normalizeGrid(source, panels);

      panels.forEach(function(panel) {
        panel.bounds = panel.bounds && typeof panel.bounds === "object"
          ? panel.bounds
          : panelBoundsFromGrid(panel, grid);
      });

      var pointCount = panels.reduce(function(total, panel) { return total + panel.point_count; }, 0);
      var lineVertexCount = panels.reduce(function(total, panel) { return total + panel.line_vertex_count; }, 0);
      var pathCount = panels.reduce(function(total, panel) { return total + panel.path_count; }, 0);
      var rasterCellCount = panels.reduce(function(total, panel) { return total + panel.raster_cell_count; }, 0);
      var vectorCount = panels.reduce(function(total, panel) { return total + (panel.vector_count || 0); }, 0);
      var meshVertexCount = panels.reduce(function(total, panel) { return total + (panel.mesh_vertex_count || 0); }, 0);
      var meshTriangleCount = panels.reduce(function(total, panel) { return total + (panel.mesh_triangle_count || 0); }, 0);
      var surfaceVertexCount = panels.reduce(function(total, panel) { return total + (panel.surface_vertex_count || 0); }, 0);
      var surfaceTriangleCount = panels.reduce(function(total, panel) { return total + (panel.surface_triangle_count || 0); }, 0);
      var primitives = panels.reduce(function(values, panel) {
        panel.primitives.forEach(function(primitive) {
          if (values.indexOf(primitive) === -1) {
            values.push(primitive);
          }
        });
        return values;
      }, []);
      var mode = source.mode ? String(source.mode) : (panels.some(function(panel) { return panel.layers.length > 0; }) ? "webgl" : "metadata");

      return {
        mode: mode,
        grid: grid,
        panels: panels,
        primitives: primitives,
        point_count: pointCount,
        line_vertex_count: lineVertexCount,
        path_count: pathCount,
        raster_cell_count: rasterCellCount,
        vector_count: vectorCount,
        mesh_vertex_count: meshVertexCount,
        mesh_triangle_count: meshTriangleCount,
        surface_vertex_count: surfaceVertexCount,
        surface_triangle_count: surfaceTriangleCount,
        dimension: String(source.dimension || "2d").toLowerCase() === "3d" ? "3d" : "2d",
        camera: source.camera && typeof source.camera === "object" ? source.camera : null,
        selection: source.selection && typeof source.selection === "object" ? normalizeSelection(source.selection, []) : null,
        timeline: normalizeTimeline(source.timeline),
        links: source.links && typeof source.links === "object" ? source.links : {},
        unsupported_layers: Array.isArray(source.unsupported_layers) ? source.unsupported_layers : [],
        messages: normalizeMessages(source.messages, source.message)
      };
    }

    function normalizeScenePayload(x) {
      var source = x && typeof x === "object" ? x : {};
      var normalized = {
        package_version: source.package_version || null,
        labels: source.labels && typeof source.labels === "object" ? source.labels : {},
        webgl: normalizeWebglOptions(source.webgl),
        layer_count: Number(source.layer_count) || 0,
        layers: Array.isArray(source.layers) ? source.layers : [],
        render: normalizeRenderPayload(source.render)
      };

      if (normalized.render.panels.length === 1) {
        normalized.render.panel = normalized.render.panels[0].panel_id;
        normalized.render.viewport = normalized.render.panels[0].viewport;
        normalized.render.layers = normalized.render.panels[0].layers;
      }
      normalized.render.dimension = normalized.render.dimension || normalized.webgl.view.dimension || normalized.webgl.dimension || "2d";
      normalized.render.camera = normalized.render.camera || {
        mode: normalized.webgl.view.controller,
        controller: normalized.webgl.view.controller,
        projection: normalized.webgl.view.projection,
        state: normalized.webgl.view.state
      };
      normalized.render.selection = normalized.render.selection || normalized.webgl.selection || { mode: "none", highlight: true, emit: true };
      normalized.render.timeline = normalized.render.timeline || normalized.webgl.timeline || null;
      if (window.ggWebGLScene && typeof window.ggWebGLScene.finalizeScene === "function") {
        normalized = window.ggWebGLScene.finalizeScene(normalized);
      }

      return normalized;
    }

    function createDom() {
      if (state.root) {
        return;
      }

      el.innerHTML = "";
      if (!el.classList.contains("ggwebgl-host")) {
        el.classList.add("ggwebgl-host");
      }

      var root = document.createElement("div");
      root.className = "ggwebgl";

      var header = document.createElement("div");
      header.className = "ggwebgl__header";

      var eyebrow = document.createElement("div");
      eyebrow.className = "ggwebgl__eyebrow";
      eyebrow.textContent = "Browser WebGL";

      var title = document.createElement("h3");
      title.className = "ggwebgl__title";

      var subtitle = document.createElement("p");
      subtitle.className = "ggwebgl__subtitle";

      var meta = document.createElement("p");
      meta.className = "ggwebgl__meta";

      header.appendChild(eyebrow);
      header.appendChild(title);
      header.appendChild(subtitle);
      header.appendChild(meta);

      var stage = document.createElement("div");
      stage.className = "ggwebgl__stage";
      stage.tabIndex = 0;

      var canvas = document.createElement("canvas");
      canvas.className = "ggwebgl__canvas";

	  var panelOverlayBack = document.createElement("div");
	  panelOverlayBack.className = "ggwebgl__panel-overlay ggwebgl__panel-overlay--back";

	  var panelOverlayFront = document.createElement("div");
	  panelOverlayFront.className = "ggwebgl__panel-overlay ggwebgl__panel-overlay--front";

      var selectionOverlay = document.createElement("div");
      selectionOverlay.className = "ggwebgl__selection-overlay";

      var empty = document.createElement("div");
      empty.className = "ggwebgl__empty";

      var tooltip = document.createElement("div");
      tooltip.className = "ggwebgl__tooltip";

	  stage.appendChild(panelOverlayBack);
	  stage.appendChild(canvas);
	  stage.appendChild(panelOverlayFront);
      stage.appendChild(selectionOverlay);
	  stage.appendChild(empty);
	  stage.appendChild(tooltip);

      var axes = document.createElement("div");
      axes.className = "ggwebgl__axes";
      axes.innerHTML = [
        "<div class='ggwebgl__axis ggwebgl__axis--y'></div>",
        "<div class='ggwebgl__axis ggwebgl__axis--x'></div>"
      ].join("");

      var notes = document.createElement("div");
      notes.className = "ggwebgl__notes";

      var selectionControls = document.createElement("div");
      selectionControls.className = "ggwebgl__selection-controls";
      selectionControls.innerHTML = [
        "<span class='ggwebgl__selection-label'>Selection</span>",
        "<button type='button' class='ggwebgl__selection-mode' data-mode='brush'>Brush</button>",
        "<button type='button' class='ggwebgl__selection-mode' data-mode='lasso'>Lasso</button>"
      ].join("");

      var selectionStatus = document.createElement("div");
      selectionStatus.className = "ggwebgl__selection-status";

      var timeline = document.createElement("div");
      timeline.className = "ggwebgl__timeline";
      timeline.innerHTML = [
        "<button type='button' class='ggwebgl__timeline-play'>Play</button>",
        "<input class='ggwebgl__timeline-scrub' type='range' min='0' max='0' value='0' step='1'>",
        "<select class='ggwebgl__timeline-speed'>",
        "<option value='0.5'>0.5x</option>",
        "<option value='1' selected>1x</option>",
        "<option value='2'>2x</option>",
        "</select>",
        "<button type='button' class='ggwebgl__timeline-reset'>Reset</button>"
      ].join("");

      root.appendChild(header);
      root.appendChild(stage);
      root.appendChild(selectionControls);
      root.appendChild(selectionStatus);
      root.appendChild(timeline);
      root.appendChild(axes);
      root.appendChild(notes);
      el.appendChild(root);

      state.root = root;
      state.title = title;
      state.subtitle = subtitle;
      state.meta = meta;
      state.stage = stage;
      state.canvas = canvas;
      state.panelOverlayBack = panelOverlayBack;
	  state.panelOverlayFront = panelOverlayFront;
      state.selectionOverlay = selectionOverlay;
      state.empty = empty;
      state.tooltip = tooltip;
      state.axes = axes;
      state.notes = notes;
      state.selectionControls = selectionControls;
      state.selectionStatus = selectionStatus;
      state.timelineControls = timeline;

      ensureWidgetLayout();

      bindInteractionHandlers();
      bindSelectionModeHandlers();
      bindTimelineHandlers();
    }

    function interactionList(x) {
      return x && x.webgl ? x.webgl.interactions : [];
    }

    function renderingMode(x) {
      return x && x.webgl && x.webgl.rendering
        ? x.webgl.rendering
        : "visualization";
    }

    function publicationMode(x) {
      return renderingMode(x) === "publication";
    }

    function panelOverlayMode(x) {
      return x && x.webgl && x.webgl.panel_overlay
        ? x.webgl.panel_overlay
        : "auto";
    }

    function shouldShowPanelOverlay(x, boxes) {
      var mode = panelOverlayMode(x);

      if (mode === "show") {
        return true;
      }

      if (mode === "hide") {
        return false;
      }

      return boxes.length > 1 || boxes.some(function(box) {
        return !!(box.panel && box.panel.label);
      });
    }

    function hasInteraction(x, name) {
      return interactionList(x).indexOf(name) !== -1;
    }

    function sceneDimension(x) {
      return x && x.render && (x.render.dimension === "3d" || x.render.coordinate_system === "cartesian3d") ? "3d" : "2d";
    }

    function sceneProjection(x) {
      return x && x.webgl && x.webgl.projection === "perspective" ? "perspective" : "orthographic";
    }

    function depthTestEnabled(x) {
      return sceneDimension(x) === "3d" && x && x.webgl && x.webgl.depth_test !== false;
    }

    function blendMode(x) {
      var mode = x && x.webgl ? String(x.webgl.blend_mode || "auto").toLowerCase() : "auto";
      return ["auto", "alpha", "additive", "premultiplied"].indexOf(mode) === -1 ? "auto" : mode;
    }

    function sceneTimeline(x) {
      return x && x.render ? (x.render.timeline || (x.webgl && x.webgl.timeline) || null) : null;
    }

    function uniqueSortedTimelineValues(values, source) {
      var seen = {};
      return normalizeNumberArray(values)
        .map(function(value) { return source === "frame" ? Math.round(value) : value; })
        .filter(function(value) {
          var key = source === "frame" ? String(Math.round(value)) : String(value);
          if (seen[key]) {
            return false;
          }
          seen[key] = true;
          return true;
        })
        .sort(function(a, b) { return a - b; });
    }

    function createTimelineState(spec, previous) {
      var source = spec && typeof spec === "object" ? spec : {};
      var timeline = sceneTimeline(source);
      if (!timeline) {
        return {
          values: [],
          value: null,
          index: 0,
          source: "frame",
          filter: "exact",
          playing: false,
          speed: 1,
          loop: false,
          fps: null,
          enabled: false,
          controls: false,
          lastTick: null
        };
      }
      var sourceName = String(timeline.source || (timeline.time && timeline.time.length ? "time" : "frame")).toLowerCase();
      if (["frame", "time"].indexOf(sourceName) === -1) {
        sourceName = timeline.time && timeline.time.length ? "time" : "frame";
      }
      var values = uniqueSortedTimelineValues(
        timeline.values && timeline.values.length
          ? timeline.values
          : (sourceName === "time" ? timeline.time : timeline.frames),
        sourceName
      );
      var filter = String(timeline.mode || timeline.filter || "exact").toLowerCase() === "cumulative" ? "cumulative" : "exact";
      var speed = isFinite(Number(timeline.speed)) ? Math.max(0.05, Number(timeline.speed)) : 1;
      var fps = isFinite(Number(timeline.fps)) ? Math.max(0.05, Number(timeline.fps)) : null;
      var previousValue = previous && previous.enabled ? previous.value : null;
      var index = findTimelineIndex(values, previousValue, sourceName);
      if (index < 0) {
        index = 0;
      }
      return {
        values: values,
        value: values.length ? values[index] : null,
        index: index,
        source: sourceName,
        filter: filter,
        playing: values.length > 1 && timeline.autoplay === true,
        speed: speed,
        loop: timeline.loop === true,
        fps: fps,
        enabled: values.length > 0,
        controls: timeline.controls !== false && values.length > 1,
        lastTick: null
      };
    }

    function findTimelineIndex(values, value, source) {
      if (!Array.isArray(values) || !values.length || value === null || value === undefined) {
        return -1;
      }
      var target = Number(value);
      if (!isFinite(target)) {
        return -1;
      }
      for (var i = 0; i < values.length; i += 1) {
        if (source === "frame") {
          if (Math.round(Number(values[i])) === Math.round(target)) {
            return i;
          }
        } else if (Math.abs(Number(values[i]) - target) < 1e-9) {
          return i;
        }
      }
      return -1;
    }

    function setTimelineIndex(timeline, index) {
      if (!timeline || !timeline.enabled || !timeline.values.length) {
        return null;
      }
      var nextIndex = Math.max(0, Math.min(timeline.values.length - 1, Math.floor(Number(index)) || 0));
      timeline.index = nextIndex;
      timeline.value = timeline.values[nextIndex];
      return timeline.value;
    }

    function setTimelineValue(timeline, value) {
      if (!timeline || !timeline.enabled) {
        return null;
      }
      var idx = findTimelineIndex(timeline.values, value, timeline.source);
      if (idx < 0) {
        idx = 0;
      }
      return setTimelineIndex(timeline, idx);
    }

    function currentTimelineFrame(x) {
      return state.timeline && state.timeline.enabled ? state.timeline.value : null;
    }

    function buildTimelinePayload(timeline, reason) {
      if (!timeline || !timeline.enabled) {
        return null;
      }

      var payload = {
        value: timeline.value,
        index: Number(timeline.index || 0) + 1,
        playing: timeline.playing === true,
        speed: isFinite(Number(timeline.speed)) ? Number(timeline.speed) : 1,
        loop: timeline.loop === true,
        source: timeline.source === "time" ? "time" : "frame",
        filter: timeline.filter === "cumulative" ? "cumulative" : "exact"
      };

      if (reason) {
        payload.reason = String(reason);
      }

      return payload;
    }

    function emitTimelineState(el, state, reason) {
      if (!el || !el.id || !state || !state.timeline || !state.timeline.enabled) {
        return;
      }
      if (!(window.Shiny && typeof window.Shiny.setInputValue === "function")) {
        return;
      }

      var payload = buildTimelinePayload(state.timeline, reason);
      if (!payload) {
        return;
      }

      window.Shiny.setInputValue(el.id + "_timeline", payload, { priority: "event" });
    }

    function applyTimelineUpdate(message) {
      if (!state.timeline || !state.timeline.enabled) {
        return;
      }

      var changed = false;
      var incoming = message && typeof message === "object" ? message : {};

      if (incoming.index !== undefined && incoming.index !== null) {
        setTimelineIndex(state.timeline, Number(incoming.index) - 1);
        changed = true;
      } else if (incoming.value !== undefined && incoming.value !== null) {
        setTimelineValue(state.timeline, incoming.value);
        changed = true;
      }

      if (incoming.speed !== undefined && incoming.speed !== null) {
        var nextSpeed = Number(incoming.speed);
        if (isFinite(nextSpeed) && nextSpeed > 0) {
          state.timeline.speed = Math.max(0.05, nextSpeed);
          changed = true;
        }
      }

      if (incoming.loop !== undefined && incoming.loop !== null) {
        state.timeline.loop = incoming.loop === true;
        changed = true;
      }

      if (incoming.playing !== undefined && incoming.playing !== null) {
        state.timeline.playing = incoming.playing === true;
        state.timeline.lastTick = null;
        changed = true;
      }

      if (!changed) {
        return;
      }

      redrawCurrent();
      emitTimelineState(el, state, "update");
      if (state.timeline.playing) {
        scheduleTimelineTick();
      }
    }

    function registerShinyTimelineHandler() {
      if (typeof window === "undefined") {
        return;
      }

      var registry = window.ggWebGLTimelineRegistry || { instances: {}, handlerRegistered: false };
      registry.instances = registry.instances || {};
      if (el.id) {
        registry.instances[el.id] = {
          updateTimeline: applyTimelineUpdate
        };
      }
      window.ggWebGLTimelineRegistry = registry;

      if (registry.handlerRegistered || !(window.Shiny && typeof window.Shiny.addCustomMessageHandler === "function")) {
        return;
      }

      window.Shiny.addCustomMessageHandler(TIMELINE_UPDATE_MESSAGE_TYPE, function(message) {
        var incoming = message && typeof message === "object" ? message : {};
        var id = incoming.id || incoming.outputId;
        var currentRegistry = window.ggWebGLTimelineRegistry;
        var instance = id && currentRegistry && currentRegistry.instances ? currentRegistry.instances[id] : null;
        if (instance && typeof instance.updateTimeline === "function") {
          instance.updateTimeline(incoming);
        }
      });
      registry.handlerRegistered = true;
    }

    function layerHasTimelineValues(layer, timeline) {
      if (!timeline || !timeline.enabled || !layer) {
        return false;
      }
      if (timeline.source === "time") {
        return (Array.isArray(layer.time) && layer.time.length) || (Array.isArray(layer.frame) && layer.frame.length);
      }
      return (Array.isArray(layer.frame) && layer.frame.length) || (Array.isArray(layer.time) && layer.time.length);
    }

    function getTimelineValue(layer, rowOrVertexIndex, timeline) {
      if (!timeline || !timeline.enabled || !layer) {
        return null;
      }
      var preferred = timeline.source === "time" ? layer.time : layer.frame;
      var fallback = timeline.source === "time" ? layer.frame : layer.time;
      var value;
      if (Array.isArray(preferred) && rowOrVertexIndex < preferred.length) {
        value = Number(preferred[rowOrVertexIndex]);
      } else if (Array.isArray(fallback) && rowOrVertexIndex < fallback.length) {
        value = Number(fallback[rowOrVertexIndex]);
      } else {
        return null;
      }
      if (!isFinite(value)) {
        return null;
      }
      return timeline.source === "frame" ? Math.round(value) : value;
    }

    function isTimelineVisible(value, timeline) {
      if (!timeline || !timeline.enabled || value === null || value === undefined) {
        return true;
      }
      var current = Number(timeline.value);
      var candidate = Number(value);
      if (!isFinite(current) || !isFinite(candidate)) {
        return true;
      }
      if (timeline.filter === "cumulative") {
        return timeline.source === "frame"
          ? Math.round(candidate) <= Math.round(current)
          : candidate <= current + 1e-9;
      }
      return timeline.source === "frame"
        ? Math.round(candidate) === Math.round(current)
        : Math.abs(candidate - current) < 1e-9;
    }

    function layerIndexVisible(layer, index, x) {
      var timeline = state.timeline;
      if (!timeline || !timeline.enabled || !layerHasTimelineValues(layer, timeline)) {
        return true;
      }
      var value = getTimelineValue(layer, index, timeline);
      return value === null ? false : isTimelineVisible(value, timeline);
    }

    function pathIndexVisible(path, index, x) {
      var timeline = state.timeline;
      if (!timeline || !timeline.enabled || !layerHasTimelineValues(path, timeline)) {
        return true;
      }
      var value = getTimelineValue(path, index, timeline);
      return value === null ? false : isTimelineVisible(value, timeline);
    }

    function pathSegmentVisible(path, i0, i1, x) {
      var timeline = state.timeline;
      if (!timeline || !timeline.enabled || !layerHasTimelineValues(path, timeline)) {
        return true;
      }
      var v0 = getTimelineValue(path, i0, timeline);
      var v1 = getTimelineValue(path, i1, timeline);
      if (v0 === null || v1 === null) {
        return false;
      }
      return isTimelineVisible(v0, timeline) && isTimelineVisible(v1, timeline);
    }

    function normaliseAxisRange(range, fallback) {
      var min = Number(range && range[0]);
      var max = Number(range && range[1]);

      if (!isFinite(min) || !isFinite(max)) {
        return fallback.slice();
      }

      if (max < min) {
        var tmp = min;
        min = max;
        max = tmp;
      }

      if (max === min) {
        var pad = min === 0 ? 0.5 : Math.abs(min) * 0.05;
        min -= pad;
        max += pad;
      }

      if (max - min < 1e-9) {
        var mid = (min + max) / 2;
        var epsilon = Math.max(1e-6, Math.abs(mid) * 1e-6);
        min = mid - epsilon;
        max = mid + epsilon;
      }

      return [min, max];
    }

		function linePathList(paths) {
		  if (!paths) {
			return [];
		  }
		
		  if (Array.isArray(paths)) {
			return paths;
		  }
		
		  if (typeof paths === "object") {
			return Object.keys(paths)
			  .sort(function(a, b) {
				var na = Number(a), nb = Number(b);
				if (isFinite(na) && isFinite(nb)) {
				  return na - nb;
				}
				return String(a).localeCompare(String(b));
			  })
			  .map(function(key) {
				return paths[key];
			  })
			  .filter(function(path) {
				return path && typeof path === "object";
			  });
		  }
		
		  return [];
		}


    function panelList(x) {
      return x && x.render ? x.render.panels : [];
    }

    function gridSpec(x) {
      return x && x.render ? x.render.grid : { rows: 1, cols: 1 };
    }


/* 
	function baseViewport(panel) {
	  var bounds = supportedLayerBounds(panel);
	
	  if (bounds) {
		var xr = normaliseAxisRange(bounds.x, [0, 1]);
		var yr = normaliseAxisRange(bounds.y, [0, 1]);
	
		var xpad = (xr[1] - xr[0]) * 0.04;
		var ypad = (yr[1] - yr[0]) * 0.04;
	
		return {
		  x: [xr[0] - xpad, xr[1] + xpad],
		  y: [yr[0] - ypad, yr[1] + ypad]
		};
	  }
	
	  var viewport = panel && panel.viewport ? panel.viewport : { x: [0, 1], y: [0, 1] };
	
	  return {
		x: normaliseAxisRange(viewport.x, [0, 1]),
		y: normaliseAxisRange(viewport.y, [0, 1])
	  };
	}
 */
 
	function baseViewport(panel) {
	  var id = String(panel && panel.panel_id !== undefined ? panel.panel_id : "default");
	  if (state.baseDomains[id]) {
		return cloneViewport(state.baseDomains[id]);
	  }
	  var bounds = supportedLayerBounds(panel);
	  var viewport;
	
	  if (bounds) {
		var xr = normaliseAxisRange(bounds.x, [0, 1]);
		var yr = normaliseAxisRange(bounds.y, [0, 1]);
	
		var xpad = (xr[1] - xr[0]) * 0.04;
		var ypad = (yr[1] - yr[0]) * 0.04;
	
		viewport = {
		  x: [xr[0] - xpad, xr[1] + xpad],
		  y: [yr[0] - ypad, yr[1] + ypad]
		};
	  } else {
		var fallbackViewport = panel && panel.viewport ? panel.viewport : { x: [0, 1], y: [0, 1] };
		viewport = {
		  x: normaliseAxisRange(fallbackViewport.x, [0, 1]),
		  y: normaliseAxisRange(fallbackViewport.y, [0, 1])
		};
	  }
	  state.baseDomains[id] = cloneViewport(viewport);
	  return cloneViewport(viewport);
	}
 
 
    function cloneViewport(viewport) {
      return {
        x: viewport.x.slice(),
        y: viewport.y.slice()
      };
    }

    function panelById(x, panelId) {
      var panels = panelList(x);
      var id = String(panelId);

      for (var i = 0; i < panels.length; i += 1) {
        if (String(panels[i].panel_id) === id) {
          return panels[i];
        }
      }

      return null;
    }

    function currentViewport(panel) {
      var stored = state.viewDomains[String(panel.panel_id)];

      if (stored) {
        return cloneViewport(stored);
      }

      return baseViewport(panel);
    }

    function setViewport(panel, viewport) {
      var fallback = baseViewport(panel);

      state.viewDomains[String(panel.panel_id)] = {
        x: normaliseAxisRange(viewport.x, fallback.x),
        y: normaliseAxisRange(viewport.y, fallback.y)
      };
    }

    function resetViewport(panelId) {
      if (panelId === null || panelId === undefined) {
        state.viewDomains = {};
      } else {
        delete state.viewDomains[String(panelId)];
      }

      state.drag.active = false;
      state.drag.panelId = null;
      state.drag.pointerId = null;
      hideTooltip();
      updateInteractionUi(state.x);
    }

    function initialiseCameraFromScene(x) {
      var camera = x && x.render && x.render.camera ? x.render.camera : null;
      var cameraState = camera && camera.state ? camera.state : (x && x.webgl ? x.webgl.camera_state : null);
      cameraState = normalizeCameraState(cameraState);
      state.camera.yaw = cameraState.yaw;
      state.camera.pitch = cameraState.pitch;
      state.camera.distance = cameraState.distance;
      state.camera.target = cameraState.target.slice();
      state.camera.rotation = cameraState.rotation.slice();
      state.camera.up = cameraState.up.slice();
      state.camera.fov = cameraState.fov;
      state.camera.near = cameraState.near;
      state.camera.far = cameraState.far;
    }

    function cameraController(x) {
      var camera = x && x.render && x.render.camera ? x.render.camera : null;
      var mode = camera ? String(camera.controller || camera.mode || "") : "";
      if (!mode && x && x.webgl && x.webgl.view) {
        mode = String(x.webgl.view.controller || "");
      }
      mode = mode.toLowerCase();
      return mode === "trackball" ? "trackball" : "orbit";
    }

    function formatNumber(value) {
      var number = Number(value);

      if (!isFinite(number)) {
        return "NA";
      }

      var magnitude = Math.abs(number);
      var digits = magnitude >= 100 ? 1 : (magnitude >= 10 ? 2 : 3);
      return number.toFixed(digits).replace(/\.?0+$/, "");
    }

    function shaderName(x) {
      return x && x.webgl ? x.webgl.shader : "default";
    }

    function lineRenderMode(x) {
      var requested = x && x.webgl ? x.webgl.line_mode : "auto";
      var total = x && x.render ? Number(x.render.line_vertex_count || 0) : 0;

      if (!isFinite(total)) {
        total = 0;
      }

      if (sceneDimension(x) === "3d" || currentTimelineFrame(x) !== null) {
        return sceneDimension(x) === "3d" ? "native" : "quad";
      }

      return requested === "auto" ? (total <= 100000 ? "quad" : "native") : requested;
    }

    function lineJoinMode(x) {
      return x && x.webgl ? x.webgl.line_join : "bevel";
    }

    function lineCapMode(x) {
      return x && x.webgl ? x.webgl.line_cap : "round";
    }

    function shaderModeForLayer(x, layerType) {
      var shader = shaderName(x);

      if (layerType === "points" && shader === "density_splat") {
        return 1;
      }

      if (layerType === "lines" && shader === "trajectory_age") {
        return 2;
      }

      if (layerType === "lines" && shader === "trajectory_age_glow") {
        return 3;
      }

      if (layerType === "lines" && shader === "trajectory_velocity") {
        return 4;
      }

      if (layerType === "lines" && shader === "trajectory_direction") {
        return 5;
      }

      return 0;
    }

    function hideTooltip() {
      if (!state.tooltip) {
        return;
      }

      state.tooltip.innerHTML = "";
      state.tooltip.style.display = "none";
    }

    function showTooltip(html, clientX, clientY) {
      if (!state.tooltip || !state.stage || publicationMode(state.x)) {
        return;
      }

      var stageRect = getStageRect();

      state.tooltip.innerHTML = html;
      state.tooltip.style.display = "block";

      var tooltipRect = state.tooltip.getBoundingClientRect();
      var left = Math.max(10, clientX - stageRect.left + 14);
      var top = Math.max(10, clientY - stageRect.top + 14);
      left = Math.min(left, Math.max(10, stageRect.width - tooltipRect.width - 10));
      top = Math.min(top, Math.max(10, stageRect.height - tooltipRect.height - 10));

      state.tooltip.style.left = left + "px";
      state.tooltip.style.top = top + "px";
    }

    function hoverHtml(target) {
      var title = "Trajectory sample";
      if (target.type === "point") {
        title = "Point sample";
      } else if (target.type === "mesh_vertex") {
        title = "Mesh vertex";
      } else if (target.type === "mesh_face") {
        title = "Mesh face";
      }
      var lines = [
        "<div class='ggwebgl__tooltip-title'>" +
          escapeHtml(title) +
          "</div>"
      ];

      if (target.panelLabel) {
        lines.push("<div><strong>panel</strong>: " + escapeHtml(target.panelLabel) + "</div>");
      }

      if (target.label) {
        lines.push("<div><strong>sample</strong>: " + escapeHtml(target.label) + "</div>");
      }

      lines.push("<div><strong>x</strong>: " + escapeHtml(formatNumber(target.x)) + "</div>");
      lines.push("<div><strong>y</strong>: " + escapeHtml(formatNumber(target.y)) + "</div>");
      if (isFinite(target.z)) {
        lines.push("<div><strong>z</strong>: " + escapeHtml(formatNumber(target.z)) + "</div>");
      }
      if (target.id) {
        lines.push("<div><strong>id</strong>: " + escapeHtml(target.id) + "</div>");
      }
      if (isFinite(target.face_index)) {
        lines.push("<div><strong>face</strong>: " + escapeHtml(String(target.face_index)) + "</div>");
      }

      if (target.group) {
        lines.push("<div><strong>group</strong>: " + escapeHtml(target.group) + "</div>");
      }

      if (target.type === "point") {
        lines.push("<div><strong>size</strong>: " + escapeHtml(formatNumber(target.size)) + "</div>");
      }

      if (isFinite(target.age)) {
        lines.push("<div><strong>age</strong>: " + escapeHtml(String(Math.round(target.age * 100))) + "%</div>");
      }

      return lines.join("");
    }

    function panelBoxes(x) {
      var panels = panelList(x);
      var rect = getStageRect();
      var grid = gridSpec(x);

      if (!rect.width || !rect.height || !panels.length) {
        return [];
      }

      var outerPad = Math.max(10, Math.min(18, Math.min(rect.width, rect.height) * 0.03));
      var gapX = grid.cols > 1 ? Math.max(8, Math.min(18, rect.width * 0.02)) : 0;
      var gapY = grid.rows > 1 ? Math.max(8, Math.min(18, rect.height * 0.03)) : 0;
      var cellWidth = Math.max(24, (rect.width - 2 * outerPad - (grid.cols - 1) * gapX) / grid.cols);
      var cellHeight = Math.max(24, (rect.height - 2 * outerPad - (grid.rows - 1) * gapY) / grid.rows);

      return panels.map(function(panel) {
        var row = Math.max(1, Number(panel.row) || 1);
        var col = Math.max(1, Number(panel.col) || 1);
        var left = outerPad + (col - 1) * (cellWidth + gapX);
        var top = outerPad + (row - 1) * (cellHeight + gapY);
        var widthPx = cellWidth;
        var heightPx = cellHeight;
        var stripHeight = panel.label ? Math.max(18, Math.min(28, heightPx * 0.15)) : 0;
        var inset = Math.max(5, Math.min(10, Math.min(widthPx, heightPx) * 0.05));
        var plotLeft = left + inset;
        var plotTop = top + stripHeight + inset * 0.6;
        var plotRight = left + widthPx - inset;
        var plotBottom = top + heightPx - inset;

        if (plotBottom <= plotTop) {
          plotTop = top + stripHeight + 4;
          plotBottom = top + heightPx - 4;
        }

        return {
          panel: panel,
          left: left,
          top: top,
          width: widthPx,
          height: heightPx,
          stripHeight: stripHeight,
          plotLeft: plotLeft,
          plotTop: plotTop,
          plotRight: plotRight,
          plotBottom: plotBottom,
          plotWidth: Math.max(1, plotRight - plotLeft),
          plotHeight: Math.max(1, plotBottom - plotTop)
        };
      });
    }

    function panelBoxById(x, panelId) {
      var id = String(panelId);
      var boxes = panelBoxes(x);

      for (var i = 0; i < boxes.length; i += 1) {
        if (String(boxes[i].panel.panel_id) === id) {
          return boxes[i];
        }
      }

      return null;
    }

    function panelAtClient(clientX, clientY, x, requirePlotArea) {
      var rect = getStageRect();

      if (!rect.width || !rect.height) {
        return null;
      }

      var localX = clientX - rect.left;
      var localY = clientY - rect.top;
      var boxes = panelBoxes(x);

      for (var i = 0; i < boxes.length; i += 1) {
        var box = boxes[i];
        var inside = requirePlotArea
          ? localX >= box.plotLeft && localX <= box.plotRight && localY >= box.plotTop && localY <= box.plotBottom
          : localX >= box.left && localX <= (box.left + box.width) && localY >= box.top && localY <= (box.top + box.height);

        if (inside) {
          return box;
        }
      }

      return null;
    }

    function clientToPanelData(clientX, clientY, panel, box) {
      if (!box || !box.plotWidth || !box.plotHeight) {
        return null;
      }

      var viewport = currentViewport(panel);
      var rect = getStageRect();
      var localX = clientX - rect.left;
      var localY = clientY - rect.top;
      var fx = (localX - box.plotLeft) / box.plotWidth;
      var fy = 1 - ((localY - box.plotTop) / box.plotHeight);

      fx = Math.max(0, Math.min(1, fx));
      fy = Math.max(0, Math.min(1, fy));

      return {
        fx: fx,
        fy: fy,
        x: viewport.x[0] + fx * (viewport.x[1] - viewport.x[0]),
        y: viewport.y[0] + fy * (viewport.y[1] - viewport.y[0])
      };
    }

    function encodeMeshPickId(index) {
      var id = Math.max(0, Math.floor(Number(index)) || 0) + 1;
      return [
        ((id >> 16) & 255) / 255,
        ((id >> 8) & 255) / 255,
        (id & 255) / 255,
        1
      ];
    }

    function decodeMeshPickColor(pixel) {
      if (!pixel || pixel.length < 3) {
        return -1;
      }
      var id = (Number(pixel[0]) << 16) + (Number(pixel[1]) << 8) + Number(pixel[2]);
      return id > 0 ? id - 1 : -1;
    }

    function createMeshPickingPayload(gl, layer, viewport) {
      var vertexCount = Math.floor(Number(layer.vertex_count) || 0);
      var xs = Array.isArray(layer.x) ? layer.x : [];
      var ys = Array.isArray(layer.y) ? layer.y : [];
      var zs = Array.isArray(layer.z) ? layer.z : [];
      var indices = Array.isArray(layer.indices) ? layer.indices : [];
      var zRange = meshZRange(layer);
      var normalized = [];
      var positions = [];
      var colors = [];

      for (var i = 0; i < vertexCount; i += 1) {
        var p = normalizePosition3(xs[i], ys[i], zs[i] || 0, viewport, zRange);
        normalized.push(p[0], p[1], p[2]);
      }

      for (var t = 0; t + 2 < indices.length; t += 3) {
        var color = encodeMeshPickId(Math.floor(t / 3));
        for (var corner = 0; corner < 3; corner += 1) {
          var idx = Math.floor(Number(indices[t + corner])) || 0;
          positions.push(
            normalized[idx * 3],
            normalized[idx * 3 + 1],
            normalized[idx * 3 + 2]
          );
          colors.push(color[0], color[1], color[2], color[3]);
        }
      }

      return {
        count: Math.floor(positions.length / 3),
        positionBuffer: createBuffer(gl, new Float32Array(positions)),
        colorBuffer: createBuffer(gl, new Float32Array(colors))
      };
    }

    function disposeMeshPickingPayload(gl, payload) {
      if (!payload || !gl) {
        return;
      }
      [payload.positionBuffer, payload.colorBuffer].forEach(function(buffer) {
        if (buffer) {
          gl.deleteBuffer(buffer);
        }
      });
    }

    function pickMeshFaceWithObjectIdPass(layer, px, py, viewport, box) {
      var gl = state.gl;
      var canvas = state.canvas;
      if (!gl || !canvas || !box || !box.plotWidth || !box.plotHeight) {
        return -1;
      }
      var programs = ensurePrograms(gl);
      var pick = programs.meshPick;
      if (!pick || !pick.program) {
        return -1;
      }

      var stageRect = getStageRect();
      var scaleX = canvas.width / Math.max(1, stageRect.width);
      var scaleY = canvas.height / Math.max(1, stageRect.height);
      var width = Math.max(1, canvas.width);
      var height = Math.max(1, canvas.height);
      var framebuffer = gl.createFramebuffer();
      var texture = gl.createTexture();
      var depth = gl.createRenderbuffer();
      var payload = null;
      var pixel = new Uint8Array(4);
      var faceIndex = -1;

      try {
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

        gl.bindRenderbuffer(gl.RENDERBUFFER, depth);
        gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height);

        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depth);
        if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) {
          return -1;
        }

        var vx = Math.round(box.plotLeft * scaleX);
        var vy = Math.round((stageRect.height - box.plotBottom) * scaleY);
        var vw = Math.max(1, Math.round(box.plotWidth * scaleX));
        var vh = Math.max(1, Math.round(box.plotHeight * scaleY));
        gl.viewport(vx, vy, vw, vh);
        gl.enable(gl.SCISSOR_TEST);
        gl.scissor(vx, vy, vw, vh);
        gl.clearColor(0, 0, 0, 0);
        gl.clearDepth(1);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        gl.enable(gl.DEPTH_TEST);
        gl.depthFunc(gl.LEQUAL);

        payload = createMeshPickingPayload(gl, layer, viewport);
        if (!payload || payload.count < 3) {
          return -1;
        }
        gl.useProgram(pick.program);
        gl.uniformMatrix4fv(pick.uniforms.viewProjection, false, new Float32Array(cameraViewProjectionMatrix(state.x, box)));
        bindAttributeBuffer(gl, pick.attributes.position3, payload.positionBuffer, 3);
        bindAttributeBuffer(gl, pick.attributes.pickColor, payload.colorBuffer, 4);
        gl.drawArrays(gl.TRIANGLES, 0, payload.count);

        var readX = Math.max(0, Math.min(width - 1, Math.round((box.plotLeft + px) * scaleX)));
        var readY = Math.max(0, Math.min(height - 1, Math.round(height - ((box.plotTop + py) * scaleY))));
        gl.readPixels(readX, readY, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixel);
        faceIndex = decodeMeshPickColor(pixel);
      } catch (err) {
        faceIndex = -1;
      } finally {
        disposeMeshPickingPayload(gl, payload);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.bindTexture(gl.TEXTURE_2D, null);
        gl.bindRenderbuffer(gl.RENDERBUFFER, null);
        if (texture) {
          gl.deleteTexture(texture);
        }
        if (depth) {
          gl.deleteRenderbuffer(depth);
        }
        if (framebuffer) {
          gl.deleteFramebuffer(framebuffer);
        }
      }

      return faceIndex;
    }

    function meshVertexScreenPoint(layer, vertexIndex, viewport, box) {
      var xs = layer.x || [];
      var ys = layer.y || [];
      var zs = layer.z || [];
      var xSpan = Math.max(1e-6, viewport.x[1] - viewport.x[0]);
      var ySpan = Math.max(1e-6, viewport.y[1] - viewport.y[0]);
      var projected = sceneDimension(state.x) === "3d"
        ? project3dPoint(xs[vertexIndex], ys[vertexIndex], zs[vertexIndex] || 0, viewport, layer)
        : { x: Number(xs[vertexIndex]), y: Number(ys[vertexIndex]) };
      return {
        x: sceneDimension(state.x) === "3d"
          ? ((projected.x + 1.2) / 2.4) * box.plotWidth
          : ((projected.x - viewport.x[0]) / xSpan) * box.plotWidth,
        y: sceneDimension(state.x) === "3d"
          ? (1 - ((projected.y + 1.2) / 2.4)) * box.plotHeight
          : (1 - ((projected.y - viewport.y[0]) / ySpan)) * box.plotHeight,
        z: Number(zs[vertexIndex]) || 0,
        dataX: Number(xs[vertexIndex]),
        dataY: Number(ys[vertexIndex])
      };
    }

    function pointInScreenTriangle(px, py, a, b, c) {
      var v0x = c.x - a.x;
      var v0y = c.y - a.y;
      var v1x = b.x - a.x;
      var v1y = b.y - a.y;
      var v2x = px - a.x;
      var v2y = py - a.y;
      var dot00 = v0x * v0x + v0y * v0y;
      var dot01 = v0x * v1x + v0y * v1y;
      var dot02 = v0x * v2x + v0y * v2y;
      var dot11 = v1x * v1x + v1y * v1y;
      var dot12 = v1x * v2x + v1y * v2y;
      var denom = dot00 * dot11 - dot01 * dot01;
      if (Math.abs(denom) < 1e-9) {
        return false;
      }
      var inv = 1 / denom;
      var u = (dot11 * dot02 - dot01 * dot12) * inv;
      var v = (dot00 * dot12 - dot01 * dot02) * inv;
      return u >= -0.001 && v >= -0.001 && (u + v) <= 1.001;
    }

    function pickMeshFaceAt(layer, px, py, viewport, box) {
      var indices = layer.indices || [];
      var pickIds = layer.pick_id || [];
      var best = null;
      var pickedFace = pickMeshFaceWithObjectIdPass(layer, px, py, viewport, box);
      if (pickedFace >= 0 && pickedFace * 3 + 2 < indices.length) {
        var offset = pickedFace * 3;
        var pa = meshVertexScreenPoint(layer, indices[offset], viewport, box);
        var pb = meshVertexScreenPoint(layer, indices[offset + 1], viewport, box);
        var pc = meshVertexScreenPoint(layer, indices[offset + 2], viewport, box);
        return {
          dist2: 0,
          type: "mesh_face",
          x: (pa.dataX + pb.dataX + pc.dataX) / 3,
          y: (pa.dataY + pb.dataY + pc.dataY) / 3,
          z: (pa.z + pb.z + pc.z) / 3,
          id: pickIds[pickedFace] || String(pickedFace),
          face_index: pickedFace
        };
      }
      for (var t = 0; t + 2 < indices.length; t += 3) {
        var ia = Number(indices[t]);
        var ib = Number(indices[t + 1]);
        var ic = Number(indices[t + 2]);
        if (!isFinite(ia) || !isFinite(ib) || !isFinite(ic)) {
          continue;
        }
        var a = meshVertexScreenPoint(layer, ia, viewport, box);
        var b = meshVertexScreenPoint(layer, ib, viewport, box);
        var c = meshVertexScreenPoint(layer, ic, viewport, box);
        if (!pointInScreenTriangle(px, py, a, b, c)) {
          continue;
        }
        var cx = (a.x + b.x + c.x) / 3;
        var cy = (a.y + b.y + c.y) / 3;
        var dist2 = (px - cx) * (px - cx) + (py - cy) * (py - cy);
        if (!best || dist2 < best.dist2) {
          var faceIndex = Math.floor(t / 3);
          best = {
            dist2: dist2,
            type: "mesh_face",
            x: (a.dataX + b.dataX + c.dataX) / 3,
            y: (a.dataY + b.dataY + c.dataY) / 3,
            z: (a.z + b.z + c.z) / 3,
            id: pickIds[faceIndex] || String(faceIndex),
            face_index: faceIndex
          };
        }
      }
      return best;
    }

    function pickSceneTarget(clientX, clientY, panel, box) {
      var layers = Array.isArray(panel.layers) ? panel.layers : [];
      var viewport = currentViewport(panel);
      var rect = getStageRect();
      var localX = clientX - rect.left;
      var localY = clientY - rect.top;
      var px = localX - box.plotLeft;
      var py = localY - box.plotTop;
      var xSpan = Math.max(1e-6, viewport.x[1] - viewport.x[0]);
      var ySpan = Math.max(1e-6, viewport.y[1] - viewport.y[0]);
      var best = null;

      layers.forEach(function(layer) {
        if (layer.type === "points") {
          var count = layer.rows || 0;
          var xs = layer.x || [];
          var ys = layer.y || [];
          var sizes = layer.size || [];
          var ages = layer.age || [];
          var labels = layer.label || [];

          for (var i = 0; i < count; i += 1) {
            var sx = ((xs[i] - viewport.x[0]) / xSpan) * box.plotWidth;
            var sy = (1 - ((ys[i] - viewport.y[0]) / ySpan)) * box.plotHeight;
            var dx = px - sx;
            var dy = py - sy;
            var threshold = Math.max(8, (sizes[i] || 4) * 0.7 + 6);
            var dist2 = dx * dx + dy * dy;

            if (dist2 <= threshold * threshold && (!best || dist2 < best.dist2)) {
              best = {
                dist2: dist2,
                type: "point",
                x: xs[i],
                y: ys[i],
                size: sizes[i] || 0,
                age: isFinite(ages[i]) ? ages[i] : 1,
                label: labels[i] || "",
                panelLabel: panel.label || ("Panel " + panel.panel_id)
              };
            }
          }
        } else if (layer.type === "lines") {
          var paths = linePathList(layer.paths);

          paths.forEach(function(path) {
            var xs = path.x || [];
            var ys = path.y || [];
            var ages = path.age || [];

            var n = Math.min(
              Array.isArray(path.x) ? path.x.length : 0,
              Array.isArray(path.y) ? path.y.length : 0
            );

            for (var i = 0; i < n; i += 1) {
              var sx = ((xs[i] - viewport.x[0]) / xSpan) * box.plotWidth;
              var sy = (1 - ((ys[i] - viewport.y[0]) / ySpan)) * box.plotHeight;
              var dx = px - sx;
              var dy = py - sy;
              var threshold = Math.max(7, (path.width || 1) * 4 + 4);
              var dist2 = dx * dx + dy * dy;

              if (dist2 <= threshold * threshold && (!best || dist2 < best.dist2)) {
                best = {
                  dist2: dist2,
                  type: "line",
                  x: xs[i],
                  y: ys[i],
                  group: path.group || "",
                  age: isFinite(ages[i]) ? ages[i] : NaN,
                  panelLabel: panel.label || ("Panel " + panel.panel_id)
                };
              }
            }
          });
        } else if (layer.type === "mesh") {
          var mxs = layer.x || [];
          var mys = layer.y || [];
          var mzs = layer.z || [];
          var mids = layer.id || [];
          var face = pickMeshFaceAt(layer, px, py, viewport, box);
          if (face && (!best || face.dist2 < best.dist2)) {
            best = Object.assign(face, {
              panelLabel: panel.label || ("Panel " + panel.panel_id)
            });
          }
          for (var m = 0; m < layer.vertex_count; m += 1) {
            var vertex = meshVertexScreenPoint(layer, m, viewport, box);
            var msx = vertex.x;
            var msy = vertex.y;
            var mdx = px - msx;
            var mdy = py - msy;
            var mdist2 = mdx * mdx + mdy * mdy;
            if (mdist2 <= 100 && (!best || mdist2 < best.dist2)) {
              best = {
                dist2: mdist2,
                type: "mesh_vertex",
                x: mxs[m],
                y: mys[m],
                z: mzs[m] || 0,
                id: mids[m] || String(m),
                panelLabel: panel.label || ("Panel " + panel.panel_id)
              };
            }
          }
        }
      });

      return best;
    }

    function emitSelection(payload) {
      payload = payload || {};
      el.ggwebglLastSelection = payload;
      var selection = state.x && state.x.webgl ? state.x.webgl.selection : null;
      if (selection && selection.emit === false) {
        return;
      }
      if (window.Shiny && typeof window.Shiny.setInputValue === "function" && el.id) {
        window.Shiny.setInputValue(el.id + "_selection", payload, { priority: "event" });
      }
      if (state.x && state.x.webgl && state.x.webgl.extra && typeof state.x.webgl.extra.on_selection === "function") {
        state.x.webgl.extra.on_selection(payload);
      }
    }

    function pointInPolygon(x, y, polygon) {
      var inside = false;
      for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
        var xi = polygon[i].x, yi = polygon[i].y;
        var xj = polygon[j].x, yj = polygon[j].y;
        var intersect = ((yi > y) !== (yj > y)) &&
          (x < (xj - xi) * (y - yi) / Math.max(1e-9, yj - yi) + xi);
        if (intersect) {
          inside = !inside;
        }
      }
      return inside;
    }

    function selectionModes(x) {
      var selection = x && x.webgl ? x.webgl.selection : null;
      if (selection && selection.mode) {
        return {
          brush: selection.mode === "brush" || selection.mode === "brush_lasso",
          lasso: selection.mode === "lasso" || selection.mode === "brush_lasso"
        };
      }
      return {
        brush: hasInteraction(x, "brush"),
        lasso: hasInteraction(x, "lasso")
      };
    }

    function activeSelectionMode(x) {
      var modes = selectionModes(x);
      if (modes.brush && modes.lasso) {
        return state.selection.modePreference === "lasso" ? "lasso" : "brush";
      }
      if (modes.brush) {
        return "brush";
      }
      if (modes.lasso) {
        return "lasso";
      }
      return null;
    }

    function dataToStagePoint(xValue, yValue, panel, box) {
      var viewport = currentViewport(panel);
      var xSpan = Math.max(1e-6, viewport.x[1] - viewport.x[0]);
      var ySpan = Math.max(1e-6, viewport.y[1] - viewport.y[0]);
      return {
        x: box.plotLeft + ((Number(xValue) - viewport.x[0]) / xSpan) * box.plotWidth,
        y: box.plotTop + (1 - ((Number(yValue) - viewport.y[0]) / ySpan)) * box.plotHeight
      };
    }

    function stageToDataPoint(stageX, stageY, panel, box) {
      var viewport = currentViewport(panel);
      var xSpan = Math.max(1e-6, viewport.x[1] - viewport.x[0]);
      var ySpan = Math.max(1e-6, viewport.y[1] - viewport.y[0]);
      return {
        x: viewport.x[0] + ((stageX - box.plotLeft) / Math.max(1, box.plotWidth)) * xSpan,
        y: viewport.y[0] + (1 - ((stageY - box.plotTop) / Math.max(1, box.plotHeight))) * ySpan
      };
    }

    function rectangleToRegion(rectangle, panel, box) {
      if (!rectangle || !panel || !box) {
        return null;
      }
      var a = stageToDataPoint(rectangle.left, rectangle.top, panel, box);
      var b = stageToDataPoint(rectangle.right, rectangle.bottom, panel, box);
      var x0 = Math.min(a.x, b.x);
      var x1 = Math.max(a.x, b.x);
      var y0 = Math.min(a.y, b.y);
      var y1 = Math.max(a.y, b.y);
      if (!(x1 > x0) || !(y1 > y0)) {
        return null;
      }
      return { x: [x0, x1], y: [y0, y1] };
    }

    function regionToRectangle(region, panel, box) {
      if (!region || !Array.isArray(region.x) || !Array.isArray(region.y)) {
        return null;
      }
      var a = dataToStagePoint(region.x[0], region.y[0], panel, box);
      var b = dataToStagePoint(region.x[1], region.y[1], panel, box);
      return {
        left: Math.min(a.x, b.x),
        right: Math.max(a.x, b.x),
        top: Math.min(a.y, b.y),
        bottom: Math.max(a.y, b.y)
      };
    }

    function polygonBounds(polygon) {
      if (!polygon || !polygon.length) {
        return null;
      }
      var xs = polygon.map(function(point) { return point.x; });
      var ys = polygon.map(function(point) { return point.y; });
      return {
        left: Math.min.apply(null, xs),
        right: Math.max.apply(null, xs),
        top: Math.min.apply(null, ys),
        bottom: Math.max.apply(null, ys)
      };
    }

    function magnifierLinks(x) {
      var links = x && x.render && x.render.links ? x.render.links : {};
      return Array.isArray(links.magnifiers) ? links.magnifiers : [];
    }

    function applyMagnifierRegion(sourcePanelId, region) {
      if (!region) {
        return false;
      }
      var changed = false;
      magnifierLinks(state.x).forEach(function(link) {
        if (String(link.source_panel) !== String(sourcePanelId)) {
          return;
        }
        var target = panelById(state.x, link.target_panel);
        if (!target) {
          return;
        }
        setViewport(target, {
          x: region.x.slice(),
          y: region.y.slice()
        });
        el.ggwebglLastMagnifierRegion = {
          source_panel: sourcePanelId,
          target_panel: link.target_panel,
          region: { x: region.x.slice(), y: region.y.slice() }
        };
        changed = true;
      });
      return changed;
    }

    function selectedCount(selections) {
      return (Array.isArray(selections) ? selections : []).reduce(function(total, selection) {
        return total + (Number(selection.count) || (selection.ids ? selection.ids.length : 0));
      }, 0);
    }

    function updateSelectionStatus() {
      if (!state.selectionStatus) {
        return;
      }
      var enabled = state.x && !publicationMode(state.x) && activeSelectionMode(state.x);
      if (!enabled) {
        state.selectionStatus.textContent = "";
        return;
      }
      if (state.selection.result) {
        state.selectionStatus.textContent = selectedCount(state.selection.result.selections) + " selected";
      } else {
        state.selectionStatus.textContent = "Drag to select samples";
      }
    }

    function escapeSvgAttr(value) {
      return escapeHtml(value).replace(/`/g, "&#96;");
    }

    function renderSelectionOverlay() {
      if (!state.selectionOverlay) {
        return;
      }
      var geometry = null;
      var panel = null;
      var box = null;
      if (state.selection.active) {
        var stageRect = getStageRect();
        var sx0 = state.selection.startClientX - stageRect.left;
        var sy0 = state.selection.startClientY - stageRect.top;
        var sx1 = state.selection.currentClientX - stageRect.left;
        var sy1 = state.selection.currentClientY - stageRect.top;
        if (state.selection.mode === "brush") {
          geometry = {
            mode: "brush",
            rectangle: {
              left: Math.min(sx0, sx1),
              right: Math.max(sx0, sx1),
              top: Math.min(sy0, sy1),
              bottom: Math.max(sy0, sy1)
            }
          };
        } else {
          geometry = {
            mode: "lasso",
            polygon: state.selection.points.map(function(point) {
              return { x: point.x - stageRect.left, y: point.y - stageRect.top };
            })
          };
        }
      } else if (state.selection.result) {
        panel = panelById(state.x, state.selection.result.panel_id);
        box = panelBoxById(state.x, state.selection.result.panel_id);
        if (panel && box && state.selection.result.mode === "brush") {
          geometry = {
            mode: "brush",
            rectangle: regionToRectangle(state.selection.result.region, panel, box)
          };
        } else if (state.selection.result.overlay) {
          geometry = state.selection.result.overlay;
        }
      }

      if (!geometry) {
        state.selectionOverlay.innerHTML = "";
        return;
      }

      var markup = "";
      if (geometry.mode === "brush" && geometry.rectangle) {
        var rect = geometry.rectangle;
        markup = "<rect x='" + escapeSvgAttr(rect.left) +
          "' y='" + escapeSvgAttr(rect.top) +
          "' width='" + escapeSvgAttr(Math.max(1, rect.right - rect.left)) +
          "' height='" + escapeSvgAttr(Math.max(1, rect.bottom - rect.top)) +
          "' fill='rgba(37,99,235,0.10)' stroke='rgba(30,64,175,0.86)' stroke-width='1.5' vector-effect='non-scaling-stroke'/>";
      } else if (geometry.mode === "lasso" && geometry.polygon && geometry.polygon.length) {
        var points = geometry.polygon.map(function(point) {
          return point.x + "," + point.y;
        }).join(" ");
        markup = "<polyline points='" + escapeSvgAttr(points) +
          "' fill='rgba(37,99,235,0.08)' stroke='rgba(30,64,175,0.86)' stroke-width='1.5' vector-effect='non-scaling-stroke'/>";
      }

      state.selectionOverlay.innerHTML = markup
        ? "<svg aria-hidden='true' focusable='false'>" + markup + "</svg>"
        : "";
    }

    function collectSelection(panel, box, polygon, rectangle) {
      var layers = Array.isArray(panel.layers) ? panel.layers : [];
      var viewport = currentViewport(panel);
      var xSpan = Math.max(1e-6, viewport.x[1] - viewport.x[0]);
      var ySpan = Math.max(1e-6, viewport.y[1] - viewport.y[0]);
      var out = [];

      function dataToScreen(xValue, yValue) {
        return {
          x: box.plotLeft + ((xValue - viewport.x[0]) / xSpan) * box.plotWidth,
          y: box.plotTop + (1 - ((yValue - viewport.y[0]) / ySpan)) * box.plotHeight
        };
      }

      function contains(point) {
        if (rectangle) {
          return point.x >= rectangle.left && point.x <= rectangle.right &&
            point.y >= rectangle.top && point.y <= rectangle.bottom;
        }
        return polygon && polygon.length >= 3 && pointInPolygon(point.x, point.y, polygon);
      }

      layers.forEach(function(layer, layerIndex) {
        if (layer.type === "points") {
          var indices = [];
          var ids = [];
          for (var i = 0; i < layer.rows; i += 1) {
            if (!layerIndexVisible(layer, i, state.x)) {
              continue;
            }
            var point = dataToScreen(Number(layer.x[i]), Number(layer.y[i]));
            if (contains(point)) {
              indices.push(i);
              ids.push(layer.id && layer.id[i] ? layer.id[i] : String(i));
            }
          }
          if (indices.length) {
            out.push({
              panel_id: panel.panel_id,
              layer_index: layerIndex,
              geom: layer.geom || "points",
              type: "points",
              count: indices.length,
              indices: indices,
              ids: ids
            });
          }
        } else if (layer.type === "vectors") {
          var vectorIndices = [];
          var vectorIds = [];
          for (var j = 0; j < layer.rows; j += 1) {
            if (!layerIndexVisible(layer, j, state.x)) {
              continue;
            }
            var anchor = dataToScreen(Number(layer.x[j]), Number(layer.y[j]));
            if (contains(anchor)) {
              vectorIndices.push(j);
              vectorIds.push(layer.id && layer.id[j] ? layer.id[j] : String(j));
            }
          }
          if (vectorIndices.length) {
            out.push({
              panel_id: panel.panel_id,
              layer_index: layerIndex,
              geom: layer.geom || "vectors",
              type: "vectors",
              count: vectorIndices.length,
              indices: vectorIndices,
              ids: vectorIds
            });
          }
        }
      });

      return out;
    }

    function refreshHover(clientX, clientY) {
      if (!state.x || !hasInteraction(state.x, "hover")) {
        hideTooltip();
        return;
      }

      state.hover.clientX = clientX;
      state.hover.clientY = clientY;

      var box = panelAtClient(clientX, clientY, state.x, true);

      if (!box) {
        hideTooltip();
        return;
      }

      state.hover.panelId = box.panel.panel_id;

      var target = pickSceneTarget(clientX, clientY, box.panel, box);

      if (!target) {
        hideTooltip();
        return;
      }

      showTooltip(hoverHtml(target), clientX, clientY);
    }

    function applyRenderingModeUi(x) {
      var publication = publicationMode(x);

      state.root.classList.toggle("ggwebgl--publication", publication);
      state.root.classList.toggle("ggwebgl--visualization", !publication);
      state.root.classList.toggle("ggwebgl--panel-overlay-visible", shouldShowPanelOverlay(x, panelBoxes(x)));
      state.stage.tabIndex = publication ? -1 : 0;
    }

    function updateInteractionUi(x) {
      var canPan = hasInteraction(x, "pan");
      var canZoom = hasInteraction(x, "zoom");
      var canHover = hasInteraction(x, "hover");
      var canBrush = hasInteraction(x, "brush");
      var canLasso = hasInteraction(x, "lasso");
      var hints = [];
      var publication = publicationMode(x);

      state.root.classList.toggle("ggwebgl--pan-enabled", !publication && canPan);
      state.root.classList.toggle("ggwebgl--zoom-enabled", canZoom);
      state.root.classList.toggle("ggwebgl--hover-enabled", !publication && canHover);
      state.root.classList.toggle("ggwebgl--selection-enabled", !publication && (canBrush || canLasso));
      state.root.classList.toggle("ggwebgl--dragging", !!state.drag.active);

      if (canPan) {
        hints.push("drag to pan");
      }

      if (canZoom) {
        hints.push("scroll to zoom");
        hints.push("double-click to reset");
      }

      if (canHover) {
        hints.push("move to inspect nearby samples");
      }
      if (canBrush) {
        hints.push("drag to brush-select samples");
      }
      if (canLasso) {
        hints.push("drag to lasso-select samples");
      }

      state.stage.title = publication || !hints.length
        ? ""
        : "Interactive controls: " + hints.join(", ");

      updateSelectionUi(x);
    }

    function updateSelectionUi(x) {
      if (!state.selectionControls) {
        return;
      }
      var modes = selectionModes(x);
      var publication = publicationMode(x);
      var showControls = !publication && modes.brush && modes.lasso;
      state.selectionControls.style.display = showControls ? "flex" : "none";
      Array.prototype.forEach.call(
        state.selectionControls.querySelectorAll(".ggwebgl__selection-mode"),
        function(button) {
          var mode = button.getAttribute("data-mode");
          button.setAttribute("aria-pressed", mode === activeSelectionMode(x) ? "true" : "false");
        }
      );
      updateSelectionStatus();
    }

    function bindSelectionModeHandlers() {
      if (!state.selectionControls || state.selectionControls.dataset.ggwebglBound === "true") {
        return;
      }
      state.selectionControls.dataset.ggwebglBound = "true";
      Array.prototype.forEach.call(
        state.selectionControls.querySelectorAll(".ggwebgl__selection-mode"),
        function(button) {
          button.addEventListener("click", function() {
            state.selection.modePreference = button.getAttribute("data-mode") === "lasso" ? "lasso" : "brush";
            updateSelectionUi(state.x);
          });
        }
      );
    }

    function timelineValues(x) {
      return state.timeline && state.timeline.enabled ? state.timeline.values.slice() : [];
    }

    function updateTimelineUi(x) {
      if (!state.timelineControls) {
        return;
      }
      var values = timelineValues(x);
      var visible = !!(state.timeline && state.timeline.controls && values.length > 1);
      el.ggwebglTimelineFrame = currentTimelineFrame(x);
      state.timelineControls.style.display = visible ? "flex" : "none";
      if (!visible) {
        return;
      }

      var scrub = state.timelineControls.querySelector(".ggwebgl__timeline-scrub");
      var play = state.timelineControls.querySelector(".ggwebgl__timeline-play");
      var speed = state.timelineControls.querySelector(".ggwebgl__timeline-speed");
      if (scrub) {
        scrub.max = String(values.length - 1);
        scrub.value = String(Math.max(0, state.timeline.index || 0));
      }
      if (play) {
        play.textContent = state.timeline.playing ? "Pause" : "Play";
      }
      if (speed) {
        speed.value = String(state.timeline.speed || 1);
      }
    }

    function bindTimelineHandlers() {
      if (!state.timelineControls || state.timelineControls.dataset.ggwebglBound === "true") {
        return;
      }
      state.timelineControls.dataset.ggwebglBound = "true";
      var play = state.timelineControls.querySelector(".ggwebgl__timeline-play");
      var scrub = state.timelineControls.querySelector(".ggwebgl__timeline-scrub");
      var speed = state.timelineControls.querySelector(".ggwebgl__timeline-speed");
      var reset = state.timelineControls.querySelector(".ggwebgl__timeline-reset");

      if (play) {
        play.addEventListener("click", function() {
          if (!state.timeline.enabled) {
            return;
          }
          state.timeline.playing = !state.timeline.playing;
          state.timeline.lastTick = null;
          updateTimelineUi(state.x);
          emitTimelineState(el, state, state.timeline.playing ? "play" : "pause");
          scheduleTimelineTick();
        });
      }
      if (scrub) {
        scrub.addEventListener("input", function() {
          if (!state.timeline.enabled) {
            return;
          }
          setTimelineIndex(state.timeline, Number(scrub.value) || 0);
          redrawCurrent();
          emitTimelineState(el, state, "scrub");
        });
      }
      if (speed) {
        speed.addEventListener("change", function() {
          if (state.timeline) {
            state.timeline.speed = Math.max(0.05, Number(speed.value) || 1);
            emitTimelineState(el, state, "speed");
          }
        });
      }
      if (reset) {
        reset.addEventListener("click", function() {
          setTimelineIndex(state.timeline, 0);
          state.timeline.playing = false;
          redrawCurrent();
          emitTimelineState(el, state, "reset");
        });
      }
    }

    function scheduleTimelineTick() {
      if (!state.timeline.playing || !state.x) {
        return;
      }
      requestAnimationFrame(function(timestamp) {
        if (!state.timeline.playing || !state.x) {
          return;
        }
        if (!state.timeline.enabled || state.timeline.values.length <= 1) {
          state.timeline.playing = false;
          updateTimelineUi(state.x);
          return;
        }
        var speed = state.timeline.speed || 1;
        if (state.timeline.lastTick === null || timestamp - state.timeline.lastTick > (500 / speed)) {
          var idx = state.timeline.index + 1;
          if (idx >= state.timeline.values.length) {
            idx = state.timeline.loop ? 0 : state.timeline.values.length - 1;
            if (!state.timeline.loop) {
              state.timeline.playing = false;
            }
          }
          setTimelineIndex(state.timeline, idx);
          state.timeline.lastTick = timestamp;
          redrawCurrent();
          emitTimelineState(el, state, "tick");
        }
        scheduleTimelineTick();
      });
    }

    function redrawCurrent() {
      if (!state.x) {
        return;
      }

      hideTooltip();
      updateLabels(state.x);
      updateTimelineUi(state.x);

      try {
        drawScene(state.x);
        renderSelectionOverlay();
        updateSelectionStatus();
      } catch (err) {
        setEmpty("Renderer error: " + escapeHtml(err.message || String(err)));
      }
    }

    function endDrag() {
      state.drag.active = false;
      state.drag.panelId = null;
      state.drag.pointerId = null;
      updateInteractionUi(state.x);
    }

    function bindInteractionHandlers() {
      if (!state.stage || state.stage.dataset.ggwebglBound === "true") {
        return;
      }

      state.stage.dataset.ggwebglBound = "true";

      state.stage.addEventListener("pointerdown", function(event) {
        if (!state.x) {
          return;
        }

        if (event.pointerType === "mouse" && event.button !== 0) {
          return;
        }

        var box = panelAtClient(event.clientX, event.clientY, state.x, true);

        if (!box) {
          return;
        }

        var selectionMode = activeSelectionMode(state.x);
        if (selectionMode) {
          state.selection.active = true;
          state.selection.mode = selectionMode;
          state.selection.panelId = box.panel.panel_id;
          state.selection.pointerId = event.pointerId;
          state.selection.points = [{ x: event.clientX, y: event.clientY }];
          state.selection.startClientX = event.clientX;
          state.selection.startClientY = event.clientY;
          state.selection.currentClientX = event.clientX;
          state.selection.currentClientY = event.clientY;
          if (state.stage.setPointerCapture) {
            state.stage.setPointerCapture(event.pointerId);
          }
          renderSelectionOverlay();
          updateSelectionStatus();
          event.preventDefault();
          return;
        }

        if (!hasInteraction(state.x, "pan")) {
          return;
        }

        state.drag.active = true;
        state.drag.panelId = box.panel.panel_id;
        state.drag.pointerId = event.pointerId;
        state.drag.lastClientX = event.clientX;
        state.drag.lastClientY = event.clientY;
        hideTooltip();

        if (state.stage.setPointerCapture) {
          state.stage.setPointerCapture(event.pointerId);
        }

        updateInteractionUi(state.x);
        event.preventDefault();
      });

      state.stage.addEventListener("pointermove", function(event) {
        if (!state.x) {
          return;
        }

        if (state.selection.active && event.pointerId === state.selection.pointerId) {
          state.selection.currentClientX = event.clientX;
          state.selection.currentClientY = event.clientY;
          if (state.selection.mode === "lasso") {
            state.selection.points.push({ x: event.clientX, y: event.clientY });
          }
          renderSelectionOverlay();
          if (state.selection.mode === "brush") {
            var liveBox = panelBoxById(state.x, state.selection.panelId);
            var livePanel = panelById(state.x, state.selection.panelId);
            if (liveBox && livePanel) {
              var liveStageRect = getStageRect();
              var liveRegion = rectangleToRegion({
                left: Math.min(state.selection.startClientX - liveStageRect.left, state.selection.currentClientX - liveStageRect.left),
                right: Math.max(state.selection.startClientX - liveStageRect.left, state.selection.currentClientX - liveStageRect.left),
                top: Math.min(state.selection.startClientY - liveStageRect.top, state.selection.currentClientY - liveStageRect.top),
                bottom: Math.max(state.selection.startClientY - liveStageRect.top, state.selection.currentClientY - liveStageRect.top)
              }, livePanel, liveBox);
              if (applyMagnifierRegion(state.selection.panelId, liveRegion)) {
                redrawCurrent();
              }
            }
          }
          event.preventDefault();
          return;
        }

        if (!state.drag.active || event.pointerId !== state.drag.pointerId) {
          if (hasInteraction(state.x, "hover")) {
            refreshHover(event.clientX, event.clientY);
          }
          return;
        }

        var panel = panelById(state.x, state.drag.panelId);
        var box = panelBoxById(state.x, state.drag.panelId);

        if (!panel || !box || !box.plotWidth || !box.plotHeight) {
          return;
        }

        var viewport = currentViewport(panel);
        var dx = event.clientX - state.drag.lastClientX;
        var dy = event.clientY - state.drag.lastClientY;
        var xSpan = viewport.x[1] - viewport.x[0];
        var ySpan = viewport.y[1] - viewport.y[0];

        state.drag.lastClientX = event.clientX;
        state.drag.lastClientY = event.clientY;

        if (!dx && !dy) {
          return;
        }

        if (sceneDimension(state.x) === "3d") {
          if (event.shiftKey) {
            panCameraTarget(dx, dy, box);
          } else if (cameraController(state.x) === "trackball") {
            applyTrackballDrag(dx, dy);
          } else {
            state.camera.yaw += dx * 0.01;
            state.camera.pitch = Math.max(-1.4, Math.min(1.4, state.camera.pitch + dy * 0.01));
            state.camera.rotation = orbitQuaternion(state.camera.yaw, state.camera.pitch);
            el.ggwebglLastCameraController = "orbit";
            el.ggwebglLastCameraState = {
              yaw: state.camera.yaw,
              pitch: state.camera.pitch,
              rotation: state.camera.rotation.slice(),
              distance: state.camera.distance
            };
          }
          redrawCurrent();
          event.preventDefault();
          return;
        }

        setViewport(panel, {
          x: [
            viewport.x[0] - (dx / box.plotWidth) * xSpan,
            viewport.x[1] - (dx / box.plotWidth) * xSpan
          ],
          y: [
            viewport.y[0] + (dy / box.plotHeight) * ySpan,
            viewport.y[1] + (dy / box.plotHeight) * ySpan
          ]
        });

        redrawCurrent();
        event.preventDefault();
      });

      state.stage.addEventListener("pointerup", function(event) {
        if (state.selection.active && event.pointerId === state.selection.pointerId) {
          var selectBox = panelBoxById(state.x, state.selection.panelId);
          var panel = panelById(state.x, state.selection.panelId);
          if (selectBox && panel) {
            var stageRect = getStageRect();
            var sx0 = state.selection.startClientX - stageRect.left;
            var sy0 = state.selection.startClientY - stageRect.top;
            var sx1 = state.selection.currentClientX - stageRect.left;
            var sy1 = state.selection.currentClientY - stageRect.top;
            var rectangle = null;
            var polygon = null;
            if (state.selection.mode === "brush") {
              rectangle = {
                left: Math.min(sx0, sx1),
                right: Math.max(sx0, sx1),
                top: Math.min(sy0, sy1),
                bottom: Math.max(sy0, sy1)
              };
            } else {
              polygon = state.selection.points.map(function(point) {
                return { x: point.x - stageRect.left, y: point.y - stageRect.top };
              });
              rectangle = polygonBounds(polygon);
            }
            var region = rectangleToRegion(rectangle, panel, selectBox);
            var selections = collectSelection(panel, selectBox, polygon, state.selection.mode === "brush" ? rectangle : null);
            var payload = {
              mode: state.selection.mode,
              panel_id: panel.panel_id,
              region: region,
              count: selectedCount(selections),
              selections: selections,
              overlay: state.selection.mode === "lasso"
                ? { mode: "lasso", polygon: polygon }
                : { mode: "brush", rectangle: rectangle }
            };
            state.selection.result = payload;
            applyMagnifierRegion(panel.panel_id, region);
            emitSelection(payload);
            updateSelectionStatus();
            redrawCurrent();
          }
          state.selection.active = false;
          state.selection.pointerId = null;
          renderSelectionOverlay();
          event.preventDefault();
          return;
        }
        if (event.pointerId === state.drag.pointerId) {
          endDrag();
        }
      });

      state.stage.addEventListener("pointercancel", function(event) {
        if (event.pointerId === state.selection.pointerId) {
          state.selection.active = false;
          state.selection.pointerId = null;
          renderSelectionOverlay();
        }
        if (event.pointerId === state.drag.pointerId) {
          endDrag();
        }
      });

      state.stage.addEventListener("lostpointercapture", function() {
        state.selection.active = false;
        state.selection.pointerId = null;
        renderSelectionOverlay();
        endDrag();
      });

      state.stage.addEventListener("pointerleave", function() {
        hideTooltip();
      });

      state.stage.addEventListener("wheel", function(event) {
        if (!state.x || !hasInteraction(state.x, "zoom")) {
          return;
        }

        var box = panelAtClient(event.clientX, event.clientY, state.x, true);

        if (!box) {
          return;
        }

        var anchor = clientToPanelData(event.clientX, event.clientY, box.panel, box);

        if (!anchor) {
          return;
        }

        var viewport = currentViewport(box.panel);
        var base = baseViewport(box.panel);
        var scale = Math.exp(Math.max(-1.5, Math.min(1.5, event.deltaY * 0.002)));

        if (sceneDimension(state.x) === "3d") {
          state.camera.distance = Math.max(0.2, Math.min(20, state.camera.distance * scale));
          redrawCurrent();
          event.preventDefault();
          return;
        }
        var newXSpan = (viewport.x[1] - viewport.x[0]) * scale;
        var newYSpan = (viewport.y[1] - viewport.y[0]) * scale;
        var maxXSpan = (base.x[1] - base.x[0]) * 1000.0;
        var maxYSpan = (base.y[1] - base.y[0]) * 1000.0;

        newXSpan = Math.min(newXSpan, maxXSpan);
        newYSpan = Math.min(newYSpan, maxYSpan);

        setViewport(box.panel, {
          x: [
            anchor.x - anchor.fx * newXSpan,
            anchor.x + (1 - anchor.fx) * newXSpan
          ],
          y: [
            anchor.y - anchor.fy * newYSpan,
            anchor.y + (1 - anchor.fy) * newYSpan
          ]
        });

        redrawCurrent();
        event.preventDefault();
      }, { passive: false });

      state.stage.addEventListener("dblclick", function(event) {
        if (!state.x || (!hasInteraction(state.x, "pan") && !hasInteraction(state.x, "zoom"))) {
          return;
        }

        var box = panelAtClient(event.clientX, event.clientY, state.x, false);

        if (sceneDimension(state.x) === "3d") {
          initialiseCameraFromScene(state.x);
        }
        resetViewport(box ? box.panel.panel_id : null);
        redrawCurrent();
        event.preventDefault();
      });
    }

    function createShader(gl, type, source) {
      var shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);

      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        var log = gl.getShaderInfoLog(shader);
        gl.deleteShader(shader);
        throw new Error(log || "Shader compilation failed.");
      }

      return shader;
    }

    function createProgram(gl, vertexSource, fragmentSource) {
      var vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexSource);
      var fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentSource);
      var program = gl.createProgram();

      gl.attachShader(program, vertexShader);
      gl.attachShader(program, fragmentShader);
      gl.linkProgram(program);

      if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        throw new Error(gl.getProgramInfoLog(program) || "Program linking failed.");
      }

      return program;
    }

    function ensurePrograms(gl) {
      if (state.programs) {
        return state.programs;
      }

      var primitiveProgram = createProgram(gl, primitiveVertexShaderSource, primitiveFragmentShaderSource);
      var primitive3dProgram = createProgram(gl, primitive3dVertexShaderSource, primitiveFragmentShaderSource);
      var rasterProgram = createProgram(gl, rasterVertexShaderSource, rasterFragmentShaderSource);
      var surfaceProgram = createProgram(gl, surfaceVertexShaderSource, surfaceFragmentShaderSource);
      var meshProgram = createProgram(gl, meshVertexShaderSource, meshFragmentShaderSource);
      var meshPickProgram = createProgram(gl, meshPickVertexShaderSource, meshPickFragmentShaderSource);

      state.programs = {
        primitive: {
          program: primitiveProgram,
          attributes: {
            position: gl.getAttribLocation(primitiveProgram, "a_position"),
            size: gl.getAttribLocation(primitiveProgram, "a_size"),
            color: gl.getAttribLocation(primitiveProgram, "a_color"),
            age: gl.getAttribLocation(primitiveProgram, "a_age"),
            metric: gl.getAttribLocation(primitiveProgram, "a_metric")
	          },
	          uniforms: {
	            domain: gl.getUniformLocation(primitiveProgram, "u_domain"),
	            pointScale: gl.getUniformLocation(primitiveProgram, "u_point_scale"),
	            minPointSize: gl.getUniformLocation(primitiveProgram, "u_min_point_size"),
	            shaderMode: gl.getUniformLocation(primitiveProgram, "u_shader_mode"),
	            isPointLayer: gl.getUniformLocation(primitiveProgram, "u_is_point_layer"),
	            densityAlphaBoost: gl.getUniformLocation(primitiveProgram, "u_density_alpha_boost"),
	            densityAlphaCeiling: gl.getUniformLocation(primitiveProgram, "u_density_alpha_ceiling")
	          }
        },
        primitive3d: {
          program: primitive3dProgram,
          attributes: {
            position3: gl.getAttribLocation(primitive3dProgram, "a_position3"),
            size: gl.getAttribLocation(primitive3dProgram, "a_size"),
            color: gl.getAttribLocation(primitive3dProgram, "a_color"),
            age: gl.getAttribLocation(primitive3dProgram, "a_age"),
            metric: gl.getAttribLocation(primitive3dProgram, "a_metric")
          },
          uniforms: {
            viewProjection: gl.getUniformLocation(primitive3dProgram, "u_view_projection"),
            pointScale: gl.getUniformLocation(primitive3dProgram, "u_point_scale"),
            minPointSize: gl.getUniformLocation(primitive3dProgram, "u_min_point_size"),
            shaderMode: gl.getUniformLocation(primitive3dProgram, "u_shader_mode"),
            isPointLayer: gl.getUniformLocation(primitive3dProgram, "u_is_point_layer"),
            densityAlphaBoost: gl.getUniformLocation(primitive3dProgram, "u_density_alpha_boost"),
            densityAlphaCeiling: gl.getUniformLocation(primitive3dProgram, "u_density_alpha_ceiling")
          }
        },
        raster: {
          program: rasterProgram,
          attributes: {
            position: gl.getAttribLocation(rasterProgram, "a_position"),
            texcoord: gl.getAttribLocation(rasterProgram, "a_texcoord")
          },
          uniforms: {
            domain: gl.getUniformLocation(rasterProgram, "u_domain"),
            texture: gl.getUniformLocation(rasterProgram, "u_texture")
          }
        },
        surface: {
          program: surfaceProgram,
          attributes: {
            position3: gl.getAttribLocation(surfaceProgram, "a_position3"),
            normal: gl.getAttribLocation(surfaceProgram, "a_normal"),
            color: gl.getAttribLocation(surfaceProgram, "a_color"),
            uncertainty: gl.getAttribLocation(surfaceProgram, "a_uncertainty")
          },
          uniforms: {
            viewProjection: gl.getUniformLocation(surfaceProgram, "u_view_projection"),
            shadingMode: gl.getUniformLocation(surfaceProgram, "u_shading_mode"),
            lightDir: gl.getUniformLocation(surfaceProgram, "u_light_dir"),
            zRange: gl.getUniformLocation(surfaceProgram, "u_z_range")
          }
        },
        mesh: {
          program: meshProgram,
          attributes: {
            position3: gl.getAttribLocation(meshProgram, "a_position3"),
            normal: gl.getAttribLocation(meshProgram, "a_normal"),
            color: gl.getAttribLocation(meshProgram, "a_color"),
            scalar: gl.getAttribLocation(meshProgram, "a_scalar")
          },
          uniforms: {
            viewProjection: gl.getUniformLocation(meshProgram, "u_view_projection"),
            shadingMode: gl.getUniformLocation(meshProgram, "u_shading_mode"),
            lightDir: gl.getUniformLocation(meshProgram, "u_light_dir"),
            scalarRange: gl.getUniformLocation(meshProgram, "u_scalar_range"),
            ambient: gl.getUniformLocation(meshProgram, "u_ambient"),
            diffuse: gl.getUniformLocation(meshProgram, "u_diffuse"),
            specular: gl.getUniformLocation(meshProgram, "u_specular")
          }
        },
        meshPick: {
          program: meshPickProgram,
          attributes: {
            position3: gl.getAttribLocation(meshPickProgram, "a_position3"),
            pickColor: gl.getAttribLocation(meshPickProgram, "a_pick_color")
          },
          uniforms: {
            viewProjection: gl.getUniformLocation(meshPickProgram, "u_view_projection")
          }
        }
      };

      return state.programs;
    }

    function ensureGl(x) {
      if (state.gl) {
        return state.gl;
      }

      var options = {
        alpha: !(x.webgl && x.webgl.transparent === false),
        antialias: !(x.webgl && x.webgl.antialias === false),
        premultipliedAlpha: false
      };

      state.gl = state.canvas.getContext("webgl", options) ||
        state.canvas.getContext("experimental-webgl", options);

      return state.gl;
    }

    function resizeCanvas() {
      var metrics = getCanvasClientMetrics();
      var cssWidth = metrics.width;
      var cssHeight = metrics.height;
      var dpr = Math.min(window.devicePixelRatio || 1, 2);
      var maxDim = 8192;
      var maxArea = 67108864;
      var area = cssWidth * cssHeight * dpr * dpr;

      if (area > maxArea) {
        dpr = Math.sqrt(maxArea / Math.max(1, cssWidth * cssHeight));
      }

      var displayWidth = Math.max(1, Math.floor(cssWidth * dpr));
      var displayHeight = Math.max(1, Math.floor(cssHeight * dpr));
      if (displayWidth > maxDim || displayHeight > maxDim) {
        var dimScale = Math.min(maxDim / displayWidth, maxDim / displayHeight);
        displayWidth = Math.max(1, Math.floor(displayWidth * dimScale));
        displayHeight = Math.max(1, Math.floor(displayHeight * dimScale));
      }

      state.canvas.style.width = cssWidth + "px";
      state.canvas.style.height = cssHeight + "px";
      state.canvas.style.position = "absolute";
      state.canvas.style.left = "0";
      state.canvas.style.top = "0";

      if (state.canvas.width !== displayWidth || state.canvas.height !== displayHeight) {
        state.canvas.width = displayWidth;
        state.canvas.height = displayHeight;
      }
    }

    function createBuffer(gl, values) {
      var buffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ARRAY_BUFFER, values, gl.STATIC_DRAW);
      return buffer;
    }

    function createElementBuffer(gl, values) {
      var buffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, values, gl.STATIC_DRAW);
      return buffer;
    }

    function deleteBufferIfPresent(buffer) {
      if (!buffer || !state.gl) {
        return;
      }

      try {
        state.gl.deleteBuffer(buffer);
      } catch (err) {
        // Ignore stale resources from a lost context; the next draw recreates them.
      }
    }

    function bindAttributeBuffer(gl, location, buffer, size) {
      if (location < 0 || !buffer) {
        return;
      }

      gl.enableVertexAttribArray(location);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(location, size, gl.FLOAT, false, 0, 0);
    }

    function disposePointLayerPayload(layer) {
      var payload = layer && layer._ggwebglPointPayload;

      if (!payload) {
        return;
      }

      deleteBufferIfPresent(payload.positionBuffer);
      deleteBufferIfPresent(payload.sizeBuffer);
      deleteBufferIfPresent(payload.ageBuffer);
      deleteBufferIfPresent(payload.colorBuffer);
      delete layer._ggwebglPointPayload;
    }

    function disposeTransientPointPayload(payload) {
      if (!payload) {
        return;
      }

      deleteBufferIfPresent(payload.positionBuffer);
      deleteBufferIfPresent(payload.sizeBuffer);
      deleteBufferIfPresent(payload.ageBuffer);
      deleteBufferIfPresent(payload.colorBuffer);
    }

    function disposeSceneResources(x) {
      var panels = panelList(x);

      panels.forEach(function(panel) {
        (panel.layers || []).forEach(function(layer) {
          if (layer.type === "points") {
            disposePointLayerPayload(layer);
          } else if (layer.type === "surface") {
            disposeSurfaceLayerGpuPayload(state.gl, layer._surfaceGpuPayload);
            delete layer._surfaceGpuPayload;
          }
        });
      });
    }

	function supportedLayerBounds(panel) {
	  var layers = panel && Array.isArray(panel.layers) ? panel.layers : [];
	  var xmin = Infinity, xmax = -Infinity, ymin = Infinity, ymax = -Infinity;
	
	  function extend(x, y) {
		x = Number(x);
		y = Number(y);
		if (!isFinite(x) || !isFinite(y)) {
		  return;
		}
		if (x < xmin) xmin = x;
		if (x > xmax) xmax = x;
		if (y < ymin) ymin = y;
		if (y > ymax) ymax = y;
	  }
	
	  layers.forEach(function(layer) {
		if (layer.type === "points") {
		  var xs = layer.x || [];
		  var ys = layer.y || [];
		  var n = Math.min(xs.length, ys.length);
		  for (var i = 0; i < n; i += 1) {
			extend(xs[i], ys[i]);
		  }
		} else if (layer.type === "lines") {
		  var paths = linePathList(layer.paths);
		  paths.forEach(function(path) {
			var xs = path.x || [];
			var ys = path.y || [];
			var n = Math.min(xs.length, ys.length);
			for (var i = 0; i < n; i += 1) {
			  extend(xs[i], ys[i]);
			}
		  });
		} else if (layer.type === "raster") {
		  extend(layer.xmin, layer.ymin);
		  extend(layer.xmax, layer.ymax);
		} else if (layer.type === "vectors") {
		  var vxs = layer.x || [];
		  var vys = layer.y || [];
		  var vxends = layer.xend || [];
		  var vyends = layer.yend || [];
		  var vn = Math.min(vxs.length, vys.length, vxends.length, vyends.length);
		  for (var vi = 0; vi < vn; vi += 1) {
			extend(vxs[vi], vys[vi]);
			extend(vxends[vi], vyends[vi]);
		  }
		} else if (layer.type === "mesh") {
		  var mxs = layer.x || [];
		  var mys = layer.y || [];
		  var mn = Math.min(mxs.length, mys.length);
		  for (var mi = 0; mi < mn; mi += 1) {
			extend(mxs[mi], mys[mi]);
		  }
		} else if (layer.type === "surface") {
		  var positions = layer.positions || [];
		  for (var si = 0; si + 2 < positions.length; si += 3) {
			extend(positions[si], positions[si + 1]);
		  }
		}
	  });
	
	  if (!isFinite(xmin) || !isFinite(xmax) || !isFinite(ymin) || !isFinite(ymax)) {
		return null;
	  }
	
	  return {
		x: [xmin, xmax],
		y: [ymin, ymax]
	  };
	}

    function normalizeColorComponent(value, fallback) {
      var number = Number(value);

      if (!isFinite(number)) {
        return fallback;
      }

      if (number > 1.5) {
        number /= 255.0;
      }

      return Math.max(0, Math.min(1, number));
    }

    function project3dPoint(xValue, yValue, zValue, viewport, layer) {
      var xs = layer.x || [];
      var ys = layer.y || [];
      var zs = layer.z || [];
      var zMin = Infinity;
      var zMax = -Infinity;
      for (var zi = 0; zi < zs.length; zi += 1) {
        if (isFinite(Number(zs[zi]))) {
          zMin = Math.min(zMin, Number(zs[zi]));
          zMax = Math.max(zMax, Number(zs[zi]));
        }
      }
      if (!isFinite(zMin) || !isFinite(zMax)) {
        zMin = -1;
        zMax = 1;
      }
      var xMid = (viewport.x[0] + viewport.x[1]) * 0.5;
      var yMid = (viewport.y[0] + viewport.y[1]) * 0.5;
      var zMid = (zMin + zMax) * 0.5;
      var span = Math.max(1e-6, viewport.x[1] - viewport.x[0], viewport.y[1] - viewport.y[0], zMax - zMin);
      var target = state.camera.target || [0, 0, 0];
      var px = (Number(xValue) - xMid - target[0]) / span;
      var py = (Number(yValue) - yMid - target[1]) / span;
      var pz = (Number(zValue || 0) - zMid - target[2]) / span;
      var rotation = state.camera.rotation && state.camera.rotation.length === 4
        ? state.camera.rotation
        : orbitQuaternion(state.camera.yaw || 0, state.camera.pitch || 0);
      var rotated = rotateByQuaternion([px, py, pz], rotation);
      var rx = rotated[0];
      var ry = rotated[1];
      var rz = rotated[2];
      var distance = Math.max(0.1, state.camera.distance || 2.8);
      var scale = 1.8;
      if (state.x && state.x.webgl && state.x.webgl.projection === "perspective") {
        scale = distance / Math.max(0.1, distance - rz);
      }
      return { x: rx * scale, y: ry * scale, z: rz };
    }

    function layerZRange(zs) {
      var zMin = Infinity;
      var zMax = -Infinity;
      zs = Array.isArray(zs) ? zs : [];
      for (var i = 0; i < zs.length; i += 1) {
        var value = Number(zs[i]);
        if (isFinite(value)) {
          zMin = Math.min(zMin, value);
          zMax = Math.max(zMax, value);
        }
      }
      if (!isFinite(zMin) || !isFinite(zMax)) {
        zMin = -1;
        zMax = 1;
      }
      if (zMin === zMax) {
        zMin -= 0.5;
        zMax += 0.5;
      }
      return [zMin, zMax];
    }

    function normalizePosition3(xValue, yValue, zValue, viewport, zRange) {
      var xMid = (viewport.x[0] + viewport.x[1]) * 0.5;
      var yMid = (viewport.y[0] + viewport.y[1]) * 0.5;
      var zMid = (zRange[0] + zRange[1]) * 0.5;
      var span = Math.max(
        1e-6,
        viewport.x[1] - viewport.x[0],
        viewport.y[1] - viewport.y[0],
        zRange[1] - zRange[0]
      );
      return [
        (Number(xValue) - xMid) / span,
        (Number(yValue) - yMid) / span,
        (Number(zValue || 0) - zMid) / span
      ];
    }

    function cameraViewProjectionMatrix(x, box) {
      var cameraModule = window.ggWebGLCamera;
      if (!cameraModule || typeof cameraModule.cameraMatrices !== "function") {
        return window.ggWebGLMat4 ? window.ggWebGLMat4.identity() : [
          1, 0, 0, 0,
          0, 1, 0, 0,
          0, 0, 1, 0,
          0, 0, 0, 1
        ];
      }
      var camera = {
        distance: state.camera.distance,
        target: state.camera.target,
        rotation: state.camera.rotation,
        up: state.camera.up,
        fov: state.camera.fov,
        near: state.camera.near,
        far: state.camera.far
      };
      var aspect = box && box.plotHeight ? Math.max(1e-6, box.plotWidth / box.plotHeight) : 1;
      return cameraModule.cameraMatrices(camera, sceneProjection(x), aspect).viewProjection;
    }

    function flattenPointLayer3d(layer, x, viewport) {
      var n = layer.rows || 0;
      var xs = layer.x || [];
      var ys = layer.y || [];
      var zs = layer.z || [];
      var sizes = layer.size || [];
      var ages = layer.age || [];
      var rgba = layer.rgba || [];
      var zRange = layerZRange(zs);
      var positions = [];
      var pointSizes = [];
      var pointAges = [];
      var colors = [];

      for (var i = 0; i < n; i += 1) {
        if (x && !layerIndexVisible(layer, i, x)) {
          continue;
        }
        var point = normalizePosition3(xs[i], ys[i], zs[i] || 0, viewport, zRange);
        positions.push(point[0], point[1], point[2]);
        pointSizes.push(isFinite(sizes[i]) ? Number(sizes[i]) : 1.0);
        pointAges.push(isFinite(ages[i]) ? Number(ages[i]) : 1.0);
        colors.push(
          normalizeColorComponent(rgba[i * 4 + 0], 0.0),
          normalizeColorComponent(rgba[i * 4 + 1], 0.0),
          normalizeColorComponent(rgba[i * 4 + 2], 0.0),
          normalizeColorComponent(rgba[i * 4 + 3], 1.0)
        );
      }

      return {
        count: pointSizes.length,
        positions: new Float32Array(positions),
        sizes: new Float32Array(pointSizes),
        ages: new Float32Array(pointAges),
        colors: new Float32Array(colors)
      };
    }

    function flattenPointLayer(layer, x, viewport) {
      var n = layer.rows || 0;
      var xs = layer.x || [];
      var ys = layer.y || [];
      var zs = layer.z || [];
      var sizes = layer.size || [];
      var ages = layer.age || [];
      var rgba = layer.rgba || [];
      var use3d = x && sceneDimension(x) === "3d" && zs.length;
      var positions = [];
      var pointSizes = [];
      var pointAges = [];
      var colors = [];

      for (var i = 0; i < n; i += 1) {
        if (x && !layerIndexVisible(layer, i, x)) {
          continue;
        }
        var point = use3d ? project3dPoint(xs[i], ys[i], zs[i], viewport, layer) : { x: Number(xs[i]), y: Number(ys[i]) };
        positions.push(point.x, point.y);
        pointSizes.push(isFinite(sizes[i]) ? Number(sizes[i]) : 1.0);
        pointAges.push(isFinite(ages[i]) ? Number(ages[i]) : 1.0);

        colors.push(
          normalizeColorComponent(rgba[i * 4 + 0], 0.0),
          normalizeColorComponent(rgba[i * 4 + 1], 0.0),
          normalizeColorComponent(rgba[i * 4 + 2], 0.0),
          normalizeColorComponent(rgba[i * 4 + 3], 1.0)
        );
      }

      return {
        count: pointSizes.length,
        positions: new Float32Array(positions),
        sizes: new Float32Array(pointSizes),
        ages: new Float32Array(pointAges),
        colors: new Float32Array(colors)
      };
    }

    function createPointLayerGpuPayload(gl, layer) {
      var payload = flattenPointLayer(layer);

      return {
        gl: gl,
        count: payload.count,
        positionBuffer: payload.count ? createBuffer(gl, payload.positions) : null,
        sizeBuffer: payload.count ? createBuffer(gl, payload.sizes) : null,
        ageBuffer: payload.count ? createBuffer(gl, payload.ages) : null,
        colorBuffer: payload.count ? createBuffer(gl, payload.colors) : null
      };
    }

    function createPointLayerGpuPayloadFromFlat(gl, payload) {
      return {
        gl: gl,
        count: payload.count,
        positionBuffer: payload.count ? createBuffer(gl, payload.positions) : null,
        sizeBuffer: payload.count ? createBuffer(gl, payload.sizes) : null,
        ageBuffer: payload.count ? createBuffer(gl, payload.ages) : null,
        colorBuffer: payload.count ? createBuffer(gl, payload.colors) : null
      };
    }

    function ensurePointLayerGpuPayload(gl, layer) {
      var cached = layer._ggwebglPointPayload;
      var expectedCount = Number(layer.rows || 0);

      if (cached && cached.gl === gl && cached.count === expectedCount) {
        return cached;
      }

      disposePointLayerPayload(layer);
      layer._ggwebglPointPayload = createPointLayerGpuPayload(gl, layer);
      return layer._ggwebglPointPayload;
    }

    function finiteTrajectoryNumber(value) {
      var number = Number(value);
      return isFinite(number) ? number : null;
    }

    function pathPointCount(path) {
      var xs = Array.isArray(path && path.x) ? path.x : [];
      var ys = Array.isArray(path && path.y) ? path.y : [];
      return Math.min(xs.length, ys.length);
    }

    function trajectoryStepDelta(path, i0, i1) {
      var times = Array.isArray(path.time) ? path.time : null;
      var frames = Array.isArray(path.frame) ? path.frame : null;
      var start;
      var end;

      if (times && times.length > i0 && times.length > i1) {
        start = finiteTrajectoryNumber(times[i0]);
        end = finiteTrajectoryNumber(times[i1]);
        return start === null || end === null ? null : end - start;
      }

      if (frames && frames.length > i0 && frames.length > i1) {
        start = finiteTrajectoryNumber(frames[i0]);
        end = finiteTrajectoryNumber(frames[i1]);
        return start === null || end === null ? null : end - start;
      }

      return 1;
    }

    function trajectoryDistance(path, i0, i1) {
      var xs = Array.isArray(path.x) ? path.x : [];
      var ys = Array.isArray(path.y) ? path.y : [];
      var zs = Array.isArray(path.z) ? path.z : [];
      var x0 = finiteTrajectoryNumber(xs[i0]);
      var y0 = finiteTrajectoryNumber(ys[i0]);
      var x1 = finiteTrajectoryNumber(xs[i1]);
      var y1 = finiteTrajectoryNumber(ys[i1]);
      var z0 = 0;
      var z1 = 0;

      if (x0 === null || y0 === null || x1 === null || y1 === null) {
        return null;
      }

      if (zs.length) {
        z0 = finiteTrajectoryNumber(zs[i0]);
        z1 = finiteTrajectoryNumber(zs[i1]);
        if (z0 === null || z1 === null) {
          return null;
        }
      }

      var dx = x1 - x0;
      var dy = y1 - y0;
      var dz = z1 - z0;
      return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    function rawTrajectoryVelocity(path) {
      var n = pathPointCount(path);
      var values = new Array(n).fill(0);

      for (var i = 1; i < n; i += 1) {
        var delta = trajectoryStepDelta(path, i - 1, i);
        var distance = trajectoryDistance(path, i - 1, i);
        if (delta !== null && distance !== null && isFinite(delta) && isFinite(distance) && delta > 0) {
          values[i] = distance / delta;
        }
      }

      return values;
    }

    function normalizeFiniteMetric(values, range) {
      var min = range && isFinite(range[0]) ? Number(range[0]) : Infinity;
      var max = range && isFinite(range[1]) ? Number(range[1]) : -Infinity;

      if (!range) {
        values.forEach(function(value) {
          var number = Number(value);
          if (isFinite(number)) {
            min = Math.min(min, number);
            max = Math.max(max, number);
          }
        });
      }

      if (!isFinite(min) || !isFinite(max) || max <= min) {
        return values.map(function() { return 0; });
      }

      return values.map(function(value) {
        var number = Number(value);
        return isFinite(number) ? Math.max(0, Math.min(1, (number - min) / (max - min))) : 0;
      });
    }

    function computeTrajectoryVelocity(path) {
      return normalizeFiniteMetric(rawTrajectoryVelocity(path));
    }

    function computeTrajectoryDirection(path) {
      var xs = Array.isArray(path.x) ? path.x : [];
      var ys = Array.isArray(path.y) ? path.y : [];
      var n = pathPointCount(path);
      var values = new Array(n).fill(0.5);

      for (var i = 1; i < n; i += 1) {
        var x0 = finiteTrajectoryNumber(xs[i - 1]);
        var y0 = finiteTrajectoryNumber(ys[i - 1]);
        var x1 = finiteTrajectoryNumber(xs[i]);
        var y1 = finiteTrajectoryNumber(ys[i]);
        if (x0 === null || y0 === null || x1 === null || y1 === null) {
          values[i] = values[i - 1];
          continue;
        }
        var dx = x1 - x0;
        var dy = y1 - y0;
        if (Math.sqrt(dx * dx + dy * dy) <= 1e-12) {
          values[i] = values[i - 1];
          continue;
        }
        values[i] = Math.max(0, Math.min(1, (Math.atan2(dy, dx) + Math.PI) / (2 * Math.PI)));
      }

      if (n > 1) {
        values[0] = values[1];
      }

      return values;
    }

    function computeLayerTrajectoryMetrics(layer, shaderMode) {
      var paths = linePathList(layer && layer.paths);
      if (shaderMode === 4) {
        var rawByPath = paths.map(rawTrajectoryVelocity);
        var min = Infinity;
        var max = -Infinity;
        rawByPath.forEach(function(values) {
          values.forEach(function(value) {
            var number = Number(value);
            if (isFinite(number)) {
              min = Math.min(min, number);
              max = Math.max(max, number);
            }
          });
        });
        return rawByPath.map(function(values) {
          return normalizeFiniteMetric(values, [min, max]);
        });
      }

      if (shaderMode === 5) {
        return paths.map(computeTrajectoryDirection);
      }

      return paths.map(function(path) {
        return new Array(pathPointCount(path)).fill(0);
      });
    }

    function trajectoryMetricAt(metrics, index) {
      if (!Array.isArray(metrics) || index < 0 || index >= metrics.length) {
        return 0;
      }
      var value = Number(metrics[index]);
      return isFinite(value) ? value : 0;
    }

		function flattenLinePath(path, xScene, metrics) {
		  var xs = Array.isArray(path.x) ? path.x : [];
		  var ys = Array.isArray(path.y) ? path.y : [];
		  var ages = Array.isArray(path.age) ? path.age : [];
		  var rgba = Array.isArray(path.rgba) ? path.rgba : [];
		
		  var n = Math.min(xs.length, ys.length);
      var timelineClipped = xScene && state.timeline && state.timeline.enabled && layerHasTimelineValues(path, state.timeline);
		
		  if (!n || (timelineClipped && n < 2)) {
			return {
			  count: 0,
        mode: "line_strip",
			  positions: new Float32Array(0),
			  ages: new Float32Array(0),
			  colors: new Float32Array(0),
        metrics: new Float32Array(0)
			};
		  }

      if (timelineClipped) {
        var segmentPositions = [];
        var segmentAges = [];
        var segmentColors = [];
        var segmentMetrics = [];
        function pushSegmentVertex(index) {
          segmentPositions.push(Number(xs[index]), Number(ys[index]));
          segmentAges.push(isFinite(ages[index]) ? Number(ages[index]) : 1.0);
          segmentMetrics.push(trajectoryMetricAt(metrics, index));
          if (rgba.length >= (index * 4 + 4)) {
            segmentColors.push(
              Number(rgba[index * 4 + 0]),
              Number(rgba[index * 4 + 1]),
              Number(rgba[index * 4 + 2]),
              Number(rgba[index * 4 + 3])
            );
          } else {
            segmentColors.push(0.1, 0.1, 0.1, 1.0);
          }
        }
        for (var s = 0; s < n - 1; s += 1) {
          if (!pathSegmentVisible(path, s, s + 1, xScene)) {
            continue;
          }
          pushSegmentVertex(s);
          pushSegmentVertex(s + 1);
        }
        return {
          count: segmentAges.length,
          mode: "lines",
          positions: new Float32Array(segmentPositions),
          ages: new Float32Array(segmentAges),
          colors: new Float32Array(segmentColors),
          metrics: new Float32Array(segmentMetrics)
        };
      }
		
		  var positions = new Float32Array(n * 2);
		  var pathAges = new Float32Array(n);
		  var colors = new Float32Array(n * 4);
      var pathMetrics = new Float32Array(n);
		
		  for (var i = 0; i < n; i += 1) {
			positions[i * 2] = Number(xs[i]);
			positions[i * 2 + 1] = Number(ys[i]);
		
			pathAges[i] = isFinite(ages[i]) ? Number(ages[i]) : 1.0;
      pathMetrics[i] = trajectoryMetricAt(metrics, i);
		
			if (rgba.length >= (i * 4 + 4)) {
			  colors[i * 4 + 0] = Number(rgba[i * 4 + 0]);
			  colors[i * 4 + 1] = Number(rgba[i * 4 + 1]);
			  colors[i * 4 + 2] = Number(rgba[i * 4 + 2]);
			  colors[i * 4 + 3] = Number(rgba[i * 4 + 3]);
			} else {
        colors[i * 4 + 0] = 0.1;
        colors[i * 4 + 1] = 0.1;
        colors[i * 4 + 2] = 0.1;
        colors[i * 4 + 3] = 1.0;
			}
		  }
		
		return {
		  count: n,
      mode: "line_strip",
		  positions: positions,
		  ages: pathAges,
		  colors: colors,
      metrics: pathMetrics
		};
	}

    function flattenLinePath3d(path, x, viewport, metrics) {
      var xs = Array.isArray(path.x) ? path.x : [];
      var ys = Array.isArray(path.y) ? path.y : [];
      var zs = Array.isArray(path.z) ? path.z : [];
      var ages = Array.isArray(path.age) ? path.age : [];
      var rgba = Array.isArray(path.rgba) ? path.rgba : [];
      var n = Math.min(xs.length, ys.length);
      var zRange = layerZRange(zs);
      var positions = [];
      var pathAges = [];
      var colors = [];
      var pathMetrics = [];
      var timelineClipped = x && state.timeline && state.timeline.enabled && layerHasTimelineValues(path, state.timeline);

      function push3dVertex(index) {
        var point = normalizePosition3(xs[index], ys[index], zs[index] || 0, viewport, zRange);
        positions.push(point[0], point[1], point[2]);
        pathAges.push(isFinite(ages[index]) ? Number(ages[index]) : 1.0);
        pathMetrics.push(trajectoryMetricAt(metrics, index));
        if (rgba.length >= (index * 4 + 4)) {
          colors.push(
            normalizeColorComponent(rgba[index * 4 + 0], 0.1),
            normalizeColorComponent(rgba[index * 4 + 1], 0.1),
            normalizeColorComponent(rgba[index * 4 + 2], 0.1),
            normalizeColorComponent(rgba[index * 4 + 3], 1.0)
          );
        } else {
          colors.push(0.1, 0.1, 0.1, 1.0);
        }
      }

      if (timelineClipped) {
        for (var s = 0; s < n - 1; s += 1) {
          if (!pathSegmentVisible(path, s, s + 1, x)) {
            continue;
          }
          push3dVertex(s);
          push3dVertex(s + 1);
        }
        return {
          count: pathAges.length,
          mode: "lines",
          positions: new Float32Array(positions),
          ages: new Float32Array(pathAges),
          colors: new Float32Array(colors),
          metrics: new Float32Array(pathMetrics)
        };
      }

      for (var i = 0; i < n; i += 1) {
        if (x && !pathIndexVisible(path, i, x)) {
          continue;
        }
        push3dVertex(i);
      }

      return {
        count: pathAges.length,
        mode: "line_strip",
        positions: new Float32Array(positions),
        ages: new Float32Array(pathAges),
        colors: new Float32Array(colors),
        metrics: new Float32Array(pathMetrics)
      };
    }

    function flattenLinePathToStyledQuads(path, viewport, plotWidthPx, plotHeightPx, joinMode, capMode, xScene, projectViewport, metrics) {
      var xs = Array.isArray(path.x) ? path.x : [];
      var ys = Array.isArray(path.y) ? path.y : [];
      var zs = Array.isArray(path.z) ? path.z : [];
      var ages = Array.isArray(path.age) ? path.age : [];
      var rgba = Array.isArray(path.rgba) ? path.rgba : [];
      var use3d = xScene && sceneDimension(xScene) === "3d" && zs.length;

      var n = Math.min(xs.length, ys.length);

      if (n < 2 || !isFinite(plotWidthPx) || !isFinite(plotHeightPx) || plotWidthPx <= 0 || plotHeightPx <= 0) {
        return {
          count: 0,
          positions: new Float32Array(0),
          ages: new Float32Array(0),
          colors: new Float32Array(0),
          metrics: new Float32Array(0)
        };
      }

      var xSpan = Math.max(1e-6, viewport.x[1] - viewport.x[0]);
      var ySpan = Math.max(1e-6, viewport.y[1] - viewport.y[0]);

      var baseWidth = Number(path.width);
      if (!isFinite(baseWidth) || baseWidth <= 0) {
        baseWidth = 1.5;
      }

      var widthPx = Math.max(2.0, baseWidth * 1.5);
      var halfWidthPx = widthPx * 0.5;

      var positions = [];
      var outAges = [];
      var outMetrics = [];
      var colors = [];

      function pointAt(i) {
        if (use3d) {
          return project3dPoint(xs[i], ys[i], zs[i], projectViewport || viewport, path);
        }
        return { x: Number(xs[i]), y: Number(ys[i]) };
      }

      function pushVertex(x, y, age, metric, r, g, b, a) {
        positions.push(x, y);
        outAges.push(isFinite(age) ? age : 1.0);
        outMetrics.push(isFinite(metric) ? metric : 0.0);
        colors.push(r, g, b, a);
      }

      function colorAt(i) {
        if (rgba.length >= (i * 4 + 4)) {
          return [
            Number(rgba[i * 4 + 0]),
            Number(rgba[i * 4 + 1]),
            Number(rgba[i * 4 + 2]),
            Math.max(0.75, Number(rgba[i * 4 + 3]))
          ];
        }

        return [0.12, 0.12, 0.12, 1.0];
      }

      var capSegments = 8;

      function screenUnit(dxData, dyData) {
        var dxPx = dxData / xSpan * plotWidthPx;
        var dyPx = dyData / ySpan * plotHeightPx;
        var lenPx = Math.sqrt(dxPx * dxPx + dyPx * dyPx);
        if (!(lenPx > 1e-6)) {
          return null;
        }
        return {
          tx: dxPx / lenPx,
          ty: dyPx / lenPx,
          nx: -dyPx / lenPx,
          ny: dxPx / lenPx
        };
      }

      function pixelOffsetToData(nxPx, nyPx) {
        return {
          x: (nxPx * halfWidthPx) / plotWidthPx * xSpan,
          y: (nyPx * halfWidthPx) / plotHeightPx * ySpan
        };
      }

      function addSegmentQuad(i0, i1) {
        if (!pathSegmentVisible(path, i0, i1, xScene)) {
          return;
        }
        var p0 = pointAt(i0);
        var p1 = pointAt(i1);
        var x0 = Number(p0.x), y0 = Number(p0.y);
        var x1 = Number(p1.x), y1 = Number(p1.y);

        if (!isFinite(x0) || !isFinite(y0) || !isFinite(x1) || !isFinite(y1)) {
          return;
        }

        var unit = screenUnit(x1 - x0, y1 - y0);
        if (!unit) {
          return;
        }

        var off = pixelOffsetToData(unit.nx, unit.ny);
        var c0 = colorAt(i0);
        var c1 = colorAt(i1);
        var a0 = isFinite(ages[i0]) ? Number(ages[i0]) : 1.0;
        var a1 = isFinite(ages[i1]) ? Number(ages[i1]) : 1.0;
        var m0 = trajectoryMetricAt(metrics, i0);
        var m1 = trajectoryMetricAt(metrics, i1);

        pushVertex(x0 - off.x, y0 - off.y, a0, m0, c0[0], c0[1], c0[2], c0[3]);
        pushVertex(x0 + off.x, y0 + off.y, a0, m0, c0[0], c0[1], c0[2], c0[3]);
        pushVertex(x1 - off.x, y1 - off.y, a1, m1, c1[0], c1[1], c1[2], c1[3]);
        pushVertex(x1 - off.x, y1 - off.y, a1, m1, c1[0], c1[1], c1[2], c1[3]);
        pushVertex(x0 + off.x, y0 + off.y, a0, m0, c0[0], c0[1], c0[2], c0[3]);
        pushVertex(x1 + off.x, y1 + off.y, a1, m1, c1[0], c1[1], c1[2], c1[3]);
      }

      function addBevelJoin(i) {
        if (!pathSegmentVisible(path, i - 1, i, xScene) || !pathSegmentVisible(path, i, i + 1, xScene)) {
          return;
        }
        if (joinMode !== "bevel" || i <= 0 || i >= n - 1) {
          return;
        }

        var xPrev = Number(xs[i - 1]), yPrev = Number(ys[i - 1]);
        var x0 = Number(xs[i]), y0 = Number(ys[i]);
        var xNext = Number(xs[i + 1]), yNext = Number(ys[i + 1]);

        if (!isFinite(xPrev) || !isFinite(yPrev) || !isFinite(x0) || !isFinite(y0) || !isFinite(xNext) || !isFinite(yNext)) {
          return;
        }

        var u0 = screenUnit(x0 - xPrev, y0 - yPrev);
        var u1 = screenUnit(xNext - x0, yNext - y0);

        if (!u0 || !u1) {
          return;
        }

        var cross = u0.tx * u1.ty - u0.ty * u1.tx;
        if (Math.abs(cross) < 1e-6) {
          return;
        }

        var outward0 = pixelOffsetToData(cross > 0 ? u0.nx : -u0.nx, cross > 0 ? u0.ny : -u0.ny);
        var outward1 = pixelOffsetToData(cross > 0 ? u1.nx : -u1.nx, cross > 0 ? u1.ny : -u1.ny);
        var c = colorAt(i);
        var a = isFinite(ages[i]) ? Number(ages[i]) : 1.0;
        var m = trajectoryMetricAt(metrics, i);

        pushVertex(x0, y0, a, m, c[0], c[1], c[2], c[3]);
        pushVertex(x0 + outward0.x, y0 + outward0.y, a, m, c[0], c[1], c[2], c[3]);
        pushVertex(x0 + outward1.x, y0 + outward1.y, a, m, c[0], c[1], c[2], c[3]);
      }

      function addRoundCap(index, atEnd) {
        if (capMode !== "round") {
          return;
        }

        var neighbor = atEnd ? index - 1 : index + 1;
        if (neighbor < 0 || neighbor >= n) {
          return;
        }
        if (!pathSegmentVisible(path, Math.min(index, neighbor), Math.max(index, neighbor), xScene)) {
          return;
        }

        var x0 = Number(xs[index]), y0 = Number(ys[index]);
        var x1 = Number(xs[neighbor]), y1 = Number(ys[neighbor]);

        if (!isFinite(x0) || !isFinite(y0) || !isFinite(x1) || !isFinite(y1)) {
          return;
        }

        var unit = screenUnit(x1 - x0, y1 - y0);
        if (!unit) {
          return;
        }

        var angleBase = Math.atan2(unit.ty, unit.tx);
        var start = atEnd ? angleBase - Math.PI / 2 : angleBase + Math.PI / 2;
        var stop  = atEnd ? angleBase + Math.PI / 2 : angleBase + 3 * Math.PI / 2;
        var c = colorAt(index);
        var a = isFinite(ages[index]) ? Number(ages[index]) : 1.0;
        var m = trajectoryMetricAt(metrics, index);

        for (var s = 0; s < capSegments; s += 1) {
          var t0 = start + (stop - start) * (s / capSegments);
          var t1 = start + (stop - start) * ((s + 1) / capSegments);
          var off0 = pixelOffsetToData(Math.cos(t0), Math.sin(t0));
          var off1 = pixelOffsetToData(Math.cos(t1), Math.sin(t1));
          pushVertex(x0, y0, a, m, c[0], c[1], c[2], c[3]);
          pushVertex(x0 + off0.x, y0 + off0.y, a, m, c[0], c[1], c[2], c[3]);
          pushVertex(x0 + off1.x, y0 + off1.y, a, m, c[0], c[1], c[2], c[3]);
        }
      }

      for (var i = 0; i < n - 1; i += 1) {
        addSegmentQuad(i, i + 1);
      }

      for (var j = 1; j < n - 1; j += 1) {
        addBevelJoin(j);
      }

      addRoundCap(0, false);
      addRoundCap(n - 1, true);

      return {
        count: positions.length / 2,
        positions: new Float32Array(positions),
        ages: new Float32Array(outAges),
        metrics: new Float32Array(outMetrics),
        colors: new Float32Array(colors)
      };
    }

    function flattenRasterLayer(layer) {
      var pixels = Array.isArray(layer.rgba) ? layer.rgba : [];

      return {
        width: Number(layer.width) || 0,
        height: Number(layer.height) || 0,
        xmin: Number(layer.xmin),
        xmax: Number(layer.xmax),
        ymin: Number(layer.ymin),
        ymax: Number(layer.ymax),
        interpolate: !!layer.interpolate,
        pixels: new Uint8Array(pixels)
      };
    }

	function renderPanelOverlay(x) {
	  if (!state.panelOverlayBack || !state.panelOverlayFront) {
		return;
	  }
	
	  var boxes = panelBoxes(x);
	  state.panelOverlayBack.innerHTML = "";
	  state.panelOverlayFront.innerHTML = "";
	
	  if (!boxes.length || !shouldShowPanelOverlay(x, boxes)) {
		return;
	  }

      var publication = publicationMode(x);
	
	  boxes.forEach(function(box) {
        if (!publication) {
		  var grid = document.createElement("div");
		  grid.style.position = "absolute";
		  grid.style.left = box.plotLeft + "px";
		  grid.style.top = box.plotTop + "px";
		  grid.style.width = box.plotWidth + "px";
		  grid.style.height = box.plotHeight + "px";
		  grid.style.pointerEvents = "none";
	
		  var nx = 6;
		  var ny = 6;
	
		  for (var i = 1; i < nx; i += 1) {
		    var v = document.createElement("div");
		    v.style.position = "absolute";
		    v.style.left = (i / nx * 100) + "%";
		    v.style.top = "0";
		    v.style.width = "1px";
		    v.style.height = "100%";
		    v.style.background = "rgba(255,255,255,0.65)";
		    grid.appendChild(v);
		  }
	
		  for (var j = 1; j < ny; j += 1) {
		    var h = document.createElement("div");
		    h.style.position = "absolute";
		    h.style.top = (j / ny * 100) + "%";
		    h.style.left = "0";
		    h.style.height = "1px";
		    h.style.width = "100%";
		    h.style.background = "rgba(255,255,255,0.65)";
		    grid.appendChild(h);
		  }
	
		  state.panelOverlayBack.appendChild(grid);
        }
	
		if (!(boxes.length === 1 && !box.panel.label && panelOverlayMode(x) !== "show")) {
		  var frame = document.createElement("div");
		  frame.className = "ggwebgl__panel-frame";
		  frame.style.left = box.left + "px";
		  frame.style.top = box.top + "px";
		  frame.style.width = box.width + "px";
		  frame.style.height = box.height + "px";
	
		  if (box.panel.label) {
			var strip = document.createElement("div");
			strip.className = "ggwebgl__panel-strip";
			strip.textContent = box.panel.label;
			frame.appendChild(strip);
		  }
	
		  state.panelOverlayFront.appendChild(frame);
		}
	  });
	}

    function summariseNotes(x) {
      var notes = [];
      var render = x.render || {};
      var unsupported = render.unsupported_layers || [];
      var messages = render.messages || [];
      var panels = panelList(x);
      var interactions = interactionList(x);

      if (interactions.length) {
        var controls = [];

        if (interactions.indexOf("pan") !== -1) {
          controls.push("drag to pan");
        }

        if (interactions.indexOf("zoom") !== -1) {
          controls.push("scroll to zoom");
          controls.push("double-click to reset");
        }

        if (interactions.indexOf("hover") !== -1) {
          controls.push("move to inspect nearby samples");
        }

        if (controls.length) {
          notes.push("<div>Controls: " + escapeHtml(controls.join(", ")) + "</div>");
        }
      }

      if (panels.length > 1) {
        notes.push("<div>Facet panels: " + escapeHtml(String(panels.length)) + " (fixed scales)</div>");
      }

      messages.forEach(function(message) {
        notes.push("<div>" + escapeHtml(message) + "</div>");
      });

      if (unsupported.length) {
        notes.push(
          "<div>Unsupported layers: " +
          unsupported.map(function(layer) {
            return escapeHtml(layer.geom || "unknown");
          }).join(", ") +
          "</div>"
        );
      }

      return notes.join("");
    }

    function updateLabels(x) {
      var render = x.render || {};
      var title = x.labels && x.labels.title ? x.labels.title : "ggWebGL";
      var subtitle = x.labels && x.labels.subtitle ? x.labels.subtitle : "";
      var shader = shaderName(x);
      var primitiveList = Array.isArray(render.primitives)
        ? render.primitives
        : (typeof render.primitives === "string" && render.primitives
          ? [render.primitives]
          : []);
      var primitives = primitiveList.length ? primitiveList.join(", ") : "none";
      var panelCount = panelList(x).length;

      applyRenderingModeUi(x);

      state.title.textContent = title;
      state.subtitle.textContent = subtitle;
      state.subtitle.style.display = subtitle ? "" : "none";
      state.meta.innerHTML = [
        "Mode: <code>" + escapeHtml(render.mode || "metadata") + "</code>",
        "Shader mode: <code>" + escapeHtml(shader) + "</code>",
        "Primitives: <strong>" + escapeHtml(primitives) + "</strong>",
        "Panels: <strong>" + escapeHtml(String(panelCount)) + "</strong>",
        "Points: <strong>" + escapeHtml(render.point_count || 0) + "</strong>",
        "Line vertices: <strong>" + escapeHtml(render.line_vertex_count || 0) + "</strong>",
        "Vectors: <strong>" + escapeHtml(render.vector_count || 0) + "</strong>",
        "Mesh triangles: <strong>" + escapeHtml(render.mesh_triangle_count || 0) + "</strong>",
        "Surface triangles: <strong>" + escapeHtml(render.surface_triangle_count || 0) + "</strong>",
        "Raster cells: <strong>" + escapeHtml(render.raster_cell_count || 0) + "</strong>"
      ].join(" | ");

      state.axes.querySelector(".ggwebgl__axis--x").textContent =
        x.labels && x.labels.x ? x.labels.x : "";
      state.axes.querySelector(".ggwebgl__axis--y").textContent =
        x.labels && x.labels.y ? x.labels.y : "";
      state.notes.innerHTML = summariseNotes(x);
      updateInteractionUi(x);
    }

    function setEmpty(message) {
      hideTooltip();
		if (state.panelOverlayBack) {
		  state.panelOverlayBack.innerHTML = "";
		}
		if (state.panelOverlayFront) {
		  state.panelOverlayFront.innerHTML = "";
		}
      state.empty.innerHTML = message;
      state.empty.style.display = "flex";
    }

    function clearEmpty() {
      state.empty.innerHTML = "";
      state.empty.style.display = "none";
    }

    function bindPositionAttribute(gl, programInfo, values) {
      var buffer = createBuffer(gl, values);
      gl.enableVertexAttribArray(programInfo.attributes.position);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(programInfo.attributes.position, 2, gl.FLOAT, false, 0, 0);
      return buffer;
    }

    function bindColorAttribute(gl, programInfo, values) {
      var buffer = createBuffer(gl, values);
      gl.enableVertexAttribArray(programInfo.attributes.color);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(programInfo.attributes.color, 4, gl.FLOAT, false, 0, 0);
      return buffer;
    }

    function bindSizeAttribute(gl, programInfo, values) {
      var buffer = createBuffer(gl, values);
      gl.enableVertexAttribArray(programInfo.attributes.size);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(programInfo.attributes.size, 1, gl.FLOAT, false, 0, 0);
      return buffer;
    }

    function bindAgeAttribute(gl, programInfo, values) {
      var buffer = createBuffer(gl, values);
      gl.enableVertexAttribArray(programInfo.attributes.age);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(programInfo.attributes.age, 1, gl.FLOAT, false, 0, 0);
      return buffer;
    }

    function bindMetricAttribute(gl, programInfo, values) {
      var buffer = createBuffer(gl, values);
      if (programInfo.attributes.metric < 0) {
        return buffer;
      }
      gl.enableVertexAttribArray(programInfo.attributes.metric);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(programInfo.attributes.metric, 1, gl.FLOAT, false, 0, 0);
      return buffer;
    }

    function bindConstantMetricAttribute(gl, programInfo) {
      if (programInfo.attributes.metric >= 0) {
        gl.disableVertexAttribArray(programInfo.attributes.metric);
        gl.vertexAttrib1f(programInfo.attributes.metric, 0.0);
      }
    }

    function bindTexcoordAttribute(gl, programInfo, values) {
      var buffer = createBuffer(gl, values);
      gl.enableVertexAttribArray(programInfo.attributes.texcoord);
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(programInfo.attributes.texcoord, 2, gl.FLOAT, false, 0, 0);
      return buffer;
    }

    function densitySplatTuning(pointCount) {
      var count = Math.max(1, Number(pointCount) || 1);
      var logCount = Math.log(count) / Math.LN10;
      var t = Math.max(0, Math.min(1, (logCount - 4.0) / 2.0));

      return {
        pointScale: 2.6 - 0.9 * t,
        minPointSize: 5.0 - 1.5 * t,
        alphaBoost: 1.0 - 0.25 * t,
        alphaCeiling: 0.90 - 0.18 * t
      };
    }

    function configurePrimitiveBlending(gl, x, shaderMode, layerType) {
      var mode = blendMode(x);
      gl.enable(gl.BLEND);
      gl.blendEquation(gl.FUNC_ADD);
      if (mode === "additive") {
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
      } else if (mode === "premultiplied") {
        gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      } else if (shaderMode === 1) {
        if (layerType === "points" && mode === "auto") {
          gl.blendFuncSeparate(
            gl.SRC_ALPHA,
            gl.ONE_MINUS_SRC_ALPHA,
            gl.ONE,
            gl.ONE_MINUS_SRC_ALPHA
          );
        } else {
          gl.blendFuncSeparate(
            gl.SRC_ALPHA,
            gl.ONE_MINUS_SRC_ALPHA,
            gl.ONE,
            gl.ONE_MINUS_SRC_ALPHA
          );
        }
      } else {
        gl.blendFuncSeparate(
          gl.SRC_ALPHA,
          gl.ONE_MINUS_SRC_ALPHA,
          gl.ONE,
          gl.ONE_MINUS_SRC_ALPHA
        );
      }
    }

    function configurePrimitiveLayerShader(gl, programInfo, x, layerType, viewport, layer) {
      var shaderMode = shaderModeForLayer(x, layerType);
      var isPointLayer = layerType === "points" ? 1.0 : 0.0;
      var densityTuning = densitySplatTuning(layer && layer.rows);

      // ggplot point sizes are not raw WebGL pixels.
      // Keep non-density sizing unchanged; density gets deterministic count-aware splats.
      var pointScale = 1.0;
      var minPointSize = 1.0;
      var densityAlphaBoost = 1.0;
      var densityAlphaCeiling = 0.90;
      if (layerType === "points") {
        pointScale = shaderMode === 1 ? densityTuning.pointScale : 1.6;
        minPointSize = shaderMode === 1 ? densityTuning.minPointSize : 1.0;
        densityAlphaBoost = shaderMode === 1 ? densityTuning.alphaBoost : 1.0;
        densityAlphaCeiling = shaderMode === 1 ? densityTuning.alphaCeiling : 0.90;
      }

      gl.useProgram(programInfo.program);
      gl.uniform4f(programInfo.uniforms.domain, viewport.x[0], viewport.x[1], viewport.y[0], viewport.y[1]);
      gl.uniform1f(programInfo.uniforms.shaderMode, shaderMode);
      gl.uniform1f(programInfo.uniforms.isPointLayer, isPointLayer);
      gl.uniform1f(programInfo.uniforms.pointScale, pointScale);
      gl.uniform1f(programInfo.uniforms.minPointSize, minPointSize);
      gl.uniform1f(programInfo.uniforms.densityAlphaBoost, densityAlphaBoost);
      gl.uniform1f(programInfo.uniforms.densityAlphaCeiling, densityAlphaCeiling);
      configurePrimitiveBlending(gl, x, shaderMode, layerType);
    }

    function configurePrimitive3dLayerShader(gl, programInfo, x, layerType, matrix, layer) {
      var shaderMode = shaderModeForLayer(x, layerType);
      var densityTuning = densitySplatTuning(layer && layer.rows);
      var pointScale = layerType === "points" && shaderMode === 1 ? densityTuning.pointScale : 1.6;
      var minPointSize = layerType === "points" && shaderMode === 1 ? densityTuning.minPointSize : 1.0;
      var densityAlphaBoost = layerType === "points" && shaderMode === 1 ? densityTuning.alphaBoost : 1.0;
      var densityAlphaCeiling = layerType === "points" && shaderMode === 1 ? densityTuning.alphaCeiling : 0.90;

      gl.useProgram(programInfo.program);
      gl.uniformMatrix4fv(programInfo.uniforms.viewProjection, false, new Float32Array(matrix));
      gl.uniform1f(programInfo.uniforms.shaderMode, shaderMode);
      gl.uniform1f(programInfo.uniforms.isPointLayer, layerType === "points" ? 1.0 : 0.0);
      gl.uniform1f(programInfo.uniforms.pointScale, pointScale);
      gl.uniform1f(programInfo.uniforms.minPointSize, minPointSize);
      gl.uniform1f(programInfo.uniforms.densityAlphaBoost, densityAlphaBoost);
      gl.uniform1f(programInfo.uniforms.densityAlphaCeiling, densityAlphaCeiling);
      configurePrimitiveBlending(gl, x, shaderMode, layerType);
    }

    function draw3dPointLayer(gl, programs, layer, x, viewport, box) {
      var payload = createPointLayerGpuPayloadFromFlat(gl, flattenPointLayer3d(layer, x, viewport));
      if (!payload.count) {
        disposeTransientPointPayload(payload);
        return;
      }
      var primitive = programs.primitive3d;
      configurePrimitive3dLayerShader(gl, primitive, x, "points", cameraViewProjectionMatrix(x, box), layer);
      bindAttributeBuffer(gl, primitive.attributes.position3, payload.positionBuffer, 3);
      bindAttributeBuffer(gl, primitive.attributes.size, payload.sizeBuffer, 1);
      bindAttributeBuffer(gl, primitive.attributes.age, payload.ageBuffer, 1);
      bindAttributeBuffer(gl, primitive.attributes.color, payload.colorBuffer, 4);
      bindConstantMetricAttribute(gl, primitive);
      gl.drawArrays(gl.POINTS, 0, payload.count);
      disposeTransientPointPayload(payload);
    }

    function configureRasterProgram(gl, programInfo, viewport) {
      gl.useProgram(programInfo.program);
      gl.uniform4f(programInfo.uniforms.domain, viewport.x[0], viewport.x[1], viewport.y[0], viewport.y[1]);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    }

    function drawPointLayer(gl, programs, layer, x, viewport) {
      var box = arguments.length > 5 ? arguments[5] : null;
      if (sceneDimension(x) === "3d") {
        draw3dPointLayer(gl, programs, layer, x, viewport, box);
        return;
      }
      var dynamic = sceneDimension(x) === "3d" || currentTimelineFrame(x) !== null;
      var drawViewport = viewport;
      var payload = dynamic
        ? createPointLayerGpuPayloadFromFlat(gl, flattenPointLayer(layer, x, viewport))
        : ensurePointLayerGpuPayload(gl, layer);

      if (!payload.count) {
        return;
      }

      configurePrimitiveLayerShader(gl, programs.primitive, x, "points", drawViewport, layer);
      bindAttributeBuffer(gl, programs.primitive.attributes.position, payload.positionBuffer, 2);
      bindAttributeBuffer(gl, programs.primitive.attributes.size, payload.sizeBuffer, 1);
      bindAttributeBuffer(gl, programs.primitive.attributes.age, payload.ageBuffer, 1);
      bindAttributeBuffer(gl, programs.primitive.attributes.color, payload.colorBuffer, 4);
      bindConstantMetricAttribute(gl, programs.primitive);

      gl.drawArrays(gl.POINTS, 0, payload.count);

      if (dynamic) {
        disposeTransientPointPayload(payload);
      }
    }

    function drawSelectionHighlights(gl, programs, x, panel, viewport) {
      var result = state.selection.result;
      var selectionOptions = x && x.webgl ? x.webgl.selection : null;
      if (!result || !Array.isArray(result.selections) || sceneDimension(x) === "3d" || (selectionOptions && selectionOptions.highlight === false)) {
        return;
      }

      var xs = [];
      var ys = [];
      result.selections.forEach(function(selection) {
        if (String(selection.panel_id) !== String(panel.panel_id)) {
          return;
        }
        var layer = panel.layers && panel.layers[selection.layer_index];
        if (!layer || !Array.isArray(selection.indices)) {
          return;
        }
        selection.indices.forEach(function(index) {
          if (layer.type === "points") {
            xs.push(Number(layer.x[index]));
            ys.push(Number(layer.y[index]));
          } else if (layer.type === "vectors") {
            xs.push(Number(layer.x[index]));
            ys.push(Number(layer.y[index]));
          }
        });
      });

      var n = xs.length;
      if (!n) {
        return;
      }

      var highlight = {
        type: "points",
        rows: n,
        x: xs,
        y: ys,
        size: new Array(n).fill(8.5),
        age: new Array(n).fill(1),
        rgba: []
      };
      for (var i = 0; i < n; i += 1) {
        highlight.rgba.push(15, 23, 42, 0.94);
      }

      var highlightScene = {
        webgl: Object.assign({}, x.webgl || {}, { shader: "default" }),
        render: x.render
      };
      drawPointLayer(gl, programs, highlight, highlightScene, viewport);
    }


    function drawLineLayerNative(gl, programs, layer, x, viewport) {
      var paths = linePathList(layer.paths);
      var primitive = programs.primitive;
      var shaderMode = shaderModeForLayer(x, "lines");
      var metricsByPath = computeLayerTrajectoryMetrics(layer, shaderMode);

      configurePrimitiveLayerShader(gl, primitive, x, "lines", viewport, layer);

      if (primitive.attributes.size >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.size);
        gl.vertexAttrib1f(primitive.attributes.size, 3.0);
      }

      paths.forEach(function(path, pathIndex) {
        var payload = flattenLinePath(path, x, metricsByPath[pathIndex]);

        if (!payload || payload.count < 2) {
          return;
        }

        var positionBuffer = bindPositionAttribute(gl, primitive, payload.positions);
        var ageBuffer = bindAgeAttribute(gl, primitive, payload.ages);
        var colorBuffer = bindColorAttribute(gl, primitive, payload.colors);
        var metricBuffer = bindMetricAttribute(gl, primitive, payload.metrics);

        gl.drawArrays(payload.mode === "lines" ? gl.LINES : gl.LINE_STRIP, 0, payload.count);

        gl.deleteBuffer(positionBuffer);
        gl.deleteBuffer(ageBuffer);
        gl.deleteBuffer(colorBuffer);
        gl.deleteBuffer(metricBuffer);
      });
    }

    function drawLineLayer3d(gl, programs, layer, x, viewport, box) {
      var paths = linePathList(layer.paths);
      var primitive = programs.primitive3d;
      var shaderMode = shaderModeForLayer(x, "lines");
      var metricsByPath = computeLayerTrajectoryMetrics(layer, shaderMode);
      configurePrimitive3dLayerShader(gl, primitive, x, "lines", cameraViewProjectionMatrix(x, box), layer);

      if (primitive.attributes.size >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.size);
        gl.vertexAttrib1f(primitive.attributes.size, 1.0);
      }

      paths.forEach(function(path, pathIndex) {
        var payload = flattenLinePath3d(path, x, viewport, metricsByPath[pathIndex]);
        if (!payload || payload.count < 2) {
          return;
        }
        var positionBuffer = createBuffer(gl, payload.positions);
        bindAttributeBuffer(gl, primitive.attributes.position3, positionBuffer, 3);
        var ageBuffer = bindAgeAttribute(gl, primitive, payload.ages);
        var colorBuffer = bindColorAttribute(gl, primitive, payload.colors);
        var metricBuffer = bindMetricAttribute(gl, primitive, payload.metrics);
        gl.drawArrays(payload.mode === "lines" ? gl.LINES : gl.LINE_STRIP, 0, payload.count);
        gl.deleteBuffer(positionBuffer);
        gl.deleteBuffer(ageBuffer);
        gl.deleteBuffer(colorBuffer);
        gl.deleteBuffer(metricBuffer);
      });
    }

    function drawLineLayer(gl, programs, layer, x, viewport, box) {
      var mode = lineRenderMode(x);
      var drawViewport = sceneDimension(x) === "3d" ? { x: [-1.2, 1.2], y: [-1.2, 1.2] } : viewport;

      if (sceneDimension(x) === "3d") {
        drawLineLayer3d(gl, programs, layer, x, viewport, box);
        return;
      }

      if (mode === "native") {
        drawLineLayerNative(gl, programs, layer, x, drawViewport);
        return;
      }

      var paths = linePathList(layer.paths);
      var primitive = programs.primitive;
      var plotWidthPx = Math.max(1, box && box.plotWidth ? box.plotWidth : 1);
      var plotHeightPx = Math.max(1, box && box.plotHeight ? box.plotHeight : 1);
      var joinMode = lineJoinMode(x);
      var capMode = lineCapMode(x);
      var shaderMode = shaderModeForLayer(x, "lines");
      var metricsByPath = computeLayerTrajectoryMetrics(layer, shaderMode);

      configurePrimitiveLayerShader(gl, primitive, x, "lines", drawViewport, layer);

      if (primitive.attributes.size >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.size);
        gl.vertexAttrib1f(primitive.attributes.size, 1.0);
      }

      gl.enable(gl.BLEND);
      gl.blendFuncSeparate(
        gl.SRC_ALPHA,
        gl.ONE_MINUS_SRC_ALPHA,
        gl.ONE,
        gl.ONE_MINUS_SRC_ALPHA
      );

      paths.forEach(function(path, pathIndex) {
        var payload = flattenLinePathToStyledQuads(path, drawViewport, plotWidthPx, plotHeightPx, joinMode, capMode, x, viewport, metricsByPath[pathIndex]);

        if (!payload || payload.count < 3) {
          return;
        }

        var positionBuffer = bindPositionAttribute(gl, primitive, payload.positions);
        var ageBuffer = bindAgeAttribute(gl, primitive, payload.ages);
        var colorBuffer = bindColorAttribute(gl, primitive, payload.colors);
        var metricBuffer = bindMetricAttribute(gl, primitive, payload.metrics);

        gl.drawArrays(gl.TRIANGLES, 0, payload.count);

        gl.deleteBuffer(positionBuffer);
        gl.deleteBuffer(ageBuffer);
        gl.deleteBuffer(colorBuffer);
        gl.deleteBuffer(metricBuffer);
      });
    }

    function flattenVectorLayer(layer, x, viewport, box) {
      var n = layer.rows || 0;
      var xs = layer.x || [];
      var ys = layer.y || [];
      var zs = layer.z || [];
      var xends = layer.xend || [];
      var yends = layer.yend || [];
      var zends = layer.zend || [];
      var widths = layer.width || [];
      var heads = layer.head_size || [];
      var rgba = layer.rgba || [];
      var use3d = x && sceneDimension(x) === "3d";
      var geometryViewport = use3d ? { x: [-1.2, 1.2], y: [-1.2, 1.2] } : viewport;
      var xSpan = Math.max(1e-6, geometryViewport.x[1] - geometryViewport.x[0]);
      var ySpan = Math.max(1e-6, geometryViewport.y[1] - geometryViewport.y[0]);
      var positions = [];
      var ages = [];
      var colors = [];

      function pushVertex(xValue, yValue, r, g, b, a) {
        positions.push(xValue, yValue);
        ages.push(1);
        colors.push(r, g, b, a);
      }

      for (var i = 0; i < n; i += 1) {
        if (!layerIndexVisible(layer, i, x)) {
          continue;
        }
        var start = use3d ? project3dPoint(xs[i], ys[i], zs[i] || 0, viewport, layer) : { x: Number(xs[i]), y: Number(ys[i]) };
        var end = use3d ? project3dPoint(xends[i], yends[i], zends[i] || zs[i] || 0, viewport, layer) : { x: Number(xends[i]), y: Number(yends[i]) };
        var x0 = Number(start.x), y0 = Number(start.y);
        var x1 = Number(end.x), y1 = Number(end.y);
        if (!isFinite(x0) || !isFinite(y0) || !isFinite(x1) || !isFinite(y1)) {
          continue;
        }
        var dxPx = (x1 - x0) / xSpan * box.plotWidth;
        var dyPx = (y1 - y0) / ySpan * box.plotHeight;
        var lenPx = Math.sqrt(dxPx * dxPx + dyPx * dyPx);
        if (!(lenPx > 1e-6)) {
          continue;
        }
        var tx = dxPx / lenPx;
        var ty = dyPx / lenPx;
        var nx = -ty;
        var ny = tx;
        var halfWidth = Math.max(1, Number(widths[i]) || 1.5) * 0.5;
        var head = Math.max(3, Number(heads[i]) || 8);
        var sx = xSpan / box.plotWidth;
        var sy = ySpan / box.plotHeight;
        var shaftEndX = x1 - tx * head * sx;
        var shaftEndY = y1 - ty * head * sy;
        var ox = nx * halfWidth * sx;
        var oy = ny * halfWidth * sy;
        var hx = nx * head * 0.55 * sx;
        var hy = ny * head * 0.55 * sy;
        var r = normalizeColorComponent(rgba[i * 4 + 0], 0.05);
        var g = normalizeColorComponent(rgba[i * 4 + 1], 0.1);
        var b = normalizeColorComponent(rgba[i * 4 + 2], 0.15);
        var a = normalizeColorComponent(rgba[i * 4 + 3], 1);

        pushVertex(x0 - ox, y0 - oy, r, g, b, a);
        pushVertex(x0 + ox, y0 + oy, r, g, b, a);
        pushVertex(shaftEndX - ox, shaftEndY - oy, r, g, b, a);
        pushVertex(shaftEndX - ox, shaftEndY - oy, r, g, b, a);
        pushVertex(x0 + ox, y0 + oy, r, g, b, a);
        pushVertex(shaftEndX + ox, shaftEndY + oy, r, g, b, a);

        pushVertex(x1, y1, r, g, b, a);
        pushVertex(shaftEndX + hx, shaftEndY + hy, r, g, b, a);
        pushVertex(shaftEndX - hx, shaftEndY - hy, r, g, b, a);
      }

      return {
        count: ages.length,
        positions: new Float32Array(positions),
        ages: new Float32Array(ages),
        colors: new Float32Array(colors)
      };
    }

    function drawVectorLayer(gl, programs, layer, x, viewport, box) {
      var payload = flattenVectorLayer(layer, x, viewport, box);
      var primitive = programs.primitive;
      var drawViewport = sceneDimension(x) === "3d" ? { x: [-1.2, 1.2], y: [-1.2, 1.2] } : viewport;

      if (!payload || payload.count < 3) {
        return;
      }

      configurePrimitiveLayerShader(gl, primitive, x, "vectors", drawViewport, layer);
      if (primitive.attributes.size >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.size);
        gl.vertexAttrib1f(primitive.attributes.size, 1.0);
      }

      var positionBuffer = bindPositionAttribute(gl, primitive, payload.positions);
      var ageBuffer = bindAgeAttribute(gl, primitive, payload.ages);
      var colorBuffer = bindColorAttribute(gl, primitive, payload.colors);
      bindConstantMetricAttribute(gl, primitive);
      gl.drawArrays(gl.TRIANGLES, 0, payload.count);
      gl.deleteBuffer(positionBuffer);
      gl.deleteBuffer(ageBuffer);
      gl.deleteBuffer(colorBuffer);
    }

    function meshLightDirection(layer) {
      var material = layer.material || {};
      var light = material.light_dir || [0.35, 0.45, 0.82];
      var len = Math.sqrt(light[0] * light[0] + light[1] * light[1] + light[2] * light[2]);
      if (!(len > 0)) {
        return [0.35, 0.45, 0.82];
      }
      return [light[0] / len, light[1] / len, light[2] / len];
    }

    function meshShadingMode(layer) {
      var material = layer.material || {};
      var shading = String(material.shading || "mesh_lambert");
      if (shading === "mesh_lambert" || shading === "lambert") {
        return 1;
      }
      if (shading === "mesh_phong_simple") {
        return 2;
      }
      if (shading === "mesh_scalar_colormap") {
        return 3;
      }
      if (shading === "mesh_selection_highlight") {
        return 4;
      }
      return 0;
    }

    function meshZRange(layer) {
      var bbox = layer && layer.bbox3d ? layer.bbox3d : null;
      var zMin = bbox && isFinite(Number(bbox.zmin)) ? Number(bbox.zmin) : Infinity;
      var zMax = bbox && isFinite(Number(bbox.zmax)) ? Number(bbox.zmax) : -Infinity;
      var zs = Array.isArray(layer && layer.z) ? layer.z : [];
      if (!isFinite(zMin) || !isFinite(zMax)) {
        zMin = Infinity;
        zMax = -Infinity;
        for (var i = 0; i < zs.length; i += 1) {
          var z = Number(zs[i]);
          if (isFinite(z)) {
            zMin = Math.min(zMin, z);
            zMax = Math.max(zMax, z);
          }
        }
      }
      if (!isFinite(zMin) || !isFinite(zMax)) {
        return [-1, 1];
      }
      if (zMin === zMax) {
        zMin -= 0.5;
        zMax += 0.5;
      }
      return [zMin, zMax];
    }

    function meshScalarRange(layer) {
      var source = Array.isArray(layer && layer.scalar_range) ? layer.scalar_range.map(Number) : [];
      if (source.length >= 2 && isFinite(source[0]) && isFinite(source[1]) && source[0] !== source[1]) {
        return [source[0], source[1]];
      }
      var scalars = Array.isArray(layer && layer.scalar) ? layer.scalar : [];
      var minValue = Infinity;
      var maxValue = -Infinity;
      for (var i = 0; i < scalars.length; i += 1) {
        var value = Number(scalars[i]);
        if (isFinite(value)) {
          minValue = Math.min(minValue, value);
          maxValue = Math.max(maxValue, value);
        }
      }
      if (!isFinite(minValue) || !isFinite(maxValue)) {
        return meshZRange(layer);
      }
      if (minValue === maxValue) {
        minValue -= 0.5;
        maxValue += 0.5;
      }
      return [minValue, maxValue];
    }

    function createMeshLayerGpuPayload(gl, programs, layer, viewport) {
      var vertexCount = Math.floor(Number(layer.vertex_count) || 0);
      var xs = Array.isArray(layer.x) ? layer.x : [];
      var ys = Array.isArray(layer.y) ? layer.y : [];
      var zs = Array.isArray(layer.z) ? layer.z : [];
      var normals = Array.isArray(layer.normal) ? layer.normal : [];
      var rgba = Array.isArray(layer.rgba) ? layer.rgba : [];
      var scalars = Array.isArray(layer.scalar) ? layer.scalar : [];
      var indices = layer.indices || [];
      var wireIndices = Array.isArray(layer.wire_indices) ? layer.wire_indices : [];
      var zRange = meshZRange(layer);
      var normalizedPositions = [];
      var normalizedNormals = [];
      var normalizedColors = [];
      var normalizedScalars = [];

      if (!vertexCount || indices.length < 3) {
        return null;
      }

      for (var i = 0; i < vertexCount; i += 1) {
        var p = normalizePosition3(xs[i], ys[i], zs[i] || 0, viewport, zRange);
        normalizedPositions.push(p[0], p[1], p[2]);
        normalizedNormals.push(
          isFinite(Number(normals[i * 3])) ? Number(normals[i * 3]) : 0,
          isFinite(Number(normals[i * 3 + 1])) ? Number(normals[i * 3 + 1]) : 0,
          isFinite(Number(normals[i * 3 + 2])) ? Number(normals[i * 3 + 2]) : 1
        );
        normalizedColors.push(
          normalizeColorComponent(rgba[i * 4 + 0], 0.35),
          normalizeColorComponent(rgba[i * 4 + 1], 0.55),
          normalizeColorComponent(rgba[i * 4 + 2], 0.78),
          normalizeColorComponent(rgba[i * 4 + 3], 0.92)
        );
        normalizedScalars.push(isFinite(Number(scalars[i])) ? Number(scalars[i]) : (isFinite(Number(zs[i])) ? Number(zs[i]) : 0));
      }

      var maxIndex = indices.reduce(function(maxValue, value) {
        return Math.max(maxValue, Math.floor(Number(value)) || 0);
      }, 0);
      var uintExtension = maxIndex > 65535 ? gl.getExtension("OES_element_index_uint") : null;
      var useUint = maxIndex > 65535 && !!uintExtension;
      var canUseElements = maxIndex <= 65535 || useUint;

      if (!canUseElements) {
        var expandedPositions = [];
        var expandedNormals = [];
        var expandedColors = [];
        var expandedScalars = [];
        for (var ti = 0; ti < indices.length; ti += 1) {
          var idx = Math.floor(Number(indices[ti])) || 0;
          expandedPositions.push(
            normalizedPositions[idx * 3],
            normalizedPositions[idx * 3 + 1],
            normalizedPositions[idx * 3 + 2]
          );
          expandedNormals.push(
            normalizedNormals[idx * 3],
            normalizedNormals[idx * 3 + 1],
            normalizedNormals[idx * 3 + 2]
          );
          expandedColors.push(
            normalizedColors[idx * 4],
            normalizedColors[idx * 4 + 1],
            normalizedColors[idx * 4 + 2],
            normalizedColors[idx * 4 + 3]
          );
          expandedScalars.push(normalizedScalars[idx]);
        }
        el.ggwebglMeshIndexFallback = "uint_index_unavailable_expanded_arrays";
        return {
          expanded: true,
          count: expandedScalars.length,
          positionBuffer: createBuffer(gl, new Float32Array(expandedPositions)),
          normalBuffer: createBuffer(gl, new Float32Array(expandedNormals)),
          colorBuffer: createBuffer(gl, new Float32Array(expandedColors)),
          scalarBuffer: createBuffer(gl, new Float32Array(expandedScalars)),
          scalarRange: meshScalarRange(layer)
        };
      }

      return {
        expanded: false,
        count: Math.floor(indices.length / 3) * 3,
        indexType: useUint ? gl.UNSIGNED_INT : gl.UNSIGNED_SHORT,
        positionBuffer: createBuffer(gl, new Float32Array(normalizedPositions)),
        normalBuffer: createBuffer(gl, new Float32Array(normalizedNormals)),
        colorBuffer: createBuffer(gl, new Float32Array(normalizedColors)),
        scalarBuffer: createBuffer(gl, new Float32Array(normalizedScalars)),
        indexBuffer: createElementBuffer(gl, useUint ? new Uint32Array(indices) : new Uint16Array(indices)),
        wireIndexBuffer: wireIndices.length ? createElementBuffer(gl, useUint ? new Uint32Array(wireIndices) : new Uint16Array(wireIndices)) : null,
        wireCount: wireIndices.length,
        scalarRange: meshScalarRange(layer)
      };
    }

    function disposeMeshLayerGpuPayload(gl, payload) {
      if (!payload) {
        return;
      }
      [
        payload.positionBuffer,
        payload.normalBuffer,
        payload.colorBuffer,
        payload.scalarBuffer,
        payload.indexBuffer,
        payload.wireIndexBuffer
      ].forEach(function(buffer) {
        if (buffer) {
          gl.deleteBuffer(buffer);
        }
      });
    }

    function ensureMeshLayerGpuPayload(gl, programs, layer, viewport) {
      var cameraKey = JSON.stringify({
        viewport: viewport,
        rotation: state.camera.rotation,
        target: state.camera.target,
        distance: state.camera.distance,
        material: layer.material,
        scalar_range: layer.scalar_range,
        wireframe: layer.wireframe
      });
      if (layer._meshGpuPayload && layer._meshGpuPayload.key === cameraKey) {
        return layer._meshGpuPayload;
      }
      disposeMeshLayerGpuPayload(gl, layer._meshGpuPayload);
      var payload = createMeshLayerGpuPayload(gl, programs, layer, viewport);
      if (payload) {
        payload.key = cameraKey;
      }
      layer._meshGpuPayload = payload;
      return payload;
    }

    function configureMeshProgram(gl, programInfo, x, matrix, layer, payload) {
      var material = layer.material || {};
      var light = meshLightDirection(layer);
      var range = payload && payload.scalarRange ? payload.scalarRange : meshScalarRange(layer);
      gl.useProgram(programInfo.program);
      gl.uniformMatrix4fv(programInfo.uniforms.viewProjection, false, new Float32Array(matrix));
      gl.uniform1f(programInfo.uniforms.shadingMode, meshShadingMode(layer));
      gl.uniform3f(programInfo.uniforms.lightDir, light[0], light[1], light[2]);
      gl.uniform2f(programInfo.uniforms.scalarRange, range[0], range[1]);
      gl.uniform1f(programInfo.uniforms.ambient, isFinite(Number(material.ambient)) ? Number(material.ambient) : 0.35);
      gl.uniform1f(programInfo.uniforms.diffuse, isFinite(Number(material.diffuse)) ? Number(material.diffuse) : 0.75);
      gl.uniform1f(programInfo.uniforms.specular, isFinite(Number(material.specular)) ? Number(material.specular) : 0.25);
      configurePrimitiveBlending(gl, x, 0, "mesh");
    }

    function drawMeshLayer(gl, programs, layer, x, viewport, box) {
      var payload = ensureMeshLayerGpuPayload(gl, programs, layer, viewport);
      var mesh = programs.mesh;

      if (!payload || !mesh || !mesh.program || payload.count < 3) {
        return;
      }

      configureMeshProgram(gl, mesh, x, cameraViewProjectionMatrix(x, box), layer, payload);
      bindAttributeBuffer(gl, mesh.attributes.position3, payload.positionBuffer, 3);
      bindAttributeBuffer(gl, mesh.attributes.normal, payload.normalBuffer, 3);
      bindAttributeBuffer(gl, mesh.attributes.color, payload.colorBuffer, 4);
      bindAttributeBuffer(gl, mesh.attributes.scalar, payload.scalarBuffer, 1);

      if (layer.material && layer.material.cull === "back") {
        gl.enable(gl.CULL_FACE);
        gl.cullFace(gl.BACK);
      } else {
        gl.disable(gl.CULL_FACE);
      }

      if (payload.expanded) {
        gl.drawArrays(gl.TRIANGLES, 0, payload.count);
      } else {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, payload.indexBuffer);
        gl.drawElements(gl.TRIANGLES, payload.count, payload.indexType, 0);
      }

      if (layer.wireframe && payload.wireIndexBuffer && payload.wireCount > 0) {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, payload.wireIndexBuffer);
        gl.drawElements(gl.LINES, payload.wireCount, payload.indexType, 0);
      }
      gl.disable(gl.CULL_FACE);
    }

    function surfaceShadingMode(layer) {
      var shading = layer && layer.surface_meta ? String(layer.surface_meta.shading || "") : "";
      if (shading === "surface_lambert") {
        return 1;
      }
      if (shading === "surface_height_colormap") {
        return 2;
      }
      if (shading === "surface_uncertainty_alpha") {
        return 3;
      }
      return 0;
    }

    function surfaceZRange(layer) {
      var source = layer && layer.surface_meta && Array.isArray(layer.surface_meta.z_range)
        ? layer.surface_meta.z_range.map(Number)
        : [];
      if (source.length >= 2 && isFinite(source[0]) && isFinite(source[1]) && source[0] !== source[1]) {
        return [source[0], source[1]];
      }
      var positions = layer && Array.isArray(layer.positions) ? layer.positions : [];
      var zMin = Infinity;
      var zMax = -Infinity;
      for (var i = 2; i < positions.length; i += 3) {
        var z = Number(positions[i]);
        if (isFinite(z)) {
          zMin = Math.min(zMin, z);
          zMax = Math.max(zMax, z);
        }
      }
      if (!isFinite(zMin) || !isFinite(zMax)) {
        return [-1, 1];
      }
      if (zMin === zMax) {
        zMin -= 0.5;
        zMax += 0.5;
      }
      return [zMin, zMax];
    }

    function surfaceLightDir(layer) {
      var source = layer && layer.material && Array.isArray(layer.material.light_dir)
        ? layer.material.light_dir.map(Number)
        : [0.35, 0.45, 0.82];
      while (source.length < 3) {
        source.push(source.length === 2 ? 1 : 0);
      }
      var len = Math.sqrt(source[0] * source[0] + source[1] * source[1] + source[2] * source[2]);
      if (!(len > 0)) {
        return [0.35, 0.45, 0.82];
      }
      return [source[0] / len, source[1] / len, source[2] / len];
    }

    function createSurfaceLayerGpuPayload(gl, layer, viewport) {
      var vertexCount = Math.floor(Number(layer.vertex_count) || 0);
      var positions = Array.isArray(layer.positions) ? layer.positions : [];
      var normals = Array.isArray(layer.normals) ? layer.normals : [];
      var colors = Array.isArray(layer.colors) ? layer.colors : [];
      var uncertainty = Array.isArray(layer.uncertainty) ? layer.uncertainty : [];
      var indices = Array.isArray(layer.indices) ? layer.indices : [];
      var wireIndices = Array.isArray(layer.wire_indices) ? layer.wire_indices : [];
      var zRange = surfaceZRange(layer);
      var normalizedPositions = [];
      var normalizedNormals = [];
      var normalizedColors = [];
      var normalizedUncertainty = [];

      for (var i = 0; i < vertexCount; i += 1) {
        var p = normalizePosition3(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2], viewport, zRange);
        normalizedPositions.push(p[0], p[1], p[2]);
        normalizedNormals.push(
          isFinite(Number(normals[i * 3])) ? Number(normals[i * 3]) : 0,
          isFinite(Number(normals[i * 3 + 1])) ? Number(normals[i * 3 + 1]) : 0,
          isFinite(Number(normals[i * 3 + 2])) ? Number(normals[i * 3 + 2]) : 1
        );
        normalizedColors.push(
          normalizeColorComponent(colors[i * 4], 0.45),
          normalizeColorComponent(colors[i * 4 + 1], 0.55),
          normalizeColorComponent(colors[i * 4 + 2], 0.65),
          normalizeColorComponent(colors[i * 4 + 3], 0.95)
        );
        normalizedUncertainty.push(normalizeColorComponent(uncertainty[i], 0));
      }

      var maxIndex = indices.reduce(function(maxValue, value) {
        return Math.max(maxValue, Math.floor(Number(value)) || 0);
      }, 0);
      var uintExtension = maxIndex > 65535 ? gl.getExtension("OES_element_index_uint") : null;
      var useUint = maxIndex > 65535 && !!uintExtension;
      var canUseElements = maxIndex <= 65535 || useUint;
      if (!canUseElements) {
        var expandedPositions = [];
        var expandedNormals = [];
        var expandedColors = [];
        var expandedUncertainty = [];
        for (var ti = 0; ti < indices.length; ti += 1) {
          var idx = Math.floor(Number(indices[ti])) || 0;
          expandedPositions.push(
            normalizedPositions[idx * 3],
            normalizedPositions[idx * 3 + 1],
            normalizedPositions[idx * 3 + 2]
          );
          expandedNormals.push(
            normalizedNormals[idx * 3],
            normalizedNormals[idx * 3 + 1],
            normalizedNormals[idx * 3 + 2]
          );
          expandedColors.push(
            normalizedColors[idx * 4],
            normalizedColors[idx * 4 + 1],
            normalizedColors[idx * 4 + 2],
            normalizedColors[idx * 4 + 3]
          );
          expandedUncertainty.push(normalizedUncertainty[idx]);
        }
        el.ggwebglSurfaceIndexFallback = "uint_index_unavailable_expanded_arrays";
        return {
          expanded: true,
          count: expandedUncertainty.length,
          positionBuffer: createBuffer(gl, new Float32Array(expandedPositions)),
          normalBuffer: createBuffer(gl, new Float32Array(expandedNormals)),
          colorBuffer: createBuffer(gl, new Float32Array(expandedColors)),
          uncertaintyBuffer: createBuffer(gl, new Float32Array(expandedUncertainty)),
          zRange: zRange
        };
      }

      return {
        expanded: false,
        count: Math.floor(indices.length / 3) * 3,
        indexType: useUint ? gl.UNSIGNED_INT : gl.UNSIGNED_SHORT,
        positionBuffer: createBuffer(gl, new Float32Array(normalizedPositions)),
        normalBuffer: createBuffer(gl, new Float32Array(normalizedNormals)),
        colorBuffer: createBuffer(gl, new Float32Array(normalizedColors)),
        uncertaintyBuffer: createBuffer(gl, new Float32Array(normalizedUncertainty)),
        indexBuffer: createElementBuffer(gl, useUint ? new Uint32Array(indices) : new Uint16Array(indices)),
        wireIndexBuffer: wireIndices.length ? createElementBuffer(gl, useUint ? new Uint32Array(wireIndices) : new Uint16Array(wireIndices)) : null,
        wireCount: wireIndices.length,
        zRange: zRange
      };
    }

    function disposeSurfaceLayerGpuPayload(gl, payload) {
      if (!payload || !gl) {
        return;
      }
      [
        payload.positionBuffer,
        payload.normalBuffer,
        payload.colorBuffer,
        payload.uncertaintyBuffer,
        payload.indexBuffer,
        payload.wireIndexBuffer
      ].forEach(function(buffer) {
        if (buffer) {
          gl.deleteBuffer(buffer);
        }
      });
    }

    function ensureSurfaceLayerGpuPayload(gl, layer, viewport) {
      var key = JSON.stringify({
        viewport: viewport,
        positions: layer.positions && layer.positions.length,
        indices: layer.indices && layer.indices.length,
        shading: layer.surface_meta && layer.surface_meta.shading,
        wireframe: layer.wireframe
      });
      if (layer._surfaceGpuPayload && layer._surfaceGpuPayload.key === key) {
        return layer._surfaceGpuPayload;
      }
      disposeSurfaceLayerGpuPayload(gl, layer._surfaceGpuPayload);
      var payload = createSurfaceLayerGpuPayload(gl, layer, viewport);
      if (payload) {
        payload.key = key;
      }
      layer._surfaceGpuPayload = payload;
      return payload;
    }

    function configureSurfaceProgram(gl, programInfo, x, matrix, layer, payload) {
      var light = surfaceLightDir(layer);
      var zRange = payload && payload.zRange ? payload.zRange : surfaceZRange(layer);
      gl.useProgram(programInfo.program);
      gl.uniformMatrix4fv(programInfo.uniforms.viewProjection, false, new Float32Array(matrix));
      gl.uniform1f(programInfo.uniforms.shadingMode, surfaceShadingMode(layer));
      gl.uniform3f(programInfo.uniforms.lightDir, light[0], light[1], light[2]);
      gl.uniform2f(programInfo.uniforms.zRange, zRange[0], zRange[1]);
      configurePrimitiveBlending(gl, x, 0, "surface");
    }

    function drawSurfaceLayer(gl, programs, layer, scene, panel, viewport, box) {
      var payload = ensureSurfaceLayerGpuPayload(gl, layer, viewport);
      var surface = programs.surface;
      if (!payload || !surface || !surface.program || payload.count < 3) {
        return;
      }

      configureSurfaceProgram(gl, surface, scene, cameraViewProjectionMatrix(scene, box), layer, payload);
      bindAttributeBuffer(gl, surface.attributes.position3, payload.positionBuffer, 3);
      bindAttributeBuffer(gl, surface.attributes.normal, payload.normalBuffer, 3);
      bindAttributeBuffer(gl, surface.attributes.color, payload.colorBuffer, 4);
      bindAttributeBuffer(gl, surface.attributes.uncertainty, payload.uncertaintyBuffer, 1);

      if (layer.material && layer.material.cull === "back") {
        gl.enable(gl.CULL_FACE);
        gl.cullFace(gl.BACK);
      } else {
        gl.disable(gl.CULL_FACE);
      }

      if (payload.expanded) {
        gl.drawArrays(gl.TRIANGLES, 0, payload.count);
      } else {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, payload.indexBuffer);
        gl.drawElements(gl.TRIANGLES, payload.count, payload.indexType, 0);
      }

      if (layer.wireframe && payload.wireIndexBuffer && payload.wireCount > 0) {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, payload.wireIndexBuffer);
        gl.drawElements(gl.LINES, payload.wireCount, payload.indexType, 0);
      }

      gl.disable(gl.CULL_FACE);

      if (Array.isArray(layer.contours) && layer.contours.length) {
        drawLineLayer(gl, programs, {
          type: "lines",
          rows: layer.contours.reduce(function(total, path) { return total + path.rows; }, 0),
          path_count: layer.contours.length,
          paths: layer.contours
        }, scene, viewport, box);
      }
    }

    function drawRasterLayer(gl, programs, layer, viewport) {
      var payload = flattenRasterLayer(layer);

      if (!payload.width || !payload.height || !payload.pixels.length) {
        return;
      }

      var positions = new Float32Array([
        payload.xmin, payload.ymin,
        payload.xmax, payload.ymin,
        payload.xmin, payload.ymax,
        payload.xmax, payload.ymax
      ]);
      var texcoords = new Float32Array([
        0, 0,
        1, 0,
        0, 1,
        1, 1
      ]);

      configureRasterProgram(gl, programs.raster, viewport);
      var positionBuffer = bindPositionAttribute(gl, programs.raster, positions);
      var texcoordBuffer = bindTexcoordAttribute(gl, programs.raster, texcoords);
      var texture = gl.createTexture();

      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, payload.interpolate ? gl.LINEAR : gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, payload.interpolate ? gl.LINEAR : gl.NEAREST);
      gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        payload.width,
        payload.height,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        payload.pixels
      );
      gl.uniform1i(programs.raster.uniforms.texture, 0);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

      gl.deleteTexture(texture);
      gl.deleteBuffer(positionBuffer);
      gl.deleteBuffer(texcoordBuffer);
    }

    function getProgramForLayer(programRegistry, layer, material, scene) {
      if (window.ggWebGLProgramRegistry &&
          typeof window.ggWebGLProgramRegistry.getProgramForLayer === "function") {
        return window.ggWebGLProgramRegistry.getProgramForLayer(programRegistry, layer, material, scene);
      }
      if (layer && layer.type === "raster") {
        return programRegistry.raster;
      }
      if (layer && layer.type === "surface") {
        return programRegistry.surface;
      }
      if (layer && layer.type === "mesh") {
        return programRegistry.mesh;
      }
      return programRegistry.primitive;
    }

    function drawPointsLayer(gl, programs, layer, scene, panel, viewport, box) {
      drawPointLayer(gl, programs, layer, scene, viewport, box);
    }

    function drawLinesLayer(gl, programs, layer, scene, panel, viewport, box) {
      drawLineLayer(gl, programs, layer, scene, viewport, box);
    }

    function drawRasterLayerTyped(gl, programs, layer, scene, panel, viewport, box) {
      drawRasterLayer(gl, programs, layer, viewport);
    }

    function drawVectorsLayer(gl, programs, layer, scene, panel, viewport, box) {
      drawVectorLayer(gl, programs, layer, scene, viewport, box);
    }

    function drawMeshLayerTyped(gl, programs, layer, scene, panel, viewport, box) {
      drawMeshLayer(gl, programs, layer, scene, viewport, box);
    }

    function drawLayer(gl, programs, layer, scene, panel, viewport, box) {
      var programInfo = getProgramForLayer(programs, layer, layer && layer.material, scene);
      if (!programInfo) {
        return;
      }
      if (!layer || !layer.type) {
        return;
      }
      if (layer.type === "raster") {
        drawRasterLayerTyped(gl, programs, layer, scene, panel, viewport, box);
      } else if (layer.type === "lines") {
        drawLinesLayer(gl, programs, layer, scene, panel, viewport, box);
      } else if (layer.type === "vectors") {
        drawVectorsLayer(gl, programs, layer, scene, panel, viewport, box);
      } else if (layer.type === "mesh") {
        drawMeshLayerTyped(gl, programs, layer, scene, panel, viewport, box);
      } else if (layer.type === "surface") {
        drawSurfaceLayer(gl, programs, layer, scene, panel, viewport, box);
      } else if (layer.type === "points") {
        drawPointsLayer(gl, programs, layer, scene, panel, viewport, box);
      }
    }

    function drawScene(x) {
      var panels = panelList(x);

      if (!panels.length) {
        setEmpty("No supported point, line, raster, vector, mesh, or surface layers are available for rendering yet.");
        return;
      }

      var gl = ensureGl(x);

      if (!gl) {
        setEmpty("WebGL is unavailable in this browser context.");
        return;
      }

      resizeCanvas();
      
      if (!isFinite(state.canvas.width) || !isFinite(state.canvas.height) ||
    	state.canvas.width < 1 || state.canvas.height < 1) {
  		setEmpty("Invalid canvas size.");
  		return;
	  }

      clearEmpty();
      renderPanelOverlay(x);
      var canvasMetrics = getCanvasScale();
      var rect = canvasMetrics.rect;
      var scaleX = canvasMetrics.scaleX;
      var scaleY = canvasMetrics.scaleY;
      var programs = ensurePrograms(gl);
      var boxes = panelBoxes(x);

      gl.disable(gl.SCISSOR_TEST);
      gl.viewport(0, 0, state.canvas.width, state.canvas.height);
	  gl.clearColor(1.0, 1.0, 1.0, 1.0);
      if (depthTestEnabled(x)) {
        gl.enable(gl.DEPTH_TEST);
        gl.depthFunc(gl.LEQUAL);
        gl.clearDepth(1.0);
      } else {
        gl.disable(gl.DEPTH_TEST);
      }
      gl.clear(depthTestEnabled(x) ? (gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT) : gl.COLOR_BUFFER_BIT);
      gl.enable(gl.BLEND);

      boxes.forEach(function(box) {
        var panel = box.panel;
        var viewport = currentViewport(panel);
        var scissorX = Math.round(box.plotLeft * scaleX);
        var scissorWidth = Math.max(1, Math.round(box.plotWidth * scaleX));
        var scissorHeight = Math.max(1, Math.round(box.plotHeight * scaleY));
        var scissorY = Math.round((rect.height - box.plotBottom) * scaleY);

        gl.enable(gl.SCISSOR_TEST);
        gl.scissor(scissorX, scissorY, scissorWidth, scissorHeight);
        gl.viewport(scissorX, scissorY, scissorWidth, scissorHeight);
        if (depthTestEnabled(x)) {
          gl.clear(gl.DEPTH_BUFFER_BIT);
        }

        (panel.layers || []).forEach(function(layer) {
          drawLayer(gl, programs, layer, x, panel, viewport, box);
        });
        drawSelectionHighlights(gl, programs, x, panel, viewport);
      });

      gl.disable(gl.SCISSOR_TEST);
    }

    return {
      renderValue: function(x) {
        createDom();
        var next = normalizeScenePayload(x);
        disposeSceneResources(state.x);
        state.baseDomains = {};
        state.x = next;
        state.selection.active = false;
        state.selection.result = null;
        state.timeline = createTimelineState(next, state.timeline);
        registerShinyTimelineHandler();
        applyWidgetSize(width, height);
        resetViewport(null);
        initialiseCameraFromScene(next);
        
		requestAnimationFrame(function() {
    	  redrawCurrent();
          scheduleTimelineTick();
	    });
      },

      resize: function(newWidth, newHeight) {
	  applyWidgetSize(newWidth, newHeight);

		requestAnimationFrame(function() {
    	  redrawCurrent();
	    });
      }
    };
  }
});
