HTMLWidgets.widget({
  name: "ggWebGL",
  type: "output",

  factory: function(el, width, height) {
    var state = {
      root: null,
      title: null,
      subtitle: null,
      meta: null,
      stage: null,
      canvas: null,
      panelOverlayBack: null,
	  panelOverlayFront: null,
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
      }
    };

    function getStageRect() {
      if (!state.stage) {
        return { left: 0, top: 0, width: 0, height: 0 };
      }

      return state.stage.getBoundingClientRect();
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
          : "auto minmax(0, 1fr) auto auto";
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
      "uniform vec4 u_domain;",
      "uniform float u_point_scale;",
      "uniform float u_min_point_size;",
      "varying vec4 v_color;",
      "varying float v_age;",
      "void main() {",
      "  float xSpan = max(1e-6, u_domain.y - u_domain.x);",
      "  float ySpan = max(1e-6, u_domain.w - u_domain.z);",
      "  float clipX = ((a_position.x - u_domain.x) / xSpan) * 2.0 - 1.0;",
      "  float clipY = ((a_position.y - u_domain.z) / ySpan) * 2.0 - 1.0;",
      "  gl_Position = vec4(clipX, clipY, 0.0, 1.0);",
      "  gl_PointSize = max(u_min_point_size, a_size * u_point_scale);",
      "  v_color = a_color;",
      "  v_age = a_age;",
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
	  "  if (u_shader_mode > 2.5) {",
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
      }

      var lineMode = String(source.line_mode || extra.line_mode || "auto").toLowerCase();
      var lineJoin = String(source.line_join || extra.line_join || "bevel").toLowerCase();
      var lineCap = String(source.line_cap || extra.line_cap || "round").toLowerCase();
      var rendering = String(source.rendering || "visualization").toLowerCase();
      var panelOverlay = String(source.panel_overlay || "auto").toLowerCase();
      var interactions = normalizeStringArray(source.interactions);

      if (["visualization", "publication"].indexOf(rendering) === -1) {
        rendering = "visualization";
      }

      if (!interactions.length && rendering === "visualization") {
        interactions = ["pan", "zoom"];
      }

      if (["auto", "show", "hide"].indexOf(panelOverlay) === -1) {
        panelOverlay = "auto";
      }

      return {
        shader: shader,
        antialias: source.antialias !== false,
        transparent: source.transparent !== undefined ? source.transparent !== false : rendering !== "publication",
        buffer_size: Number(source.buffer_size) || 65536,
        interactions: interactions,
        rendering: rendering,
        panel_overlay: panelOverlay,
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
      var ages = Array.isArray(source.age) ? source.age.map(Number) : [];
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
        width: isFinite(Number(source.width)) ? Number(source.width) : 1,
        age: ages.slice(0, count),
        rgba: rgba.slice(0, count * 4)
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
          size: pointSize.slice(0, pointCount),
          age: pointAge.slice(0, pointCount),
          label: pointLabel.slice(0, pointCount),
          rgba: pointRgba.slice(0, pointCount * 4)
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

      var empty = document.createElement("div");
      empty.className = "ggwebgl__empty";

      var tooltip = document.createElement("div");
      tooltip.className = "ggwebgl__tooltip";

	  stage.appendChild(panelOverlayBack);
	  stage.appendChild(canvas);
	  stage.appendChild(panelOverlayFront);
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

      root.appendChild(header);
      root.appendChild(stage);
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
      state.empty = empty;
      state.tooltip = tooltip;
      state.axes = axes;
      state.notes = notes;

      ensureWidgetLayout();

      bindInteractionHandlers();
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
      var lines = [
        "<div class='ggwebgl__tooltip-title'>" +
          escapeHtml(target.type === "point" ? "Point sample" : "Trajectory sample") +
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
        }
      });

      return best;
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
      var hints = [];
      var publication = publicationMode(x);

      state.root.classList.toggle("ggwebgl--pan-enabled", !publication && canPan);
      state.root.classList.toggle("ggwebgl--zoom-enabled", canZoom);
      state.root.classList.toggle("ggwebgl--hover-enabled", !publication && canHover);
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

      state.stage.title = publication || !hints.length
        ? ""
        : "Interactive controls: " + hints.join(", ");
    }

    function redrawCurrent() {
      if (!state.x) {
        return;
      }

      hideTooltip();
      updateLabels(state.x);

      try {
        drawScene(state.x);
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
        if (!state.x || !hasInteraction(state.x, "pan")) {
          return;
        }

        if (event.pointerType === "mouse" && event.button !== 0) {
          return;
        }

        var box = panelAtClient(event.clientX, event.clientY, state.x, true);

        if (!box) {
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
        if (event.pointerId === state.drag.pointerId) {
          endDrag();
        }
      });

      state.stage.addEventListener("pointercancel", function(event) {
        if (event.pointerId === state.drag.pointerId) {
          endDrag();
        }
      });

      state.stage.addEventListener("lostpointercapture", function() {
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
      var rasterProgram = createProgram(gl, rasterVertexShaderSource, rasterFragmentShaderSource);

      state.programs = {
        primitive: {
          program: primitiveProgram,
          attributes: {
            position: gl.getAttribLocation(primitiveProgram, "a_position"),
            size: gl.getAttribLocation(primitiveProgram, "a_size"),
            color: gl.getAttribLocation(primitiveProgram, "a_color"),
            age: gl.getAttribLocation(primitiveProgram, "a_age")
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

    function disposeSceneResources(x) {
      var panels = panelList(x);

      panels.forEach(function(panel) {
        (panel.layers || []).forEach(function(layer) {
          if (layer.type === "points") {
            disposePointLayerPayload(layer);
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

    function flattenPointLayer(layer) {
      var n = layer.rows || 0;
      var xs = layer.x || [];
      var ys = layer.y || [];
      var sizes = layer.size || [];
      var ages = layer.age || [];
      var rgba = layer.rgba || [];
      var positions = new Float32Array(n * 2);
      var pointSizes = new Float32Array(n);
      var pointAges = new Float32Array(n);
      var colors = new Float32Array(n * 4);

      for (var i = 0; i < n; i += 1) {
        positions[i * 2] = Number(xs[i]);
        positions[i * 2 + 1] = Number(ys[i]);
        pointSizes[i] = isFinite(sizes[i]) ? Number(sizes[i]) : 1.0;
        pointAges[i] = isFinite(ages[i]) ? Number(ages[i]) : 1.0;

        colors[i * 4 + 0] = normalizeColorComponent(rgba[i * 4 + 0], 0.0);
        colors[i * 4 + 1] = normalizeColorComponent(rgba[i * 4 + 1], 0.0);
        colors[i * 4 + 2] = normalizeColorComponent(rgba[i * 4 + 2], 0.0);
        colors[i * 4 + 3] = normalizeColorComponent(rgba[i * 4 + 3], 1.0);
      }

      return {
        count: n,
        positions: positions,
        sizes: pointSizes,
        ages: pointAges,
        colors: colors
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

		function flattenLinePath(path) {
		  var xs = Array.isArray(path.x) ? path.x : [];
		  var ys = Array.isArray(path.y) ? path.y : [];
		  var ages = Array.isArray(path.age) ? path.age : [];
		  var rgba = Array.isArray(path.rgba) ? path.rgba : [];
		
		  var n = Math.min(xs.length, ys.length);
		
		  if (!n) {
			return {
			  count: 0,
			  positions: new Float32Array(0),
			  ages: new Float32Array(0),
			  colors: new Float32Array(0)
			};
		  }
		
		  var positions = new Float32Array(n * 2);
		  var pathAges = new Float32Array(n);
		  var colors = new Float32Array(n * 4);
		
		  for (var i = 0; i < n; i += 1) {
			positions[i * 2] = Number(xs[i]);
			positions[i * 2 + 1] = Number(ys[i]);
		
			pathAges[i] = isFinite(ages[i]) ? Number(ages[i]) : 1.0;
		
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
			positions: positions,
			ages: pathAges,
			colors: colors
		  };
		}

    function flattenLinePathToStyledQuads(path, viewport, plotWidthPx, plotHeightPx, joinMode, capMode) {
      var xs = Array.isArray(path.x) ? path.x : [];
      var ys = Array.isArray(path.y) ? path.y : [];
      var ages = Array.isArray(path.age) ? path.age : [];
      var rgba = Array.isArray(path.rgba) ? path.rgba : [];

      var n = Math.min(xs.length, ys.length);

      if (n < 2 || !isFinite(plotWidthPx) || !isFinite(plotHeightPx) || plotWidthPx <= 0 || plotHeightPx <= 0) {
        return {
          count: 0,
          positions: new Float32Array(0),
          ages: new Float32Array(0),
          colors: new Float32Array(0)
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
      var colors = [];

      function pushVertex(x, y, age, r, g, b, a) {
        positions.push(x, y);
        outAges.push(isFinite(age) ? age : 1.0);
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
        var x0 = Number(xs[i0]), y0 = Number(ys[i0]);
        var x1 = Number(xs[i1]), y1 = Number(ys[i1]);

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

        pushVertex(x0 - off.x, y0 - off.y, a0, c0[0], c0[1], c0[2], c0[3]);
        pushVertex(x0 + off.x, y0 + off.y, a0, c0[0], c0[1], c0[2], c0[3]);
        pushVertex(x1 - off.x, y1 - off.y, a1, c1[0], c1[1], c1[2], c1[3]);
        pushVertex(x1 - off.x, y1 - off.y, a1, c1[0], c1[1], c1[2], c1[3]);
        pushVertex(x0 + off.x, y0 + off.y, a0, c0[0], c0[1], c0[2], c0[3]);
        pushVertex(x1 + off.x, y1 + off.y, a1, c1[0], c1[1], c1[2], c1[3]);
      }

      function addBevelJoin(i) {
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

        pushVertex(x0, y0, a, c[0], c[1], c[2], c[3]);
        pushVertex(x0 + outward0.x, y0 + outward0.y, a, c[0], c[1], c[2], c[3]);
        pushVertex(x0 + outward1.x, y0 + outward1.y, a, c[0], c[1], c[2], c[3]);
      }

      function addRoundCap(index, atEnd) {
        if (capMode !== "round") {
          return;
        }

        var neighbor = atEnd ? index - 1 : index + 1;
        if (neighbor < 0 || neighbor >= n) {
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

        for (var s = 0; s < capSegments; s += 1) {
          var t0 = start + (stop - start) * (s / capSegments);
          var t1 = start + (stop - start) * ((s + 1) / capSegments);
          var off0 = pixelOffsetToData(Math.cos(t0), Math.sin(t0));
          var off1 = pixelOffsetToData(Math.cos(t1), Math.sin(t1));
          pushVertex(x0, y0, a, c[0], c[1], c[2], c[3]);
          pushVertex(x0 + off0.x, y0 + off0.y, a, c[0], c[1], c[2], c[3]);
          pushVertex(x0 + off1.x, y0 + off1.y, a, c[0], c[1], c[2], c[3]);
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

      if (layerType === "points") {
        gl.enable(gl.BLEND);

        if (shaderMode === 1) {
          gl.blendEquation(gl.FUNC_ADD);
          gl.blendFuncSeparate(
            gl.SRC_ALPHA,
            gl.ONE_MINUS_SRC_ALPHA,
            gl.ONE,
            gl.ONE_MINUS_SRC_ALPHA
          );
        } else {
          gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
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

    function configureRasterProgram(gl, programInfo, viewport) {
      gl.useProgram(programInfo.program);
      gl.uniform4f(programInfo.uniforms.domain, viewport.x[0], viewport.x[1], viewport.y[0], viewport.y[1]);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    }

    function drawPointLayer(gl, programs, layer, x, viewport) {
      var payload = ensurePointLayerGpuPayload(gl, layer);

      if (!payload.count) {
        return;
      }

      configurePrimitiveLayerShader(gl, programs.primitive, x, "points", viewport, layer);
      bindAttributeBuffer(gl, programs.primitive.attributes.position, payload.positionBuffer, 2);
      bindAttributeBuffer(gl, programs.primitive.attributes.size, payload.sizeBuffer, 1);
      bindAttributeBuffer(gl, programs.primitive.attributes.age, payload.ageBuffer, 1);
      bindAttributeBuffer(gl, programs.primitive.attributes.color, payload.colorBuffer, 4);

      gl.drawArrays(gl.POINTS, 0, payload.count);
    }


    function drawLineLayerNative(gl, programs, layer, x, viewport) {
      var paths = linePathList(layer.paths);
      var primitive = programs.primitive;

      gl.useProgram(primitive.program);
      gl.disable(gl.BLEND);

      gl.uniform4f(
        primitive.uniforms.domain,
        viewport.x[0], viewport.x[1],
        viewport.y[0], viewport.y[1]
      );
      gl.uniform1f(primitive.uniforms.shaderMode, 0.0);
      gl.uniform1f(primitive.uniforms.isPointLayer, 0.0);
      gl.uniform1f(primitive.uniforms.pointScale, 1.0);
      gl.uniform1f(primitive.uniforms.minPointSize, 1.0);

      if (primitive.attributes.size >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.size);
        gl.vertexAttrib1f(primitive.attributes.size, 3.0);
      }

      if (primitive.attributes.age >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.age);
        gl.vertexAttrib1f(primitive.attributes.age, 1.0);
      }

      if (primitive.attributes.color >= 0) {
        gl.disableVertexAttribArray(primitive.attributes.color);
      }

      paths.forEach(function(path) {
        var payload = flattenLinePath(path);

        if (!payload || payload.count < 2) {
          return;
        }

        var positionBuffer = bindPositionAttribute(gl, primitive, payload.positions);

        if (primitive.attributes.color >= 0) {
          gl.vertexAttrib4f(primitive.attributes.color, 0.1, 0.1, 0.1, 1.0);
        }
        gl.drawArrays(gl.LINE_STRIP, 0, payload.count);

        gl.deleteBuffer(positionBuffer);
      });

      gl.enable(gl.BLEND);
      gl.blendFuncSeparate(
        gl.SRC_ALPHA,
        gl.ONE_MINUS_SRC_ALPHA,
        gl.ONE,
        gl.ONE_MINUS_SRC_ALPHA
      );
    }

    function drawLineLayer(gl, programs, layer, x, viewport, box) {
      var mode = lineRenderMode(x);

      if (mode === "native") {
        drawLineLayerNative(gl, programs, layer, x, viewport);
        return;
      }

      var paths = linePathList(layer.paths);
      var primitive = programs.primitive;
      var plotWidthPx = Math.max(1, box && box.plotWidth ? box.plotWidth : 1);
      var plotHeightPx = Math.max(1, box && box.plotHeight ? box.plotHeight : 1);
      var joinMode = lineJoinMode(x);
      var capMode = lineCapMode(x);

      configurePrimitiveLayerShader(gl, primitive, x, "lines", viewport, layer);

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

      paths.forEach(function(path) {
        var payload = flattenLinePathToStyledQuads(path, viewport, plotWidthPx, plotHeightPx, joinMode, capMode);

        if (!payload || payload.count < 3) {
          return;
        }

        var positionBuffer = bindPositionAttribute(gl, primitive, payload.positions);
        var ageBuffer = bindAgeAttribute(gl, primitive, payload.ages);
        var colorBuffer = bindColorAttribute(gl, primitive, payload.colors);

        gl.drawArrays(gl.TRIANGLES, 0, payload.count);

        gl.deleteBuffer(positionBuffer);
        gl.deleteBuffer(ageBuffer);
        gl.deleteBuffer(colorBuffer);
      });
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

    function drawScene(x) {
      var panels = panelList(x);

      if (!panels.length) {
        setEmpty("No supported point, line, or raster layers are available for rendering yet.");
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
      gl.clear(gl.COLOR_BUFFER_BIT);
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

        (panel.layers || []).forEach(function(layer) {
          if (layer.type === "raster") {
            drawRasterLayer(gl, programs, layer, viewport);
          } else if (layer.type === "lines") {
            drawLineLayer(gl, programs, layer, x, viewport, box);
          } else if (layer.type === "points") {
            drawPointLayer(gl, programs, layer, x, viewport);
          }
        });
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
        applyWidgetSize(width, height);
        resetViewport(null);
        
		requestAnimationFrame(function() {
    	  redrawCurrent();
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
