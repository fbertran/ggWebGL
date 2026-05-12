if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

library(ggplot2)
library(htmlwidgets)

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x)) y else x
}

benchmark_family_plot <- function(family = c("dense_points", "raster_field", "faceted_dense_points"),
                                  use_webgl_geoms = TRUE) {
  family <- match.arg(family)
  point_layer <- if (isTRUE(use_webgl_geoms)) geom_point_webgl else ggplot2::geom_point
  raster_layer <- if (isTRUE(use_webgl_geoms)) geom_raster_webgl else ggplot2::geom_raster
  theme_layer <- if (isTRUE(use_webgl_geoms)) {
    theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover"))
  } else {
    ggplot2::theme_minimal(base_size = 11)
  }
  raster_theme_layer <- if (isTRUE(use_webgl_geoms)) {
    theme_webgl(shader = "default", interactions = c("pan", "zoom", "hover"))
  } else {
    ggplot2::theme_minimal(base_size = 11)
  }

  if (identical(family, "dense_points")) {
    embedding <- ggwebgl_example_data("dense_embedding")

    return(
      ggplot(embedding, aes(embed_x, embed_y, colour = cut)) +
        point_layer(size = 1.1, alpha = 0.22) +
        scale_colour_brewer(palette = "Set2", guide = "none") +
        coord_equal() +
        labs(x = "Projection axis 1", y = "Projection axis 2") +
        theme_layer
    )
  }

  if (identical(family, "raster_field")) {
    volcano_dem <- ggwebgl_example_data("volcano_dem")

    return(
      ggplot(volcano_dem, aes(x, y, fill = elevation)) +
        raster_layer(interpolate = TRUE) +
        scale_fill_gradientn(colours = grDevices::hcl.colors(12L, "Terrain 2"), guide = "none") +
        coord_equal(expand = FALSE) +
        labs(x = "Grid x", y = "Grid y") +
        raster_theme_layer
    )
  }

  embedding <- ggwebgl_example_data("dense_embedding")
  ggplot(embedding, aes(embed_x, embed_y, colour = cut)) +
    point_layer(size = 1.0, alpha = 0.20) +
    scale_colour_brewer(palette = "Set2", guide = "none") +
    coord_equal() +
    facet_wrap(~price_band, nrow = 2) +
    labs(x = "Projection axis 1", y = "Projection axis 2") +
    theme_layer
}

write_static_wrapper <- function(image_file, html_file, title = "ggplot2 benchmark") {
  html <- c(
    "<!DOCTYPE html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    paste0("  <title>", title, "</title>"),
    "  <style>body { margin: 0; display: grid; place-items: center; min-height: 100vh; background: #f8fafc; } img { max-width: 100%; height: auto; }</style>",
    "</head>",
    "<body>",
    "  <img id=\"plot\" src=\"", basename(image_file), "\" alt=\"benchmark plot\">",
    "  <script>",
    "    window.__render_ready = null;",
    "    window.addEventListener('load', function() {",
    "      var img = document.getElementById('plot');",
    "      if (img.complete) { window.__render_ready = performance.now(); }",
    "      img.addEventListener('load', function() { window.__render_ready = performance.now(); }, { once: true });",
    "    });",
    "  </script>",
    "</body>",
    "</html>"
  )

  writeLines(html, con = html_file, useBytes = TRUE)
  invisible(html_file)
}

html_file_url <- function(path) {
  normalised <- normalizePath(path, winslash = "/", mustWork = TRUE)
  paste0("file://", utils::URLencode(normalised, reserved = TRUE))
}

measure_browser_render <- function(file, timeout_seconds = 10) {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    return(list(browser_first_render_ms = NA_real_, browser_status = "chromote_unavailable"))
  }

  session <- NULL
  on.exit(
    if (!is.null(session)) {
      try(session$close(), silent = TRUE)
    },
    add = TRUE
  )

  out <- tryCatch({
    session <- chromote::ChromoteSession$new()
    session$Page$navigate(html_file_url(file))
    deadline <- Sys.time() + timeout_seconds
    render_ms <- NULL

    while (Sys.time() < deadline) {
      Sys.sleep(0.1)
      render_ms <- tryCatch(
        session$Runtime$evaluate("window.__render_ready")$result$value,
        error = function(e) NULL
      )

      if (is.numeric(render_ms) && length(render_ms) == 1L && is.finite(render_ms)) {
        break
      }
    }

    transport_metrics <- tryCatch(
      session$Runtime$evaluate("window.__ggwebgl_transport_metrics || null", returnByValue = TRUE)$result$value,
      error = function(e) NULL
    )

    if (is.numeric(render_ms) && length(render_ms) == 1L && is.finite(render_ms)) {
      list(
        browser_first_render_ms = as.numeric(render_ms),
        browser_status = "ok",
        transport_uploaded = as.numeric(transport_metrics$uploaded %||% NA_real_),
        transport_full_upload_ms = as.numeric(transport_metrics$full_upload_ms %||% NA_real_)
      )
    } else {
      list(
        browser_first_render_ms = NA_real_,
        browser_status = "timeout",
        transport_uploaded = NA_real_,
        transport_full_upload_ms = NA_real_
      )
    }
  }, error = function(e) {
    list(
      browser_first_render_ms = NA_real_,
      browser_status = "browser_unavailable",
      transport_uploaded = NA_real_,
      transport_full_upload_ms = NA_real_
    )
  })

  out
}

widget_transport_summary <- function(widget) {
  transport <- widget$x$render$transport %||% list()
  list(
    transport_mode = as.character(transport$mode %||% "legacy"),
    transport_compact_layers = as.integer(transport$compact_layers %||% 0L),
    transport_compact_point_count = as.integer(transport$compact_point_count %||% 0L),
    transport_decoded_bytes = as.numeric(transport$decoded_bytes %||% NA_real_)
  )
}

fps_claim_required_columns <- function() {
  c(
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
}

fps_claim_metrics_template <- function() {
  out <- data.frame(
    claim_id = character(),
    package_version = character(),
    commit_sha = character(),
    dataset_size = integer(),
    primitive_counts = character(),
    browser = character(),
    browser_version = character(),
    device = character(),
    gpu_renderer = character(),
    os = character(),
    pixel_width = integer(),
    pixel_height = integer(),
    shader = character(),
    rendering_mode = character(),
    dimension = character(),
    interaction = character(),
    frame_count = integer(),
    warmup_frames = integer(),
    median_frame_time_ms = numeric(),
    p95_frame_time_ms = numeric(),
    median_fps = numeric(),
    p95_fps = numeric(),
    artifact_html = character(),
    artifact_csv = character(),
    status = character(),
    created_at = character(),
    stringsAsFactors = FALSE
  )
  out[fps_claim_required_columns()]
}

validate_fps_claim_metrics <- function(metrics) {
  if (!is.data.frame(metrics)) {
    stop("Frame-rate metrics must be a data frame.", call. = FALSE)
  }

  missing <- setdiff(fps_claim_required_columns(), names(metrics))
  if (length(missing)) {
    stop(
      "Frame-rate metrics are missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  TRUE
}

build_engine_artifact <- function(engine = c("ggwebgl", "plotly", "ggplot2"),
                                  plot,
                                  family,
                                  rep_id,
                                  output_dir,
                                  selfcontained = TRUE,
                                  include_browser = TRUE) {
  engine <- match.arg(engine)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  ggplot_build_seconds <- system.time(ggplot2::ggplot_build(plot))[["elapsed"]]

  if (identical(engine, "ggwebgl")) {
    file <- file.path(output_dir, sprintf("%s-%s-%02d.html", family, engine, rep_id))
    build <- system.time({
      widget <- ggplot_webgl(plot, width = "100%", height = 540)
    })[["elapsed"]]
    serialised_bytes <- length(serialize(widget$x, NULL))
    write_seconds <- system.time({
      htmlwidgets::saveWidget(
        htmlwidgets::onRender(widget, "function(el, x) { window.__render_ready = performance.now(); }"),
        file = file,
        selfcontained = selfcontained
      )
    })[["elapsed"]]
    browser <- if (isTRUE(include_browser)) measure_browser_render(file) else {
      list(
        browser_first_render_ms = NA_real_,
        browser_status = "skipped",
        transport_uploaded = NA_real_,
        transport_full_upload_ms = NA_real_
      )
    }
    transport <- widget_transport_summary(widget)

    return(data.frame(
      family = family,
      engine = engine,
      rep = rep_id,
      status = "ok",
      ggplot_build_seconds = ggplot_build_seconds,
      engine_build_seconds = build,
      artifact_write_seconds = write_seconds,
      serialized_bytes = serialised_bytes,
      artifact_bytes = file.info(file)$size,
      artifact_file = normalizePath(file, winslash = "/", mustWork = FALSE),
      browser_first_render_ms = browser$browser_first_render_ms,
      browser_status = browser$browser_status,
      startup_latency_ms = browser$browser_first_render_ms,
      transport_mode = transport$transport_mode,
      transport_compact_layers = transport$transport_compact_layers,
      transport_compact_point_count = transport$transport_compact_point_count,
      transport_decoded_bytes = transport$transport_decoded_bytes,
      transport_uploaded = browser$transport_uploaded,
      progressive_complete_ms = browser$transport_full_upload_ms,
      stringsAsFactors = FALSE
    ))
  }

  if (identical(engine, "plotly")) {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      return(data.frame(
        family = family,
        engine = engine,
        rep = rep_id,
        status = "package_unavailable",
        ggplot_build_seconds = ggplot_build_seconds,
        engine_build_seconds = NA_real_,
        artifact_write_seconds = NA_real_,
        serialized_bytes = NA_real_,
        artifact_bytes = NA_real_,
        artifact_file = NA_character_,
        browser_first_render_ms = NA_real_,
        browser_status = "skipped",
        startup_latency_ms = NA_real_,
        transport_mode = NA_character_,
        transport_compact_layers = NA_integer_,
        transport_compact_point_count = NA_integer_,
        transport_decoded_bytes = NA_real_,
        transport_uploaded = NA_real_,
        progressive_complete_ms = NA_real_,
        stringsAsFactors = FALSE
      ))
    }

    file <- file.path(output_dir, sprintf("%s-%s-%02d.html", family, engine, rep_id))
    build <- system.time({
      widget <- plotly::ggplotly(plot)
    })[["elapsed"]]
    serialised_bytes <- length(serialize(widget$x, NULL))
    write_seconds <- system.time({
      htmlwidgets::saveWidget(
        htmlwidgets::onRender(widget, "function(el, x) { window.__render_ready = performance.now(); }"),
        file = file,
        selfcontained = selfcontained
      )
    })[["elapsed"]]
    browser <- if (isTRUE(include_browser)) measure_browser_render(file) else {
      list(
        browser_first_render_ms = NA_real_,
        browser_status = "skipped",
        transport_uploaded = NA_real_,
        transport_full_upload_ms = NA_real_
      )
    }

    return(data.frame(
      family = family,
      engine = engine,
      rep = rep_id,
      status = "ok",
      ggplot_build_seconds = ggplot_build_seconds,
      engine_build_seconds = build,
      artifact_write_seconds = write_seconds,
      serialized_bytes = serialised_bytes,
      artifact_bytes = file.info(file)$size,
      artifact_file = normalizePath(file, winslash = "/", mustWork = FALSE),
      browser_first_render_ms = browser$browser_first_render_ms,
      browser_status = browser$browser_status,
      startup_latency_ms = browser$browser_first_render_ms,
      transport_mode = NA_character_,
      transport_compact_layers = NA_integer_,
      transport_compact_point_count = NA_integer_,
      transport_decoded_bytes = NA_real_,
      transport_uploaded = NA_real_,
      progressive_complete_ms = NA_real_,
      stringsAsFactors = FALSE
    ))
  }

  png_file <- file.path(output_dir, sprintf("%s-%s-%02d.png", family, engine, rep_id))
  html_file <- file.path(output_dir, sprintf("%s-%s-%02d.html", family, engine, rep_id))
  build <- system.time({
    ggplot2::ggplotGrob(plot)
  })[["elapsed"]]
  write_seconds <- system.time({
    ggplot2::ggsave(filename = png_file, plot = plot, width = 7.5, height = 5.4, dpi = 144)
    write_static_wrapper(png_file, html_file, title = paste("Benchmark", family, engine))
  })[["elapsed"]]
  browser <- if (isTRUE(include_browser)) measure_browser_render(html_file) else {
    list(
      browser_first_render_ms = NA_real_,
      browser_status = "skipped",
      transport_uploaded = NA_real_,
      transport_full_upload_ms = NA_real_
    )
  }

  data.frame(
    family = family,
    engine = engine,
    rep = rep_id,
    status = "ok",
    ggplot_build_seconds = ggplot_build_seconds,
    engine_build_seconds = build,
    artifact_write_seconds = write_seconds,
    serialized_bytes = length(serialize(plot, NULL)),
    artifact_bytes = file.info(png_file)$size,
    artifact_file = normalizePath(png_file, winslash = "/", mustWork = FALSE),
    browser_first_render_ms = browser$browser_first_render_ms,
    browser_status = browser$browser_status,
    startup_latency_ms = browser$browser_first_render_ms,
    transport_mode = NA_character_,
    transport_compact_layers = NA_integer_,
    transport_compact_point_count = NA_integer_,
    transport_decoded_bytes = NA_real_,
    transport_uploaded = NA_real_,
    progressive_complete_ms = NA_real_,
    stringsAsFactors = FALSE
  )
}

benchmark_render_suite <- function(output_dir = tempfile("ggwebgl-benchmarks-"),
                                   families = c("dense_points", "raster_field", "faceted_dense_points"),
                                   engines = c("ggwebgl", "plotly", "ggplot2"),
                                   reps = 1L,
                                   selfcontained = TRUE,
                                   include_browser = TRUE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  reps <- as.integer(reps)[1]

  metrics <- do.call(
    rbind,
    lapply(families, function(family) {
      do.call(
        rbind,
        lapply(seq_len(reps), function(rep_id) {
          do.call(
            rbind,
            lapply(engines, function(engine) {
              plot <- benchmark_family_plot(
                family = family,
                use_webgl_geoms = identical(engine, "ggwebgl")
              )
              build_engine_artifact(
                engine = engine,
                plot = plot,
                family = family,
                rep_id = rep_id,
                output_dir = output_dir,
                selfcontained = selfcontained,
                include_browser = include_browser
              )
            })
          )
        })
      )
    })
  )

  csv_path <- file.path(output_dir, "benchmark_metrics.csv")
  utils::write.csv(metrics, csv_path, row.names = FALSE)
  attr(metrics, "metrics_path") <- csv_path
  attr(metrics, "output_dir") <- output_dir
  metrics
}
