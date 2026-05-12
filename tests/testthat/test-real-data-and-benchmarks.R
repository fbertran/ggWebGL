locate_script <- function(path_parts, installed_parts = path_parts[-1L]) {
  candidates <- c(
    do.call(file.path, as.list(path_parts)),
    do.call(file.path, c("tests", "testthat", "..", "..", as.list(path_parts))),
    do.call(system.file, c(as.list(installed_parts), package = "ggWebGL"))
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1]]
}

test_that("packaged real-data loaders return expected structures", {
  volcano_dem <- ggwebgl_example_data("volcano_dem")
  storm_tracks <- ggwebgl_example_data("storm_tracks")
  dense_embedding <- ggwebgl_example_data("dense_embedding")
  dense_embedding_legacy <- ggwebgl_example_data("diamonds_embedding")

  expect_true(all(c("x", "y", "elevation") %in% names(volcano_dem)))
  expect_gt(nrow(volcano_dem), 0L)

  expect_true(all(c("storm_id", "storm_name", "timestamp", "lon", "lat", "wind", "pressure") %in% names(storm_tracks)))
  expect_gt(nrow(storm_tracks), 0L)

  expect_true(all(c("embed_x", "embed_y") %in% names(dense_embedding)))
  expect_gt(nrow(dense_embedding), 0L)
  expect_equal(dense_embedding, dense_embedding_legacy)
})

test_that("real-data gallery exports all html files", {
  gallery_env <- new.env(parent = globalenv())
  gallery_path <- locate_script(
    path_parts = c("inst", "examples", "htmlwidget", "real-data-gallery.R"),
    installed_parts = c("examples", "htmlwidget", "real-data-gallery.R")
  )

  expect_false(is.na(gallery_path))
  if (is.na(gallery_path)) {
    return(invisible())
  }

  sys.source(gallery_path, envir = gallery_env)

  output_dir <- tempfile("ggwebgl-real-gallery-")
  files <- gallery_env$export_real_data_gallery(output_dir = output_dir, selfcontained = FALSE)
  index_path <- attr(files, "index")

  expect_length(files, 4L)
  expect_named(files, c("volcano_dem", "storm_tracks", "dense_embedding", "faceted_embedding"))
  expect_true(all(file.exists(unname(files))))
  expect_true(file.exists(index_path))
})

test_that("benchmark suite emits machine-readable metrics for all families", {
  suite_env <- new.env(parent = globalenv())
  suite_path <- locate_script(
    path_parts = c("inst", "benchmarks", "benchmark-suite.R"),
    installed_parts = c("benchmarks", "benchmark-suite.R")
  )

  expect_false(is.na(suite_path))
  if (is.na(suite_path)) {
    return(invisible())
  }

  sys.source(suite_path, envir = suite_env)

  output_dir <- tempfile("ggwebgl-bench-suite-")
  metrics <- suite_env$benchmark_render_suite(
    output_dir = output_dir,
    families = c("dense_points", "raster_field", "faceted_dense_points"),
    engines = c("ggwebgl", "ggplot2"),
    reps = 1L,
    selfcontained = FALSE,
    include_browser = FALSE
  )

  expect_equal(nrow(metrics), 6L)
  expect_true(all(c(
    "family", "engine", "rep", "status", "ggplot_build_seconds",
    "engine_build_seconds", "artifact_write_seconds", "serialized_bytes",
    "artifact_bytes", "artifact_file", "browser_first_render_ms",
    "browser_status", "startup_latency_ms", "transport_mode",
    "transport_compact_layers", "transport_compact_point_count",
    "transport_decoded_bytes", "transport_uploaded", "progressive_complete_ms"
  ) %in% names(metrics)))
  expect_true(all(metrics$status == "ok"))
  expect_true(file.exists(attr(metrics, "metrics_path")))
})

test_that("plotly benchmark baseline executes when available", {
  suite_env <- new.env(parent = globalenv())
  suite_path <- locate_script(
    path_parts = c("inst", "benchmarks", "benchmark-suite.R"),
    installed_parts = c("benchmarks", "benchmark-suite.R")
  )

  expect_false(is.na(suite_path))
  if (is.na(suite_path)) {
    return(invisible())
  }

  sys.source(suite_path, envir = suite_env)

  output_dir <- tempfile("ggwebgl-plotly-bench-")
  metrics <- suite_env$benchmark_render_suite(
    output_dir = output_dir,
    families = "dense_points",
    engines = "plotly",
    reps = 1L,
    selfcontained = FALSE,
    include_browser = FALSE
  )

  expect_equal(nrow(metrics), 1L)
  if (requireNamespace("plotly", quietly = TRUE)) {
    expect_equal(metrics$status, "ok")
    expect_true(file.exists(metrics$artifact_file))
  } else {
    expect_equal(metrics$status, "package_unavailable")
  }
})

test_that("browser benchmark metric degrades gracefully when unavailable", {
  suite_env <- new.env(parent = globalenv())
  suite_path <- locate_script(
    path_parts = c("inst", "benchmarks", "benchmark-suite.R"),
    installed_parts = c("benchmarks", "benchmark-suite.R")
  )

  expect_false(is.na(suite_path))
  if (is.na(suite_path)) {
    return(invisible())
  }

  sys.source(suite_path, envir = suite_env)

  html_file <- tempfile(fileext = ".html")
  writeLines(c(
    "<!DOCTYPE html>",
    "<html><body><script>window.__render_ready = 1;</script></body></html>"
  ), con = html_file)

  browser <- suite_env$measure_browser_render(html_file, timeout_seconds = 0.2)
  expect_true(all(c("browser_first_render_ms", "browser_status") %in% names(browser)))
  expect_true(browser$browser_status %in% c("ok", "timeout", "chromote_unavailable", "browser_unavailable"))
})

test_that("frame-rate benchmark contract is explicit before performance statements", {
  suite_env <- new.env(parent = globalenv())
  suite_path <- locate_script(
    path_parts = c("inst", "benchmarks", "benchmark-suite.R"),
    installed_parts = c("benchmarks", "benchmark-suite.R")
  )

  expect_false(is.na(suite_path))
  if (is.na(suite_path)) {
    return(invisible())
  }

  sys.source(suite_path, envir = suite_env)

  required <- c(
    "claim_id",
    "package_version",
    "commit_sha",
    "dataset_size",
    "primitive_counts",
    "browser",
    "browser_version",
    "device",
    "gpu_renderer",
    "os",
    "pixel_width",
    "pixel_height",
    "shader",
    "rendering_mode",
    "dimension",
    "interaction",
    "frame_count",
    "warmup_frames",
    "median_frame_time_ms",
    "p95_frame_time_ms",
    "median_fps",
    "p95_fps",
    "artifact_html",
    "artifact_csv",
    "status",
    "created_at"
  )
  template <- suite_env$fps_claim_metrics_template()

  expect_equal(names(template), required)
  expect_equal(nrow(template), 0L)
  expect_true(suite_env$validate_fps_claim_metrics(template))
  expect_error(
    suite_env$validate_fps_claim_metrics(data.frame(dataset_size = 1L)),
    "missing required columns"
  )
})

test_that("benchmark plotting script regenerates a summary figure", {
  suite_env <- new.env(parent = globalenv())
  suite_path <- locate_script(
    path_parts = c("inst", "benchmarks", "benchmark-suite.R"),
    installed_parts = c("benchmarks", "benchmark-suite.R")
  )
  plot_env <- new.env(parent = globalenv())
  plot_path <- locate_script(
    path_parts = c("inst", "benchmarks", "plot-benchmark-results.R"),
    installed_parts = c("benchmarks", "plot-benchmark-results.R")
  )

  expect_false(is.na(suite_path))
  expect_false(is.na(plot_path))
  if (is.na(suite_path) || is.na(plot_path)) {
    return(invisible())
  }

  sys.source(suite_path, envir = suite_env)
  sys.source(plot_path, envir = plot_env)

  output_dir <- tempfile("ggwebgl-bench-plot-")
  metrics <- suite_env$benchmark_render_suite(
    output_dir = output_dir,
    families = c("dense_points", "raster_field"),
    engines = c("ggwebgl", "ggplot2"),
    reps = 1L,
    selfcontained = FALSE,
    include_browser = FALSE
  )
  plot_file <- tempfile(fileext = ".png")

  summary <- plot_env$summarise_benchmark_metrics(metrics)
  plot <- plot_env$plot_benchmark_results(metrics, output_file = plot_file)

  expect_s3_class(plot, "ggplot")
  expect_gt(nrow(summary), 0L)
  expect_true(file.exists(plot_file))
})
