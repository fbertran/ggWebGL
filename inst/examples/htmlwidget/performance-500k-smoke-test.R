performance_500k_cloud <- function(point_count = 500000L) {
  point_count <- as.integer(point_count)[[1L]]
  if (!is.finite(point_count) || point_count <= 0L) {
    stop("`point_count` must be a positive integer scalar.", call. = FALSE)
  }

  index <- seq_len(point_count)
  cluster <- ((index - 1L) %% 6L) + 1L
  center_x <- c(-3.2, -1.2, 0.4, 1.8, 3.1, -2.4)
  center_y <- c(-1.6, 1.2, -0.2, 1.5, -0.9, 2.2)
  scale_x <- c(0.42, 0.75, 1.05, 0.62, 0.48, 0.58)
  scale_y <- c(0.30, 0.38, 0.46, 0.34, 0.26, 0.42)
  angle_offset <- c(0.20, -0.75, 0.55, -0.35, 0.95, -1.05)

  fract <- function(x) x - floor(x)
  u1 <- pmax(fract(sin(index * 12.9898) * 43758.5453), 1e-7)
  u2 <- fract(sin(index * 78.233 + 11.135) * 24634.6345)
  radius <- sqrt(-2 * log(u1))
  theta <- 2 * pi * u2 + angle_offset[cluster]

  data.frame(
    x = center_x[cluster] + scale_x[cluster] * radius * cos(theta) +
      0.12 * sin(index * 0.004),
    y = center_y[cluster] + scale_y[cluster] * radius * sin(theta) +
      0.10 * cos(index * 0.003),
    cluster = factor(cluster),
    stringsAsFactors = FALSE
  )
}

performance_500k_widget <- function(point_count = 500000L,
                                    shader = "density_splat",
                                    width = "100%",
                                    height = 600,
                                    frame_count = 120L,
                                    warmup_frames = 20L) {
  shader <- as.character(shader)[[1L]]
  data <- performance_500k_cloud(point_count)
  plot <- ggplot2::ggplot(data, ggplot2::aes(.data$x, .data$y, colour = .data$cluster)) +
    ggWebGL::geom_point_webgl(size = 1.1, alpha = 0.42) +
    ggplot2::scale_colour_manual(
      values = c("#1f9d8a", "#e76f51", "#457b9d", "#e9c46a", "#8d5cf6", "#d1495b"),
      guide = "none"
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "ggWebGL 500k-point manual smoke test",
      subtitle = "Manual smoke metrics only; not benchmark evidence."
    ) +
    ggWebGL::theme_webgl(
      shader = shader,
      interactions = c("pan", "zoom"),
      transparent = FALSE
    )

  widget <- ggWebGL::ggplot_webgl(plot, width = width, height = height)
  htmlwidgets::onRender(
    widget,
    ggwebgl_500k_smoke_js(
      point_count = point_count,
      shader = shader,
      frame_count = frame_count,
      warmup_frames = warmup_frames
    )
  )
}

run_manual_500k_performance_smoke_test <- function(output = tempfile(fileext = ".html"),
                                                   browse = interactive(),
                                                   selfcontained = FALSE,
                                                   point_count = 500000L,
                                                   shader = "density_splat",
                                                   frame_count = 120L,
                                                   warmup_frames = 20L) {
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  parent <- dirname(output)
  if (!dir.exists(parent)) {
    stop("The parent directory for `output` does not exist: ", parent, call. = FALSE)
  }

  widget <- performance_500k_widget(
    point_count = point_count,
    shader = shader,
    frame_count = frame_count,
    warmup_frames = warmup_frames
  )
  htmlwidgets::saveWidget(widget, file = output, selfcontained = selfcontained)
  message("Saved ggWebGL 500k-point manual smoke test to: ", output)

  if (isTRUE(browse)) {
    utils::browseURL(output)
  }

  invisible(output)
}

run_chromote_500k_performance_smoke_test <- function(output_dir = tempdir(),
                                                     frame_count = 120L,
                                                     warmup_frames = 20L,
                                                     point_count = 500000L,
                                                     shader = "density_splat",
                                                     timeout_seconds = 20) {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    message("chromote is not installed; skipping browser metric capture.")
    return(invisible(NULL))
  }
  if (!dir.exists(output_dir)) {
    stop("`output_dir` must exist before running the smoke test.", call. = FALSE)
  }

  html_file <- file.path(output_dir, "ggwebgl-500k-performance-smoke.html")
  csv_file <- file.path(output_dir, "ggwebgl-500k-performance-smoke.csv")
  run_manual_500k_performance_smoke_test(
    output = html_file,
    browse = FALSE,
    selfcontained = FALSE,
    point_count = point_count,
    shader = shader,
    frame_count = frame_count,
    warmup_frames = warmup_frames
  )

  chromote_ns <- asNamespace("chromote")
  browser <- chromote_ns$Chromote$new()
  on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
  session <- browser$new_session(width = 900, height = 600, wait_ = TRUE)
  on.exit(try(session$close(), silent = TRUE), add = TRUE)

  session$Page$navigate(paste0("file://", normalizePath(html_file, winslash = "/")), wait_ = TRUE)
  try(session$Page$loadEventFired(wait_ = TRUE), silent = TRUE)

  deadline <- Sys.time() + timeout_seconds
  metrics <- NULL
  repeat {
    result <- tryCatch(
      session$Runtime$evaluate(
        "window.__ggwebgl_500k_smoke_metrics || null",
        returnByValue = TRUE
      )$result$value,
      error = function(e) NULL
    )
    if (is.list(result) && identical(result$status, "complete")) {
      metrics <- result
      break
    }
    if (Sys.time() > deadline) {
      metrics <- result %||% list(status = "timeout")
      break
    }
    Sys.sleep(0.1)
  }

  version <- tryCatch(session$Browser$getVersion(), error = function(e) list())
  row <- ggwebgl_500k_metrics_row(
    metrics = metrics,
    html_file = html_file,
    csv_file = csv_file,
    browser_version = version$product %||% NA_character_
  )
  utils::write.csv(row, file = csv_file, row.names = FALSE)
  row
}

ggwebgl_500k_metrics_row <- function(metrics,
                                     html_file,
                                     csv_file,
                                     browser_version = NA_character_) {
  metrics <- metrics %||% list(status = "unavailable")
  data.frame(
    status = metrics$status %||% "unavailable",
    point_count = as.integer(metrics$point_count %||% NA_integer_),
    shader = as.character(metrics$shader %||% NA_character_),
    pixel_width = as.integer(metrics$pixel_width %||% NA_integer_),
    pixel_height = as.integer(metrics$pixel_height %||% NA_integer_),
    frame_count = as.integer(metrics$frame_count %||% NA_integer_),
    warmup_frames = as.integer(metrics$warmup_frames %||% NA_integer_),
    first_render_ms = as.numeric(metrics$first_render_ms %||% NA_real_),
    median_frame_time_ms = as.numeric(metrics$median_frame_time_ms %||% NA_real_),
    p95_frame_time_ms = as.numeric(metrics$p95_frame_time_ms %||% NA_real_),
    median_fps = as.numeric(metrics$median_fps %||% NA_real_),
    p95_fps = as.numeric(metrics$p95_fps %||% NA_real_),
    browser_version = as.character(browser_version %||% NA_character_),
    gpu_renderer = as.character(metrics$gpu_renderer %||% NA_character_),
    user_agent = as.character(metrics$user_agent %||% NA_character_),
    artifact_html = normalizePath(html_file, winslash = "/", mustWork = FALSE),
    artifact_csv = normalizePath(csv_file, winslash = "/", mustWork = FALSE),
    stringsAsFactors = FALSE
  )
}

ggwebgl_500k_smoke_js <- function(point_count,
                                  shader,
                                  frame_count,
                                  warmup_frames) {
  sprintf(
    "function(el, x) {
      const config = {
        point_count: %d,
        shader: %s,
        frame_count: %d,
        warmup_frames: %d
      };
      const start = performance.now();
      const panel = document.createElement('div');
      panel.className = 'ggwebgl-500k-smoke-metrics';
      panel.setAttribute('aria-label', 'ggWebGL manual smoke metrics');
      panel.style.cssText = [
        'position:absolute',
        'right:16px',
        'bottom:16px',
        'z-index:20',
        'max-width:320px',
        'padding:10px 12px',
        'border:1px solid rgba(15,23,42,0.14)',
        'border-radius:10px',
        'background:rgba(255,255,255,0.92)',
        'box-shadow:0 10px 24px rgba(15,23,42,0.10)',
        'font:12px/1.35 -apple-system,BlinkMacSystemFont,Segoe UI,sans-serif',
        'color:#0f172a',
        'pointer-events:none'
      ].join(';');
      el.style.position = el.style.position || 'relative';
      el.appendChild(panel);

      function percentile(values, p) {
        if (!values.length) return null;
        const sorted = values.slice().sort(function(a, b) { return a - b; });
        const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
        return sorted[index];
      }
      function median(values) {
        return percentile(values, 50);
      }
      function fps(frameTime) {
        return frameTime && frameTime > 0 ? 1000 / frameTime : null;
      }
      function round(value, digits) {
        if (value === null || value === undefined || !isFinite(value)) return null;
        const scale = Math.pow(10, digits || 1);
        return Math.round(value * scale) / scale;
      }
      function gpuRenderer() {
        const canvas = el.querySelector('canvas');
        const gl = canvas && (canvas.getContext('webgl') || canvas.getContext('experimental-webgl'));
        if (!gl) return null;
        const debug = gl.getExtension('WEBGL_debug_renderer_info');
        return debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : null;
      }
      function metrics(status, frameTimes) {
        const canvas = el.querySelector('canvas');
        const rect = canvas ? canvas.getBoundingClientRect() : { width: null, height: null };
        const samples = (frameTimes || []).slice(config.warmup_frames);
        const med = median(samples);
        const p95 = percentile(samples, 95);
        return {
          status: status,
          point_count: config.point_count,
          shader: config.shader,
          pixel_width: rect.width ? Math.round(rect.width) : null,
          pixel_height: rect.height ? Math.round(rect.height) : null,
          frame_count: config.frame_count,
          warmup_frames: config.warmup_frames,
          first_render_ms: round(window.__ggwebgl_500k_first_render_ms, 1),
          median_frame_time_ms: round(med, 2),
          p95_frame_time_ms: round(p95, 2),
          median_fps: round(fps(med), 1),
          p95_fps: round(fps(p95), 1),
          gpu_renderer: gpuRenderer(),
          user_agent: navigator.userAgent
        };
      }
      function renderPanel(current) {
        const lines = [
          '<strong>Manual smoke metrics</strong>',
          'points: ' + current.point_count.toLocaleString(),
          'shader: ' + current.shader,
          'status: ' + current.status,
          'first render: ' + (current.first_render_ms === null ? 'pending' : current.first_render_ms + ' ms'),
          'median frame: ' + (current.median_frame_time_ms === null ? 'pending' : current.median_frame_time_ms + ' ms'),
          'p95 frame: ' + (current.p95_frame_time_ms === null ? 'pending' : current.p95_frame_time_ms + ' ms'),
          'median FPS: ' + (current.median_fps === null ? 'pending' : current.median_fps),
          'p95 FPS: ' + (current.p95_fps === null ? 'pending' : current.p95_fps)
        ];
        panel.innerHTML = lines.map(function(line) { return '<div>' + line + '</div>'; }).join('');
      }

      const frameTimes = [];
      let previous = null;
      let frame = 0;
      window.__ggwebgl_500k_smoke_metrics = metrics('initializing', frameTimes);
      renderPanel(window.__ggwebgl_500k_smoke_metrics);

      function animate(timestamp) {
        if (previous !== null) frameTimes.push(timestamp - previous);
        previous = timestamp;
        frame += 1;
        const stage = el.querySelector('.ggwebgl__stage') || el;
        if (stage && frame <= config.frame_count) {
          const rect = stage.getBoundingClientRect();
          const delta = (frame %% 2 === 0 ? 1 : -1) * 12;
          stage.dispatchEvent(new WheelEvent('wheel', {
            deltaY: delta,
            clientX: rect.left + rect.width / 2,
            clientY: rect.top + rect.height / 2,
            bubbles: true,
            cancelable: true
          }));
        }
        if (frame < config.frame_count + config.warmup_frames) {
          if (frame %% 10 === 0) {
            window.__ggwebgl_500k_smoke_metrics = metrics('running', frameTimes);
            renderPanel(window.__ggwebgl_500k_smoke_metrics);
          }
          requestAnimationFrame(animate);
          return;
        }
        window.__ggwebgl_500k_smoke_metrics = metrics('complete', frameTimes);
        renderPanel(window.__ggwebgl_500k_smoke_metrics);
      }

      requestAnimationFrame(function() {
        window.__ggwebgl_500k_first_render_ms = performance.now() - start;
        window.__ggwebgl_500k_smoke_metrics = metrics('running', frameTimes);
        renderPanel(window.__ggwebgl_500k_smoke_metrics);
        requestAnimationFrame(animate);
      });
    }",
    as.integer(point_count),
    shQuote(as.character(shader)[[1L]], type = "sh"),
    as.integer(frame_count),
    as.integer(warmup_frames)
  )
}

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x)) y else x
}
