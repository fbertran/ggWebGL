library(ggplot2)

summarise_benchmark_metrics <- function(metrics) {
  ok <- metrics[metrics$status == "ok", , drop = FALSE]

  if (!nrow(ok)) {
    stop("No successful benchmark rows were available to summarise.")
  }

  browser_ok <- ok[is.finite(ok$browser_first_render_ms), , drop = FALSE]

  build_frame <- stats::aggregate(
    cbind(ggplot_build_seconds, engine_build_seconds) ~ family + engine,
    data = ok,
    FUN = stats::median
  )
  names(build_frame)[3:4] <- c("ggplot_build", "engine_build")

  transport_frame <- stats::aggregate(
    cbind(serialized_bytes, artifact_bytes) ~ family + engine,
    data = ok,
    FUN = stats::median
  )
  names(transport_frame)[3:4] <- c("serialized_bytes", "artifact_bytes")

  frames <- list(
    data.frame(
      family = build_frame$family,
      engine = build_frame$engine,
      category = "Build cost",
      metric = "ggplot_build_seconds",
      value = build_frame$ggplot_build,
      stringsAsFactors = FALSE
    ),
    data.frame(
      family = build_frame$family,
      engine = build_frame$engine,
      category = "Build cost",
      metric = "engine_build_seconds",
      value = build_frame$engine_build,
      stringsAsFactors = FALSE
    ),
    data.frame(
      family = transport_frame$family,
      engine = transport_frame$engine,
      category = "Transport cost",
      metric = "serialized_bytes",
      value = transport_frame$serialized_bytes,
      stringsAsFactors = FALSE
    ),
    data.frame(
      family = transport_frame$family,
      engine = transport_frame$engine,
      category = "Transport cost",
      metric = "artifact_bytes",
      value = transport_frame$artifact_bytes,
      stringsAsFactors = FALSE
    )
  )

  if (nrow(browser_ok)) {
    browser_frame <- stats::aggregate(
      browser_first_render_ms ~ family + engine,
      data = browser_ok,
      FUN = stats::median
    )
    names(browser_frame)[3] <- "browser_first_render_ms"
    frames[[length(frames) + 1L]] <- data.frame(
      family = browser_frame$family,
      engine = browser_frame$engine,
      category = "Browser render",
      metric = "browser_first_render_ms",
      value = browser_frame$browser_first_render_ms,
      stringsAsFactors = FALSE
    )
  }

  summary <- do.call(rbind, frames)
  summary$family <- factor(
    summary$family,
    levels = c("dense_points", "raster_field", "faceted_dense_points")
  )
  summary
}

plot_benchmark_results <- function(metrics,
                                   output_file = NULL,
                                   width = 12,
                                   height = 8,
                                   dpi = 144) {
  summary <- summarise_benchmark_metrics(metrics)
  metric_labels <- c(
    ggplot_build_seconds = "ggplot_build() seconds",
    engine_build_seconds = "Engine build seconds",
    serialized_bytes = "Serialized payload bytes",
    artifact_bytes = "Saved artifact bytes",
    browser_first_render_ms = "Browser first-render ms"
  )

  plot <- ggplot(summary, aes(engine, value, fill = engine)) +
    geom_col(position = "dodge", width = 0.72, show.legend = FALSE) +
    facet_grid(metric ~ family, scales = "free_y", labeller = ggplot2::labeller(
      metric = metric_labels,
      family = c(
        dense_points = "Dense points",
        raster_field = "Raster field",
        faceted_dense_points = "Faceted dense points"
      )
    )) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "ggWebGL Benchmark Overview",
      subtitle = "Median results grouped by plot family and engine",
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(angle = 25, hjust = 1),
      strip.text = element_text(face = "bold")
    )

  if (!is.null(output_file)) {
    ggplot2::ggsave(filename = output_file, plot = plot, width = width, height = height, dpi = dpi)
  }

  plot
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  metrics_file <- if (length(args) >= 1L) args[[1]] else "benchmark_metrics.csv"
  output_file <- if (length(args) >= 2L) args[[2]] else "benchmark_overview.png"

  metrics <- utils::read.csv(metrics_file, stringsAsFactors = FALSE)
  summary <- summarise_benchmark_metrics(metrics)
  plot_benchmark_results(metrics, output_file = output_file)

  summary_file <- sub("\\.[^.]+$", "_summary.csv", output_file)
  utils::write.csv(summary, summary_file, row.names = FALSE)
  message("Wrote benchmark plot to: ", normalizePath(output_file, winslash = "/", mustWork = FALSE))
  message("Wrote benchmark summary to: ", normalizePath(summary_file, winslash = "/", mustWork = FALSE))
}
