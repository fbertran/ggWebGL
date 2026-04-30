library(ggplot2)
library(htmlwidgets)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

smoke_test_plot <- function(scenario = c("points", "lines", "mixed", "raster", "facet")) {
  scenario <- match.arg(scenario)

  if (identical(scenario, "points")) {
    return(
      ggplot(mtcars, aes(mpg, wt, colour = factor(cyl))) +
        geom_point_webgl(size = 3) +
        theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Points Smoke Test", subtitle = "Expected: point cloud in WebGL")
    )
  }

  if (identical(scenario, "lines")) {
    df <- transform(
      economics_long[economics_long$variable %in% c("psavert", "uempmed"), ],
      scaled_value = value01 * 100
    )

    return(
      ggplot(df, aes(date, scaled_value, colour = variable)) +
        geom_line_webgl(linewidth = 1.1) +
        theme_webgl(shader = "trajectory_age", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Lines Smoke Test", subtitle = "Expected: two time-series lines in WebGL")
    )
  }

  if (identical(scenario, "mixed")) {
    df <- data.frame(
      x = seq(-4, 4, length.out = 200),
      y = sin(seq(-4, 4, length.out = 200))
    )

    return(
      ggplot(df, aes(x, y)) +
        geom_line_webgl(linewidth = 1.2, colour = "#0f766e") +
        geom_point_webgl(
          data = df[seq(1, nrow(df), by = 8), , drop = FALSE],
          colour = "#b45309",
          size = 2.5
        ) +
        theme_webgl(shader = "trajectory_age", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Mixed Smoke Test", subtitle = "Expected: line plus sampled points")
    )
  }

  if (identical(scenario, "raster")) {
    grid <- expand.grid(x = seq(-2, 2, length.out = 24), y = seq(-2, 2, length.out = 18))
    grid$z <- with(grid, cos(x * 1.5) * sin(y * 1.2))

    return(
      ggplot(grid, aes(x, y, fill = z)) +
        geom_raster_webgl(interpolate = TRUE) +
        theme_webgl(shader = "default", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Raster Smoke Test", subtitle = "Expected: texture-backed raster rendering")
    )
  }

  ggplot(transform(mtcars, cyl = factor(cyl)), aes(mpg, wt, colour = cyl)) +
    geom_point_webgl(size = 2.4, alpha = 0.85) +
    ggplot2::facet_wrap(~cyl) +
    theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover")) +
    labs(title = "Facet Smoke Test", subtitle = "Expected: fixed-scale multi-panel point rendering")
}

run_manual_htmlwidget_smoke_test <- function(scenario = c("points", "lines", "mixed", "raster", "facet"),
                                             selfcontained = FALSE,
                                             browse = interactive()) {
  scenario <- match.arg(scenario)
  widget <- ggplot_webgl(smoke_test_plot(scenario), width = "100%", height = 520)
  output <- tempfile(pattern = paste0("ggwebgl-", scenario, "-"), fileext = ".html")

  htmlwidgets::saveWidget(widget, file = output, selfcontained = selfcontained)
  message("Saved smoke test widget to: ", output)

  if (isTRUE(browse)) {
    utils::browseURL(output)
  }

  invisible(output)
}
