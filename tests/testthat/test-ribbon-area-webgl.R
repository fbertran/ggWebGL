ribbon_layer <- function(plot, panel = 1L) {
  ggplot_webgl(plot)$x$render$panels[[panel]]$layers[[1L]]
}

collect_ribbon_strips <- function(layer, field) {
  unlist(lapply(layer$strips, `[[`, field), use.names = FALSE)
}

test_that("geom_ribbon_webgl serializes one filled ribbon strip", {
  df <- data.frame(
    x = 1:4,
    ymin = c(0.1, 0.2, 0.1, 0.3),
    ymax = c(0.5, 0.7, 0.6, 0.8)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, ymin = ymin, ymax = ymax)) +
    geom_ribbon_webgl(fill = "#38bdf8", alpha = 0.6)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ribbon_layer(plot)

  expect_equal(layer$type, "ribbons")
  expect_equal(layer$geom, "GeomRibbonWebGL")
  expect_equal(layer$strip_count, 1L)
  expect_equal(layer$triangle_count, 6L)
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$strips[[1L]]$x, built$x)
  expect_equal(layer$strips[[1L]]$ymin, built$ymin)
  expect_equal(layer$strips[[1L]]$ymax, built$ymax)
  expect_equal(length(layer$strips[[1L]]$rgba), nrow(built) * 4L)
})

test_that("geom_ribbon_webgl preserves grouped ribbon boundaries", {
  df <- data.frame(
    x = rep(1:4, 2),
    ymin = c(0.1, 0.2, 0.2, 0.3, 0.5, 0.4, 0.6, 0.5),
    ymax = c(0.4, 0.6, 0.5, 0.7, 0.9, 1.0, 0.95, 1.1),
    group = rep(c("a", "b"), each = 4)
  )
  plot <- ggplot2::ggplot(
    df,
    ggplot2::aes(x, ymin = ymin, ymax = ymax, group = group, fill = group)
  ) +
    geom_ribbon_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ribbon_layer(plot)

  expect_equal(layer$strip_count, length(unique(built$group)))
  expect_equal(layer$rows, nrow(built))
  expect_equal(collect_ribbon_strips(layer, "x"), built$x)
  expect_equal(collect_ribbon_strips(layer, "ymin"), built$ymin)
  expect_equal(collect_ribbon_strips(layer, "ymax"), built$ymax)
})

test_that("geom_ribbon_webgl breaks strips across missing values", {
  df <- data.frame(
    x = 1:5,
    ymin = c(0.1, 0.2, NA, 0.2, 0.3),
    ymax = c(0.5, 0.7, NA, 0.8, 0.9)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, ymin = ymin, ymax = ymax)) +
    geom_ribbon_webgl()
  layer <- ribbon_layer(plot)

  expect_equal(layer$strip_count, 2L)
  expect_equal(unname(vapply(layer$strips, `[[`, integer(1), "rows")), c(2L, 2L))
  expect_false(anyNA(collect_ribbon_strips(layer, "ymin")))
  expect_false(anyNA(collect_ribbon_strips(layer, "ymax")))
})

test_that("geom_area_webgl consumes ggplot2-built area baselines", {
  df <- data.frame(x = 1:4, y = c(1, 2, 1, 3))
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y)) +
    geom_area_webgl(fill = "#0f766e", alpha = 0.7)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ribbon_layer(plot)

  expect_equal(layer$type, "ribbons")
  expect_equal(layer$geom, "GeomAreaWebGL")
  expect_equal(layer$strip_count, length(unique(built$group)))
  expect_equal(collect_ribbon_strips(layer, "x"), built$x)
  expect_equal(collect_ribbon_strips(layer, "ymin"), built$ymin)
  expect_equal(collect_ribbon_strips(layer, "ymax"), built$ymax)
  expect_true(all(built$ymin == 0))
})

test_that("geom_area_webgl preserves ggplot2-built stacked boundaries", {
  df <- data.frame(
    x = rep(1:4, 2),
    y = c(1, 2, 1, 2, 0.5, 1, 1.5, 1),
    group = rep(c("a", "b"), each = 4)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = group)) +
    geom_area_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ribbon_layer(plot)

  expect_equal(layer$strip_count, length(unique(built$group)))
  expect_equal(layer$rows, nrow(built))
  expect_equal(collect_ribbon_strips(layer, "ymin"), built$ymin)
  expect_equal(collect_ribbon_strips(layer, "ymax"), built$ymax)
  expect_true(any(built$ymin > 0))
})

test_that("ribbon and area layers split across fixed-scale facets", {
  df <- data.frame(
    x = rep(1:4, 2),
    ymin = c(0, 0.2, 0.1, 0.3, 0.4, 0.5, 0.45, 0.6),
    ymax = c(0.4, 0.6, 0.5, 0.7, 0.9, 1.0, 1.1, 1.2),
    panel = rep(c("left", "right"), each = 4)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, ymin = ymin, ymax = ymax)) +
    geom_ribbon_webgl() +
    ggplot2::facet_wrap(~panel)
  widget <- ggplot_webgl(plot)
  render <- widget$x$render

  expect_equal(length(render$panels), 2L)
  expect_equal(render$primitives, "ribbons")
  expect_equal(render$ribbon_count, 2L)
  expect_equal(render$ribbon_vertex_count, nrow(df))
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$primitives, "ribbons") &&
      panel$ribbon_count == 1L &&
      panel$ribbon_vertex_count == 4L &&
      panel$ribbon_triangle_count == 6L
  }, logical(1))))
})

test_that("ribbon primitive has a dedicated JS normalization and draw path", {
  js <- ggwebgl_test_read_text("inst/htmlwidgets/ggWebGL.js")

  expect_match(js, "type === \"ribbons\"", fixed = TRUE)
  expect_match(js, "function flattenRibbonLayer", fixed = TRUE)
  expect_match(js, "function drawRibbonLayer", fixed = TRUE)
  expect_match(js, "function drawRibbonsLayer", fixed = TRUE)
  expect_match(js, "layer.type === \"ribbons\"", fixed = TRUE)
  expect_match(js, "gl.drawArrays(gl.TRIANGLES", fixed = TRUE)
})
