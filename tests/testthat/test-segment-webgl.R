segment_layer <- function(widget, panel = 1L, layer = 1L) {
  widget$x$render$panels[[panel]]$layers[[layer]]
}

test_that("geom_segment_webgl serializes pure 2D segments", {
  segments <- data.frame(
    x = c(0, 1),
    y = c(0, 0.2),
    xend = c(0.8, 1.6),
    yend = c(0.7, 1),
    frame = 1:2
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(segments, ggplot2::aes(x, y, xend = xend, yend = yend, frame = frame)) +
      geom_segment_webgl(linewidth = 1.2)
  )
  layer <- segment_layer(widget)

  expect_equal(widget$x$render$dimension, "2d")
  expect_equal(layer$type, "vectors")
  expect_equal(layer$geom, "GeomSegmentWebGL")
  expect_equal(layer$rows, 2L)
  expect_equal(layer$x, segments$x)
  expect_equal(layer$yend, segments$yend)
  expect_equal(layer$frame, 1:2)
  expect_equal(layer$head_size, c(0, 0))
})

test_that("geom_segment_webgl serializes optional z and zend coordinates", {
  segments <- data.frame(
    x = c(0, 1),
    y = c(0, 0.2),
    z = c(0.1, 0.4),
    xend = c(0.8, 1.6),
    yend = c(0.7, 1),
    zend = c(0.5, 0.9)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(segments, ggplot2::aes(x, y, z = z, xend = xend, yend = yend, zend = zend)) +
      geom_segment_webgl() +
      coord_webgl_3d()
  )
  layer <- segment_layer(widget)

  expect_equal(widget$x$render$coordinate_system, "cartesian3d")
  expect_equal(layer$z, segments$z)
  expect_equal(layer$zend, segments$zend)
  expect_equal(layer$head_size, c(0, 0))
})

test_that("geom_segment_webgl preserves mapped colour, alpha, and linewidth", {
  segments <- data.frame(
    x = c(0, 1),
    y = c(0, 0.2),
    xend = c(0.8, 1.6),
    yend = c(0.7, 1),
    colour = c("#ff0000", "#0000ff"),
    alpha = c(0.25, 0.75),
    linewidth = c(0.5, 1.5)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(
      segments,
      ggplot2::aes(
        x,
        y,
        xend = xend,
        yend = yend,
        colour = colour,
        alpha = alpha,
        linewidth = linewidth
      )
    ) +
      geom_segment_webgl() +
      ggplot2::scale_colour_identity() +
      ggplot2::scale_alpha_identity() +
      ggplot2::scale_linewidth_identity()
  )
  layer <- segment_layer(widget)
  rgba <- matrix(layer$rgba, ncol = 4L, byrow = TRUE)

  expect_equal(layer$head_size, c(0, 0))
  expect_length(layer$width, 2L)
  expect_gt(layer$width[[2L]], layer$width[[1L]])
  expect_equal(rgba[, 4L], segments$alpha, tolerance = 1e-8)
})

test_that("geom_segment_webgl works in fixed-scale facets", {
  segments <- data.frame(
    panel = rep(c("left", "right"), each = 2),
    x = c(0, 1, 0.2, 1.2),
    y = c(0, 0.2, 0.1, 0.4),
    xend = c(0.8, 1.6, 0.9, 1.8),
    yend = c(0.7, 1, 0.6, 1.1),
    time = c(0, 1, 0, 1)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(segments, ggplot2::aes(x, y, xend = xend, yend = yend, time = time)) +
      geom_segment_webgl() +
      ggplot2::facet_wrap(~panel)
  )

  expect_equal(length(widget$x$render$panels), 2L)
  expect_true(all(vapply(widget$x$render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "vectors") &&
      identical(panel$layers[[1L]]$geom, "GeomSegmentWebGL") &&
      all(panel$layers[[1L]]$head_size == 0)
  }, logical(1))))
})

test_that("geom_vector_webgl keeps arrowhead behavior", {
  arrows <- data.frame(x = 0:1, y = 0:1, xend = c(0.5, 1.4), yend = c(0.2, 1.2))

  default_vector <- segment_layer(
    ggplot_webgl(
      ggplot2::ggplot(arrows, ggplot2::aes(x, y, xend = xend, yend = yend)) +
        geom_vector_webgl()
    )
  )
  sized_vector <- segment_layer(
    ggplot_webgl(
      ggplot2::ggplot(arrows, ggplot2::aes(x, y, xend = xend, yend = yend)) +
        geom_vector_webgl(head_size = 6)
    )
  )

  expect_equal(default_vector$geom, "GeomVectorWebGL")
  expect_equal(default_vector$head_size, c(9, 9))
  expect_equal(sized_vector$head_size, c(6, 6))
})

test_that("vector renderer source honors zero-sized arrowheads for segments", {
  js <- paste(readLines(testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js"), warn = FALSE), collapse = "\n")

  expect_match(js, "var hasHead = isFinite(rawHead) ? rawHead > 0 : true;", fixed = TRUE)
  expect_match(js, "if (hasHead) {", fixed = TRUE)
})
