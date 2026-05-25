crossbar_render <- function(plot) {
  ggplot_webgl(plot)$x$render
}

crossbar_layers <- function(plot, panel = 1L) {
  crossbar_render(plot)$panels[[panel]]$layers
}

test_that("geom_crossbar_webgl serializes body and middle line", {
  df <- data.frame(
    x = 1:3,
    y = c(2, 3, 2.5),
    ymin = c(1, 2, 1.8),
    ymax = c(3, 4, 3.2)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
    geom_crossbar_webgl(width = 0.4, fill = "#93c5fd")
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layers <- crossbar_layers(plot)
  body <- layers[[1L]]
  middle <- layers[[2L]]

  expect_equal(vapply(layers, `[[`, character(1), "type"), c("rects", "vectors"))
  expect_equal(body$geom, "GeomCrossbarWebGL")
  expect_equal(middle$geom, "GeomCrossbarWebGL")
  expect_equal(body$rows, nrow(built))
  expect_equal(body$xmin, built$xmin)
  expect_equal(body$xmax, built$xmax)
  expect_equal(body$ymin, built$ymin)
  expect_equal(body$ymax, built$ymax)
  expect_equal(middle$x, built$xmin)
  expect_equal(middle$xend, built$xmax)
  expect_equal(middle$y, built$y)
  expect_equal(middle$yend, built$y)
  expect_equal(middle$head_size, rep(0, nrow(built)))
})

test_that("geom_crossbar_webgl preserves mapped fill in body payload", {
  df <- data.frame(
    x = 1:3,
    y = c(2, 3, 2.5),
    ymin = c(1, 2, 1.8),
    ymax = c(3, 4, 3.2),
    group = c("a", "b", "c"),
    alpha = c(0.4, 0.7, 1)
  )
  plot <- ggplot2::ggplot(
    df,
    ggplot2::aes(x, y, ymin = ymin, ymax = ymax, fill = group, alpha = alpha)
  ) +
    geom_crossbar_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  body <- crossbar_layers(plot)[[1L]]

  expect_equal(body$type, "rects")
  expect_equal(body$rows, nrow(built))
  expect_equal(body$rgba[seq(4, length(body$rgba), by = 4)], built$alpha)
  expect_length(unique(matrix(body$rgba, ncol = 4, byrow = TRUE)[, 1]), 3L)
})

test_that("geom_crossbar_webgl preserves mapped colour in middle payload", {
  df <- data.frame(
    x = 1:3,
    y = c(2, 3, 2.5),
    ymin = c(1, 2, 1.8),
    ymax = c(3, 4, 3.2),
    group = c("a", "b", "c")
  )
  plot <- ggplot2::ggplot(
    df,
    ggplot2::aes(x, y, ymin = ymin, ymax = ymax, colour = group)
  ) +
    geom_crossbar_webgl(linewidth = 1.1)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  middle <- crossbar_layers(plot)[[2L]]

  expect_equal(middle$type, "vectors")
  expect_equal(middle$rows, nrow(built))
  expect_true(all(middle$width > 0))
  expect_length(unique(matrix(middle$rgba, ncol = 4, byrow = TRUE)[, 1]), 3L)
})

test_that("geom_crossbar_webgl splits body and middle across fixed-scale facets", {
  df <- data.frame(
    x = rep(1:3, 2),
    y = c(2, 3, 2.5, 1.5, 2.5, 3.5),
    ymin = c(1, 2, 1.8, 0.8, 1.8, 2.8),
    ymax = c(3, 4, 3.2, 2.1, 3.1, 4.1),
    panel = rep(c("left", "right"), each = 3)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
    geom_crossbar_webgl(width = 0.35) +
    ggplot2::facet_wrap(~panel)
  render <- crossbar_render(plot)

  expect_equal(length(render$panels), 2L)
  expect_equal(sort(render$primitives), c("rects", "vectors"))
  expect_equal(render$rect_count, nrow(df))
  expect_equal(render$vector_count, nrow(df))
  expect_true(all(vapply(render$panels, function(panel) {
    identical(vapply(panel$layers, `[[`, character(1), "type"), c("rects", "vectors")) &&
      panel$rect_count == 3L &&
      panel$vector_count == 3L
  }, logical(1))))
})
