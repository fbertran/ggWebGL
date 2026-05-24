test_that("geom_bin2d_webgl serializes ggplot2 stat_bin2d rectangles", {
  values <- data.frame(
    x = c(0.1, 0.2, 0.7, 1.2, 1.8, 2.1),
    y = c(0.1, 0.5, 0.6, 1.1, 1.3, 1.8)
  )
  plot <- ggplot2::ggplot(values, ggplot2::aes(x, y)) +
    geom_bin2d_webgl(binwidth = c(1, 1), boundary = c(0, 0)) +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$type, "rects")
  expect_equal(layer$geom, "GeomBin2dWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(layer$count, built$count)
  expect_equal(layer$density, built$density)
})

test_that("geom_bin2d_webgl preserves mapped fill from count and density", {
  values <- data.frame(
    x = c(0.1, 0.2, 0.7, 1.2, 1.8, 2.1),
    y = c(0.1, 0.5, 0.6, 1.1, 1.3, 1.8)
  )
  count_plot <- ggplot2::ggplot(values, ggplot2::aes(x, y, fill = ggplot2::after_stat(count))) +
    geom_bin2d_webgl(binwidth = c(1, 1), boundary = c(0, 0)) +
    theme_webgl()
  density_plot <- ggplot2::ggplot(values, ggplot2::aes(x, y, fill = ggplot2::after_stat(density))) +
    geom_bin2d_webgl(binwidth = c(1, 1), boundary = c(0, 0)) +
    theme_webgl()

  count_layer <- ggplot_webgl(count_plot)$x$render$layers[[1L]]
  density_layer <- ggplot_webgl(density_plot)$x$render$layers[[1L]]

  expect_equal(count_layer$count, ggplot2::ggplot_build(count_plot)$data[[1L]]$count)
  expect_equal(density_layer$density, ggplot2::ggplot_build(density_plot)$data[[1L]]$density)
  expect_gt(length(unique(matrix(count_layer$rgba, ncol = 4L, byrow = TRUE)[, 1L])), 1L)
  expect_gt(length(unique(matrix(density_layer$rgba, ncol = 4L, byrow = TRUE)[, 1L])), 1L)
})

test_that("geom_bin2d_webgl splits rectangles across fixed-scale facets", {
  values <- data.frame(
    x = c(0.1, 0.2, 0.7, 1.2, 1.8, 2.1, 0.1, 0.9, 1.2, 1.9),
    y = c(0.1, 0.5, 0.6, 1.1, 1.3, 1.8, 1.7, 1.4, 0.2, 0.8),
    panel = rep(c("left", "right"), each = 5)
  )
  plot <- ggplot2::ggplot(values, ggplot2::aes(x, y)) +
    geom_bin2d_webgl(binwidth = c(1, 1), boundary = c(0, 0)) +
    ggplot2::facet_wrap(~panel) +
    theme_webgl()

  render <- ggplot_webgl(plot)$x$render
  built <- ggplot2::ggplot_build(plot)$data[[1L]]

  expect_equal(render$mode, "webgl")
  expect_equal(render$rect_count, nrow(built))
  expect_equal(length(render$panels), 2L)
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "rects") &&
      identical(panel$layers[[1L]]$geom, "GeomBin2dWebGL")
  }, logical(1))))
  expect_equal(
    unname(vapply(render$panels, `[[`, integer(1), "rect_count")),
    as.integer(tabulate(as.integer(built$PANEL), nbins = 2L))
  )
})
