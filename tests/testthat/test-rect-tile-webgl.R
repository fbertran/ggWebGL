test_that("geom_rect_webgl serializes ggplot2-built rectangle boundaries", {
  rects <- data.frame(
    xmin = c(0, 1.25),
    xmax = c(0.75, 2),
    ymin = c(-1, 0.5),
    ymax = c(0, 1.5),
    fill = c("a", "b")
  )
  plot <- ggplot2::ggplot(
    rects,
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill)
  ) +
    geom_rect_webgl(alpha = 0.6) +
    ggplot2::scale_fill_manual(values = c(a = "#0f766e", b = "#f97316")) +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$type, "rects")
  expect_equal(layer$geom, "GeomRectWebGL")
  expect_equal(layer$rows, 2L)
  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(layer$rgba[c(4, 8)], c(0.6, 0.6))
})

test_that("geom_tile_webgl serializes regular tile boundaries from ggplot2", {
  tiles <- expand.grid(x = 1:3, y = 1:2)
  tiles$value <- with(tiles, x + y)
  plot <- ggplot2::ggplot(tiles, ggplot2::aes(x, y, fill = value)) +
    geom_tile_webgl(alpha = 0.8) +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$type, "rects")
  expect_equal(layer$geom, "GeomTileWebGL")
  expect_equal(layer$rows, nrow(tiles))
  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(layer$rgba[seq(4, length(layer$rgba), by = 4)], rep(0.8, nrow(tiles)))
})

test_that("geom_tile_webgl respects irregular ggplot2-built boundaries", {
  tiles <- data.frame(
    x = c(1, 3, 8),
    y = c(2, 5, 6),
    value = c(1, 2, 3)
  )
  plot <- ggplot2::ggplot(tiles, ggplot2::aes(x, y, fill = value)) +
    geom_tile_webgl() +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(anyDuplicated(paste(layer$xmin, layer$xmax, layer$ymin, layer$ymax)), 0L)
})

test_that("rect and tile fill and alpha mappings are preserved", {
  rects <- data.frame(
    xmin = c(0, 1),
    xmax = c(1, 2),
    ymin = 0,
    ymax = 1,
    fill = c("low", "high"),
    alpha = c(0.25, 0.75)
  )
  plot <- ggplot2::ggplot(
    rects,
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill, alpha = alpha)
  ) +
    geom_rect_webgl() +
    ggplot2::scale_fill_manual(values = c(low = "#2563eb", high = "#f97316")) +
    ggplot2::scale_alpha_identity() +
    theme_webgl()

  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$rgba[seq(4, length(layer$rgba), by = 4)], rects$alpha)
  expect_true(length(unique(matrix(layer$rgba, ncol = 4L, byrow = TRUE)[, 1L])) > 1L)
})

test_that("rect and tile layers split across fixed-scale facets", {
  rects <- data.frame(
    xmin = c(0, 1, 2, 0),
    xmax = c(0.8, 1.8, 2.8, 0.6),
    ymin = c(0, 0, 0, 1),
    ymax = c(1, 1, 1, 2),
    panel = c("a", "a", "b", "b")
  )
  plot <- ggplot2::ggplot(
    rects,
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
  ) +
    geom_rect_webgl(fill = "#38bdf8") +
    ggplot2::facet_wrap(~panel) +
    theme_webgl()

  render <- ggplot_webgl(plot)$x$render

  expect_equal(render$mode, "webgl")
  expect_equal(render$rect_count, nrow(rects))
  expect_equal(unname(vapply(render$panels, `[[`, integer(1), "rect_count")), c(2L, 2L))
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$primitives, "rects")
  }, logical(1))))
})

test_that("raster behavior is unchanged by rectangle geoms", {
  grid <- expand.grid(x = 1:3, y = 1:2)
  grid$z <- with(grid, x + y)
  plot <- ggplot2::ggplot(grid, ggplot2::aes(x, y, fill = z)) +
    geom_raster_webgl(interpolate = TRUE) +
    theme_webgl()

  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$type, "raster")
  expect_equal(layer$width, 3L)
  expect_equal(layer$height, 2L)
  expect_true(layer$interpolate)
})
