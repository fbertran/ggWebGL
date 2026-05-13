benchmark_scene_columns <- function() {
  c(
    "scene_id",
    "package_version",
    "commit_sha",
    "dataset_size",
    "primitive_counts",
    "transport_mode",
    "serialized_bytes",
    "artifact_bytes",
    "startup_latency_ms",
    "first_interactive_frame_ms",
    "selection_latency_ms",
    "median_frame_time_ms",
    "p95_frame_time_ms",
    "median_fps",
    "p95_fps",
    "memory_used_mb",
    "browser",
    "browser_version",
    "gpu_renderer",
    "device",
    "os",
    "pixel_width",
    "pixel_height",
    "interaction",
    "artifact_html",
    "artifact_csv",
    "status",
    "created_at"
  )
}

benchmark_scene_metrics_template <- function() {
  data.frame(
    scene_id = character(),
    package_version = character(),
    commit_sha = character(),
    dataset_size = integer(),
    primitive_counts = character(),
    transport_mode = character(),
    serialized_bytes = numeric(),
    artifact_bytes = numeric(),
    startup_latency_ms = numeric(),
    first_interactive_frame_ms = numeric(),
    selection_latency_ms = numeric(),
    median_frame_time_ms = numeric(),
    p95_frame_time_ms = numeric(),
    median_fps = numeric(),
    p95_fps = numeric(),
    memory_used_mb = numeric(),
    browser = character(),
    browser_version = character(),
    gpu_renderer = character(),
    device = character(),
    os = character(),
    pixel_width = integer(),
    pixel_height = integer(),
    interaction = character(),
    artifact_html = character(),
    artifact_csv = character(),
    status = character(),
    created_at = character(),
    stringsAsFactors = FALSE
  )
}

benchmark_scene_validate_metrics <- function(metrics) {
  missing <- setdiff(benchmark_scene_columns(), names(metrics))
  if (length(missing) > 0L) {
    stop("Benchmark metrics are missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  metrics[benchmark_scene_columns()]
}

benchmark_scene_commit_sha <- function() {
  out <- tryCatch(
    system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
  if (length(out) == 0L || !nzchar(out[[1L]])) {
    return(NA_character_)
  }
  out[[1L]]
}

benchmark_scene_script_path <- function(file) {
  installed <- system.file("examples", "htmlwidget", file, package = "ggWebGL")
  candidates <- c(installed, file.path("inst", "examples", "htmlwidget", file))
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates) == 0L) {
    stop("Cannot find benchmark scene helper script: ", file, call. = FALSE)
  }
  candidates[[1L]]
}

benchmark_scene_load_helpers <- function(files) {
  env <- new.env(parent = baseenv())
  for (file in files) {
    sys.source(benchmark_scene_script_path(file), envir = env)
  }
  env
}

benchmark_scene_primitive_counts <- function(widget) {
  render <- widget$x$render %||% list()
  parts <- c(
    points = render$point_count %||% 0L,
    line_vertices = render$line_vertex_count %||% 0L,
    vectors = render$vector_count %||% 0L,
    mesh_triangles = render$mesh_triangle_count %||% 0L,
    surface_triangles = render$surface_triangle_count %||% 0L,
    raster_cells = render$raster_cell_count %||% 0L
  )
  paste(names(parts), as.integer(parts), sep = "=", collapse = ";")
}

benchmark_scene_transport_mode <- function(widget) {
  transport <- widget$x$render$transport %||% widget$x$webgl$transport %||% list()
  mode <- transport$mode %||% "legacy"
  compact_layers <- transport$compact_layers %||% 0L
  paste0(mode, ";compact_layers=", compact_layers)
}

benchmark_scene_build_widget <- function(scene = c("embedding", "trajectories", "surface_mesh", "workflow"),
                                         point_count = 1000000L,
                                         height = 620) {
  scene <- match.arg(scene)
  if (identical(scene, "embedding")) {
    helpers <- benchmark_scene_load_helpers("million-point-embedding.R")
    return(helpers$embedding_widget(point_count = point_count, height = height))
  }
  if (identical(scene, "trajectories")) {
    helpers <- benchmark_scene_load_helpers("temporal-trajectories.R")
    return(helpers$temporal_velocity_widget(height = height))
  }
  if (identical(scene, "surface_mesh")) {
    helpers <- benchmark_scene_load_helpers("surface-gallery.R")
    return(helpers$surface_gallery_volcano_widget(height = height))
  }

  helpers <- benchmark_scene_load_helpers("workflow-comparison.R")
  helpers$workflow_comparison_widget(n = min(point_count, 10000L), height = height)
}

benchmark_scene_file_url <- function(path) {
  normalised <- normalizePath(path, winslash = "/", mustWork = TRUE)
  paste0("file://", utils::URLencode(normalised, reserved = TRUE))
}

benchmark_scene_browser_metric_script <- function(frame_count = 120L, warmup_frames = 20L) {
  sprintf(
    "(async function() {
      const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
      const now = () => performance.now();
      const frameCount = %d;
      const warmupFrames = %d;
      const quantile = (values, p) => {
        if (!values.length) return null;
        const sorted = values.slice().sort((a, b) => a - b);
        const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil(p * sorted.length) - 1));
        return sorted[index];
      };
      const median = (values) => quantile(values, 0.5);
      const canvas = document.querySelector('canvas');
      let gpu = null;
      if (canvas) {
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (gl) {
          const ext = gl.getExtension('WEBGL_debug_renderer_info');
          gpu = ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
        }
      }
      const start = now();
      while (!document.querySelector('canvas') && now() - start < 10000) {
        await sleep(50);
      }
      const firstInteractive = now() - start;
      const frames = [];
      let last = null;
      await new Promise((resolve) => {
        const step = (ts) => {
          if (last !== null) frames.push(ts - last);
          last = ts;
          if (frames.length >= frameCount + warmupFrames) {
            resolve();
          } else {
            requestAnimationFrame(step);
          }
        };
        requestAnimationFrame(step);
      });
      const measured = frames.slice(warmupFrames);
      const medianFrame = median(measured);
      const p95Frame = quantile(measured, 0.95);
      const memory = performance.memory && performance.memory.usedJSHeapSize ?
        performance.memory.usedJSHeapSize / (1024 * 1024) : null;
      return {
        status: 'browser_complete',
        first_interactive_frame_ms: firstInteractive,
        median_frame_time_ms: medianFrame,
        p95_frame_time_ms: p95Frame,
        median_fps: medianFrame ? 1000 / medianFrame : null,
        p95_fps: p95Frame ? 1000 / p95Frame : null,
        memory_used_mb: memory,
        browser: navigator.userAgent,
        gpu_renderer: gpu,
        device: navigator.platform,
        pixel_width: window.innerWidth,
        pixel_height: window.innerHeight
      };
    })()",
    as.integer(frame_count),
    as.integer(warmup_frames)
  )
}

benchmark_scene_capture_browser_metrics <- function(html_file, frame_count = 120L, warmup_frames = 20L) {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    return(list(status = "browser_unavailable"))
  }

  session <- NULL
  tryCatch({
    session <- chromote::ChromoteSession$new()
    on.exit(try(session$close(), silent = TRUE), add = TRUE)
    session$Page$navigate(benchmark_scene_file_url(html_file))
    try(session$Page$loadEventFired(), silent = TRUE)
    version <- tryCatch(session$Browser$getVersion(), error = function(e) list())
    result <- session$Runtime$evaluate(
      benchmark_scene_browser_metric_script(frame_count, warmup_frames),
      awaitPromise = TRUE,
      returnByValue = TRUE
    )$result$value
    if (!is.list(result)) {
      return(list(status = "browser_metric_unavailable"))
    }
    result$browser_version <- version$product %||% NA_character_
    result
  }, error = function(e) {
    list(status = "browser_unavailable", error = conditionMessage(e))
  })
}

benchmark_scene_types <- function(output_dir = tempdir(),
                                  scenes = c("embedding", "trajectories", "surface_mesh", "workflow"),
                                  point_count = 1000000L,
                                  include_browser = FALSE,
                                  selfcontained = FALSE,
                                  frame_count = 120L,
                                  warmup_frames = 20L) {
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)
  scenes <- match.arg(scenes, several.ok = TRUE)
  rows <- benchmark_scene_metrics_template()
  csv_file <- file.path(output_dir, "ggwebgl-scene-type-metrics.csv")

  for (scene in scenes) {
    build_time <- system.time({
      widget <- benchmark_scene_build_widget(scene, point_count = point_count)
    })[["elapsed"]]
    html_file <- file.path(output_dir, paste0("ggwebgl-", scene, "-scene.html"))
    htmlwidgets::saveWidget(widget, file = html_file, selfcontained = selfcontained)
    browser_metrics <- if (isTRUE(include_browser)) {
      benchmark_scene_capture_browser_metrics(
        html_file,
        frame_count = frame_count,
        warmup_frames = warmup_frames
      )
    } else {
      list(status = "browser_skipped")
    }

    row <- data.frame(
      scene_id = scene,
      package_version = as.character(utils::packageVersion("ggWebGL")),
      commit_sha = benchmark_scene_commit_sha(),
      dataset_size = as.integer(if (identical(scene, "embedding")) point_count else NA_integer_),
      primitive_counts = benchmark_scene_primitive_counts(widget),
      transport_mode = benchmark_scene_transport_mode(widget),
      serialized_bytes = length(serialize(widget$x, NULL)),
      artifact_bytes = unname(file.info(html_file)$size),
      startup_latency_ms = unname(build_time * 1000),
      first_interactive_frame_ms = as.numeric(browser_metrics$first_interactive_frame_ms %||% NA_real_),
      selection_latency_ms = NA_real_,
      median_frame_time_ms = as.numeric(browser_metrics$median_frame_time_ms %||% NA_real_),
      p95_frame_time_ms = as.numeric(browser_metrics$p95_frame_time_ms %||% NA_real_),
      median_fps = as.numeric(browser_metrics$median_fps %||% NA_real_),
      p95_fps = as.numeric(browser_metrics$p95_fps %||% NA_real_),
      memory_used_mb = as.numeric(browser_metrics$memory_used_mb %||% NA_real_),
      browser = as.character(browser_metrics$browser %||% NA_character_),
      browser_version = as.character(browser_metrics$browser_version %||% NA_character_),
      gpu_renderer = as.character(browser_metrics$gpu_renderer %||% NA_character_),
      device = as.character(browser_metrics$device %||% Sys.info()[["nodename"]]),
      os = paste(Sys.info()[["sysname"]], Sys.info()[["release"]]),
      pixel_width = as.integer(browser_metrics$pixel_width %||% NA_integer_),
      pixel_height = as.integer(browser_metrics$pixel_height %||% NA_integer_),
      interaction = if (identical(scene, "embedding")) "brush" else "view",
      artifact_html = html_file,
      artifact_csv = csv_file,
      status = browser_metrics$status %||% "browser_skipped",
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      stringsAsFactors = FALSE
    )
    rows <- rbind(rows, row)
  }

  rows <- benchmark_scene_validate_metrics(rows)
  utils::write.csv(rows, csv_file, row.names = FALSE)
  rows
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
