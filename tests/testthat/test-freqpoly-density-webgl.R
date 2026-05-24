line_layer <- function(plot) {
  ggplot_webgl(plot)$x$render$layers[[1L]]
}

path_xy <- function(layer) {
  list(
    x = unlist(lapply(layer$paths, `[[`, "x"), use.names = FALSE),
    y = unlist(lapply(layer$paths, `[[`, "y"), use.names = FALSE)
  )
}

test_that("geom_freqpoly_webgl serializes stat_bin paths", {
  values <- data.frame(x = c(0.1, 0.2, 0.7, 1.2, 1.6, 2.1, 2.2, 2.8))
  plot <- ggplot2::ggplot(values, ggplot2::aes(x)) +
    geom_freqpoly_webgl(binwidth = 1, boundary = 0, colour = "#2563eb") +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- line_layer(plot)
  xy <- path_xy(layer)

  expect_equal(layer$type, "lines")
  expect_equal(layer$geom, "GeomFreqpolyWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$path_count, length(unique(built$group)))
  expect_equal(xy$x, built$x)
  expect_equal(xy$y, built$y)
})

test_that("geom_freqpoly_webgl serializes grouped stat_bin paths", {
  values <- data.frame(
    x = c(0.1, 0.2, 0.7, 1.2, 1.6, 2.1, 2.2, 2.8),
    group = rep(c("a", "b"), each = 4)
  )
  plot <- ggplot2::ggplot(values, ggplot2::aes(x, colour = group)) +
    geom_freqpoly_webgl(binwidth = 1, boundary = 0) +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- line_layer(plot)
  xy <- path_xy(layer)

  expect_equal(layer$type, "lines")
  expect_equal(layer$path_count, length(unique(built$group)))
  expect_equal(xy$x, built$x)
  expect_equal(xy$y, built$y)
})

test_that("geom_density_webgl serializes stat_density curves", {
  values <- data.frame(x = seq(-2, 2, length.out = 40))
  plot <- ggplot2::ggplot(values, ggplot2::aes(x)) +
    geom_density_webgl(colour = "#0f766e") +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- line_layer(plot)
  xy <- path_xy(layer)

  expect_equal(layer$type, "lines")
  expect_equal(layer$geom, "GeomDensityWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$path_count, length(unique(built$group)))
  expect_equal(xy$x, built$x)
  expect_equal(xy$y, built$y)
})

test_that("geom_density_webgl serializes grouped stat_density curves", {
  values <- data.frame(
    x = c(seq(-2, 0, length.out = 32), seq(0, 2, length.out = 32)),
    group = rep(c("a", "b"), each = 32)
  )
  plot <- ggplot2::ggplot(values, ggplot2::aes(x, colour = group)) +
    geom_density_webgl() +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- line_layer(plot)
  xy <- path_xy(layer)

  expect_equal(layer$type, "lines")
  expect_equal(layer$path_count, length(unique(built$group)))
  expect_equal(xy$x, built$x)
  expect_equal(xy$y, built$y)
})

test_that("density fill is accepted as unsupported line metadata", {
  values <- data.frame(
    x = c(seq(-2, 0, length.out = 32), seq(0, 2, length.out = 32)),
    group = rep(c("a", "b"), each = 32)
  )
  plot <- ggplot2::ggplot(values, ggplot2::aes(x, fill = group)) +
    geom_density_webgl(colour = NA) +
    theme_webgl()

  layer <- line_layer(plot)
  default_rgba <- as.numeric(colour_to_rgba("#2C3E50", 1))

  expect_equal(layer$type, "lines")
  expect_equal(layer$path_count, 2L)
  expect_equal(layer$paths[[1L]]$rgba[1:4], default_rgba)
})

test_that("freqpoly and density paths split across fixed-scale facets", {
  values <- data.frame(
    x = c(seq(-2, 0, length.out = 32), seq(0, 2, length.out = 32)),
    panel = rep(c("left", "right"), each = 32)
  )

  freqpoly_plot <- ggplot2::ggplot(values, ggplot2::aes(x)) +
    geom_freqpoly_webgl(binwidth = 0.5) +
    ggplot2::facet_wrap(~panel) +
    theme_webgl()
  density_plot <- ggplot2::ggplot(values, ggplot2::aes(x)) +
    geom_density_webgl() +
    ggplot2::facet_wrap(~panel) +
    theme_webgl()

  freqpoly_render <- ggplot_webgl(freqpoly_plot)$x$render
  density_render <- ggplot_webgl(density_plot)$x$render

  expect_equal(length(freqpoly_render$panels), 2L)
  expect_equal(length(density_render$panels), 2L)
  expect_true(all(vapply(freqpoly_render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "lines")
  }, logical(1))))
  expect_true(all(vapply(density_render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "lines")
  }, logical(1))))
})
