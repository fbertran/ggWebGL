path3d_layer <- function(widget, panel = 1L, layer = 1L) {
  widget$x$render$panels[[panel]]$layers[[layer]]
}

test_that("geom_path3d_webgl serializes one ordered 3D path", {
  data <- data.frame(
    x = c(3, 1, 2),
    y = c(0.1, 0.8, 0.4),
    z = c(0, 0.5, 1),
    frame = c(10L, 11L, 12L)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, z = z, frame = frame)) +
      geom_path3d_webgl(linewidth = 1.2)
  )
  layer <- path3d_layer(widget)
  path <- layer$paths[[1L]]

  expect_equal(widget$x$render$dimension, "3d")
  expect_equal(widget$x$render$coordinate_system, "cartesian3d")
  expect_equal(layer$type, "lines")
  expect_equal(layer$subtype, "path3d")
  expect_equal(layer$path_count, 1L)
  expect_equal(path$subtype, "path3d")
  expect_equal(path$x, c(3, 1, 2))
  expect_equal(path$z, c(0, 0.5, 1))
  expect_equal(path$frame, c(10L, 11L, 12L))
})

test_that("geom_path3d_webgl preserves row order within multiple groups", {
  data <- data.frame(
    trajectory = c("a", "b", "a", "b", "a", "b"),
    x = c(3, 30, 1, 10, 2, 20),
    y = c(0.1, 1.1, 0.8, 1.8, 0.4, 1.4),
    z = c(0, 1, 0.5, 1.5, 1, 2),
    time = c(0, 0, 0.5, 0.5, 1, 1)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, z = z, group = trajectory, time = time, colour = trajectory)) +
      geom_path3d_webgl(linewidth = 1)
  )
  layer <- path3d_layer(widget)
  xs <- lapply(layer$paths, `[[`, "x")
  zs <- lapply(layer$paths, `[[`, "z")
  times <- lapply(layer$paths, `[[`, "time")

  expect_equal(layer$path_count, 2L)
  expect_true(any(vapply(xs, identical, logical(1), c(3, 1, 2))))
  expect_true(any(vapply(xs, identical, logical(1), c(30, 10, 20))))
  expect_true(any(vapply(zs, identical, logical(1), c(0, 0.5, 1))))
  expect_true(any(vapply(times, identical, logical(1), c(0, 0.5, 1))))
})

test_that("geom_path3d_webgl serializes time values", {
  data <- data.frame(
    x = c(0, 0.25, 0.75, 1),
    y = c(0, 0.5, 0.25, 1),
    z = c(0, 0.2, 0.6, 1),
    time = c(0, 0.15, 0.7, 1.4)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, z = z, time = time)) +
      geom_path3d_webgl()
  )

  expect_equal(path3d_layer(widget)$paths[[1L]]$time, data$time)
})

test_that("geom_path3d_webgl works in fixed-scale facets", {
  data <- data.frame(
    panel = rep(c("left", "right"), each = 3),
    trajectory = rep(c("a", "b"), each = 3),
    x = c(0, 0.3, 0.8, 1, 1.4, 1.8),
    y = c(0, 0.7, 0.4, 1, 1.6, 1.3),
    z = c(0, 0.2, 0.5, 0.1, 0.4, 0.9),
    frame = rep(1:3, times = 2)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, z = z, group = trajectory, frame = frame)) +
      geom_path3d_webgl() +
      ggplot2::facet_wrap(~panel)
  )

  expect_equal(length(widget$x$render$panels), 2L)
  expect_true(all(vapply(widget$x$render$panels, function(panel) {
    identical(panel$layers[[1L]]$subtype, "path3d") &&
      !is.null(panel$layers[[1L]]$paths[[1L]]$z) &&
      !is.null(panel$layers[[1L]]$paths[[1L]]$frame)
  }, logical(1))))
})

test_that("geom_line_webgl keeps existing x-sorted 2D behavior", {
  data <- data.frame(
    x = c(3, 1, 2),
    y = c(0.1, 0.8, 0.4)
  )

  line_widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_line_webgl()
  )
  path_widget <- ggplot_webgl(
    ggplot2::ggplot(transform(data, z = c(0, 0.5, 1)), ggplot2::aes(x, y, z = z)) +
      geom_path3d_webgl()
  )

  expect_equal(path3d_layer(line_widget)$paths[[1L]]$x, c(1, 2, 3))
  expect_null(path3d_layer(line_widget)$subtype)
  expect_equal(line_widget$x$render$dimension, "2d")
  expect_equal(path3d_layer(path_widget)$paths[[1L]]$x, c(3, 1, 2))
  expect_equal(path_widget$x$render$dimension, "3d")
})
