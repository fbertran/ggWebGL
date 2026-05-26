coordinate_widget <- function(plot) {
  ggplot_webgl(plot + theme_webgl(interactions = character()))
}

test_that("coord_webgl_3d remains a WebGL view contract", {
  data <- data.frame(x = c(0, 1), y = c(0, 1), z = c(0.2, 0.8))
  widget <- coordinate_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, z = z)) +
      geom_point_webgl() +
      coord_webgl_3d(projection = "perspective", camera = "orbit")
  )

  expect_equal(widget$x$render$coordinate_system, "cartesian3d")
  expect_equal(widget$x$render$dimension, "3d")
  expect_equal(widget$x$render$camera$controller, "orbit")
  expect_equal(widget$x$render$camera$projection, "perspective")
  expect_true(widget$x$render$depth_test)
  expect_equal(widget$x$render$panels[[1L]]$coord$type, "cartesian")
})

test_that("coord_cartesian limits are carried as panel viewport metadata", {
  data <- data.frame(x = 1:5, y = (1:5) * 10)
  widget <- coordinate_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      ggplot2::coord_cartesian(xlim = c(2, 4), ylim = c(20, 40), expand = FALSE)
  )
  panel <- widget$x$render$panels[[1L]]
  layer <- panel$layers[[1L]]

  expect_equal(panel$viewport$x, c(2, 4))
  expect_equal(panel$viewport$y, c(20, 40))
  expect_equal(panel$coord$type, "cartesian")
  expect_equal(panel$coord$clip, "on")
  expect_equal(panel$viewport_source, "ggplot2")
  expect_equal(layer$x, data$x)
  expect_equal(layer$y, data$y)
})

test_that("coord_cartesian clip metadata is preserved", {
  widget <- coordinate_widget(
    ggplot2::ggplot(data.frame(x = 1:2, y = 1:2), ggplot2::aes(x, y)) +
      geom_point_webgl() +
      ggplot2::coord_cartesian(clip = "off")
  )

  expect_equal(widget$x$render$coord$clip, "off")
  expect_equal(widget$x$render$panels[[1L]]$coord$clip, "off")
})

test_that("coord_fixed aspect metadata is preserved conservatively", {
  widget <- coordinate_widget(
    ggplot2::ggplot(data.frame(x = c(1, 2, 3), y = c(10, 20, 30)), ggplot2::aes(x, y)) +
      geom_point_webgl() +
      ggplot2::coord_fixed(ratio = 2)
  )
  coord <- widget$x$render$panels[[1L]]$coord

  expect_equal(coord$type, "cartesian")
  expect_true(coord$fixed)
  expect_equal(coord$ratio, 2)
  expect_true(is.finite(coord$aspect))
  expect_gt(coord$aspect, 0)
})

test_that("coord_flip swaps data-coordinate payloads after ggplot2 builds layers", {
  data <- data.frame(x = c(1, 2, 3), y = c(10, 20, 30))
  widget <- coordinate_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      ggplot2::coord_flip()
  )
  panel <- widget$x$render$panels[[1L]]
  layer <- panel$layers[[1L]]

  expect_equal(widget$x$render$coord$type, "cartesian_flip")
  expect_true(panel$coord$flipped)
  expect_equal(layer$x, data$y)
  expect_equal(layer$y, data$x)
  expect_equal(panel$viewport$x, c(9, 31))
  expect_equal(panel$viewport$y, c(0.9, 3.1))
})

test_that("coord_flip swaps segment endpoints without changing vector semantics", {
  data <- data.frame(x = c(1, 2), y = c(10, 20), xend = c(3, 4), yend = c(30, 40))
  widget <- coordinate_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, xend = xend, yend = yend)) +
      geom_segment_webgl() +
      ggplot2::coord_flip()
  )
  layer <- widget$x$render$panels[[1L]]$layers[[1L]]

  expect_equal(layer$type, "vectors")
  expect_true(all(layer$head_size == 0))
  expect_equal(layer$x, data$y)
  expect_equal(layer$y, data$x)
  expect_equal(layer$xend, data$yend)
  expect_equal(layer$yend, data$xend)
})

test_that("fixed-scale facets keep panel labels, viewports, and scale metadata", {
  data <- data.frame(
    panel = rep(c("left", "right"), each = 3),
    x = c(1, 2, 3, 4, 5, 6),
    y = c(2, 3, 4, 5, 6, 7)
  )
  widget <- coordinate_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      ggplot2::facet_wrap(~panel)
  )
  render <- widget$x$render

  expect_equal(render$mode, "webgl")
  expect_equal(render$scales$mode, "fixed")
  expect_false(render$scales$free_x)
  expect_false(render$scales$free_y)
  expect_equal(length(render$panels), 2L)
  expect_equal(vapply(render$panels, `[[`, character(1), "label"), c("panel=left", "panel=right"))
  expect_true(all(vapply(render$panels, function(panel) identical(panel$viewport, render$panels[[1L]]$viewport), logical(1))))
  expect_equal(vapply(render$panels, `[[`, integer(1), "scale_x"), c(1L, 1L))
  expect_equal(vapply(render$panels, `[[`, integer(1), "scale_y"), c(1L, 1L))
})

test_that("free-scale facets remain an explicit metadata fallback", {
  data <- data.frame(
    panel = rep(c("left", "right"), each = 3),
    x = c(1, 2, 3, 100, 200, 300),
    y = c(2, 3, 4, 5, 6, 7)
  )
  widget <- coordinate_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      ggplot2::facet_wrap(~panel, scales = "free_x")
  )
  render <- widget$x$render

  expect_equal(render$mode, "metadata")
  expect_equal(render$scales$mode, "free")
  expect_true(render$scales$free_x)
  expect_false(render$scales$free_y)
  expect_match(render$messages[[1L]], "free x or y scales", fixed = TRUE)
  expect_equal(length(render$panels), 2L)
  expect_true(all(vapply(render$panels, function(panel) length(panel$layers) == 0L, logical(1))))
  expect_false(identical(render$panels[[1L]]$viewport$x, render$panels[[2L]]$viewport$x))
})

test_that("widget source prefers explicit panel viewports and keeps layer bounds as fallback", {
  js <- paste(readLines(testthat::test_path("../../inst/htmlwidgets/ggWebGL.js"), warn = FALSE), collapse = "\n")

  expect_match(js, "viewport_explicit", fixed = TRUE)
  expect_match(js, "viewport_source", fixed = TRUE)
  expect_match(js, "panel.viewport_explicit !== false", fixed = TRUE)
  expect_match(js, "supportedLayerBounds(panel)", fixed = TRUE)
  expect_match(js, "coord: source.coord", fixed = TRUE)
})
