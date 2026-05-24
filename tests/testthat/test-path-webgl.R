path2d_layer <- function(widget, panel = 1L, layer = 1L) {
  widget$x$render$panels[[panel]]$layers[[layer]]
}

test_that("geom_path_webgl serializes one ordered 2D path", {
  data <- data.frame(
    x = c(3, 1, 2),
    y = c(0.1, 0.8, 0.4),
    frame = c(10L, 11L, 12L)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, frame = frame)) +
      geom_path_webgl(linewidth = 1.2)
  )
  layer <- path2d_layer(widget)
  path <- layer$paths[[1L]]

  expect_equal(widget$x$render$dimension, "2d")
  expect_equal(widget$x$render$coordinate_system, "cartesian2d")
  expect_equal(layer$type, "lines")
  expect_null(layer$subtype)
  expect_equal(layer$path_count, 1L)
  expect_null(path$subtype)
  expect_equal(path$x, c(3, 1, 2))
  expect_equal(path$frame, c(10L, 11L, 12L))
})

test_that("geom_path_webgl preserves row order within multiple groups", {
  data <- data.frame(
    trajectory = c("a", "b", "a", "b", "a", "b"),
    x = c(3, 30, 1, 10, 2, 20),
    y = c(0.1, 1.1, 0.8, 1.8, 0.4, 1.4),
    time = c(0, 0, 0.5, 0.5, 1, 1)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, group = trajectory, time = time, colour = trajectory)) +
      geom_path_webgl(linewidth = 1)
  )
  layer <- path2d_layer(widget)
  xs <- lapply(layer$paths, `[[`, "x")
  times <- lapply(layer$paths, `[[`, "time")

  expect_equal(layer$path_count, 2L)
  expect_true(any(vapply(xs, identical, logical(1), c(3, 1, 2))))
  expect_true(any(vapply(xs, identical, logical(1), c(30, 10, 20))))
  expect_true(any(vapply(times, identical, logical(1), c(0, 0.5, 1))))
})

test_that("geom_path_webgl breaks paths at missing coordinates", {
  data <- data.frame(
    x = c(0, 1, NA, 2, 3),
    y = c(0, 1, 0.5, 2, 3),
    frame = 1:5
  )

  widget <- suppressWarnings(ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, frame = frame)) +
      geom_path_webgl()
  ))
  layer <- path2d_layer(widget)

  expect_equal(layer$path_count, 2L)
  expect_equal(layer$paths[[1L]]$x, c(0, 1))
  expect_equal(layer$paths[[2L]]$x, c(2, 3))
  expect_equal(layer$paths[[1L]]$frame, c(1L, 2L))
  expect_equal(layer$paths[[2L]]$frame, c(4L, 5L))
})

test_that("geom_path_webgl works in fixed-scale facets", {
  data <- data.frame(
    panel = rep(c("left", "right"), each = 3),
    trajectory = rep(c("a", "b"), each = 3),
    x = c(0, 0.3, 0.8, 1, 1.4, 1.8),
    y = c(0, 0.7, 0.4, 1, 1.6, 1.3),
    frame = rep(1:3, times = 2)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y, group = trajectory, frame = frame)) +
      geom_path_webgl() +
      ggplot2::facet_wrap(~panel)
  )

  expect_equal(length(widget$x$render$panels), 2L)
  expect_true(all(vapply(widget$x$render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "lines") &&
      is.null(panel$layers[[1L]]$subtype) &&
      !is.null(panel$layers[[1L]]$paths[[1L]]$frame)
  }, logical(1))))
})

test_that("geom_path_webgl does not change line sorting or 3D path behavior", {
  data <- data.frame(
    x = c(3, 1, 2),
    y = c(0.1, 0.8, 0.4)
  )

  line_widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_line_webgl()
  )
  path_widget <- ggplot_webgl(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_path_webgl()
  )
  path3d_widget <- ggplot_webgl(
    ggplot2::ggplot(transform(data, z = c(0, 0.5, 1)), ggplot2::aes(x, y, z = z)) +
      geom_path3d_webgl()
  )

  expect_equal(path2d_layer(line_widget)$paths[[1L]]$x, c(1, 2, 3))
  expect_equal(path2d_layer(path_widget)$paths[[1L]]$x, c(3, 1, 2))
  expect_equal(path2d_layer(path3d_widget)$paths[[1L]]$x, c(3, 1, 2))
  expect_equal(path2d_layer(path3d_widget)$subtype, "path3d")
  expect_equal(line_widget$x$render$dimension, "2d")
  expect_equal(path_widget$x$render$dimension, "2d")
  expect_equal(path3d_widget$x$render$dimension, "3d")
})
