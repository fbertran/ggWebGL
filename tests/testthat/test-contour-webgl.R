contour_line_layer <- function(plot, panel = 1L) {
  ggplot_webgl(plot)$x$render$panels[[panel]]$layers[[1L]]
}

contour_path_field <- function(layer, field) {
  unlist(lapply(layer$paths, `[[`, field), use.names = FALSE)
}

contour_grid <- function(n = 7L) {
  grid <- expand.grid(
    x = seq(-1, 1, length.out = n),
    y = seq(-1, 1, length.out = n)
  )
  grid$z <- with(grid, x^2 - y^2)
  grid
}

test_that("geom_density2d_webgl serializes stat_density_2d contours as paths", {
  skip_if_not_installed("MASS")

  points <- expand.grid(
    x = seq(-1, 1, length.out = 8),
    y = seq(-1, 1, length.out = 8)
  )
  plot <- ggplot2::ggplot(points, ggplot2::aes(x, y)) +
    geom_density2d_webgl(bins = 3, colour = "#2563eb") +
    theme_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- contour_line_layer(plot)

  expect_equal(layer$type, "lines")
  expect_equal(layer$geom, "GeomDensity2dWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$path_count, length(unique(built$group)))
  expect_equal(contour_path_field(layer, "x"), built$x)
  expect_equal(contour_path_field(layer, "y"), built$y)
  expect_equal(contour_path_field(layer, "level"), built$level)
})

test_that("geom_contour_webgl serializes gridded z contours as paths", {
  grid <- contour_grid()
  plot <- ggplot2::ggplot(grid, ggplot2::aes(x, y, z = z)) +
    geom_contour_webgl(bins = 4, colour = "#0f766e") +
    theme_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- contour_line_layer(plot)

  expect_equal(layer$type, "lines")
  expect_equal(layer$geom, "GeomContourWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$path_count, length(unique(built$group)))
  expect_equal(contour_path_field(layer, "x"), built$x)
  expect_equal(contour_path_field(layer, "y"), built$y)
  expect_equal(contour_path_field(layer, "level"), built$level)
})

test_that("geom_contour_webgl preserves multiple contour levels", {
  grid <- contour_grid(9L)
  plot <- ggplot2::ggplot(grid, ggplot2::aes(x, y, z = z)) +
    geom_contour_webgl(breaks = c(-0.5, 0, 0.5), ggplot2::aes(colour = ggplot2::after_stat(level))) +
    theme_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- contour_line_layer(plot)
  levels <- contour_path_field(layer, "level")

  expect_equal(layer$type, "lines")
  expect_setequal(unique(levels), unique(built$level))
  expect_gt(length(unique(levels)), 1L)
  expect_equal(contour_path_field(layer, "x"), built$x)
  expect_gt(length(unique(matrix(layer$paths[[1L]]$rgba, ncol = 4L, byrow = TRUE)[, 1L])), 0L)
})

test_that("line contours split across fixed-scale facets", {
  grid <- contour_grid()
  faceted <- rbind(
    transform(grid, panel = "left"),
    transform(grid, panel = "right", z = z + 0.25)
  )
  plot <- ggplot2::ggplot(faceted, ggplot2::aes(x, y, z = z)) +
    geom_contour_webgl(bins = 4) +
    ggplot2::facet_wrap(~panel) +
    theme_webgl()
  render <- ggplot_webgl(plot)$x$render

  expect_equal(length(render$panels), 2L)
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "lines") &&
      identical(panel$layers[[1L]]$geom, "GeomContourWebGL") &&
      panel$layers[[1L]]$path_count > 0L
  }, logical(1))))
})
