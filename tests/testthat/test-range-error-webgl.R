range_render <- function(plot) {
  ggplot_webgl(plot)$x$render
}

range_layer <- function(plot, index = 1L, panel = 1L) {
  range_render(plot)$panels[[panel]]$layers[[index]]
}

test_that("geom_linerange_webgl serializes vertical ranges as pure segments", {
  df <- data.frame(
    x = 1:3,
    y = c(2, 3, 2.5),
    ymin = c(1, 2, 1.8),
    ymax = c(3, 4, 3.2)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
    geom_linerange_webgl(linewidth = 1)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- range_layer(plot)

  expect_equal(layer$type, "vectors")
  expect_equal(layer$geom, "GeomLinerangeWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$x, built$x)
  expect_equal(layer$y, built$ymin)
  expect_equal(layer$xend, built$x)
  expect_equal(layer$yend, built$ymax)
  expect_equal(layer$head_size, rep(0, nrow(built)))
})

test_that("geom_errorbar_webgl serializes vertical ranges and caps", {
  df <- data.frame(
    x = 1:2,
    y = c(2, 3),
    ymin = c(1, 2),
    ymax = c(3, 4)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
    geom_errorbar_webgl(width = 0.4)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- range_layer(plot)
  vertical <- seq_len(nrow(built))
  lower <- nrow(built) + seq_len(nrow(built))
  upper <- 2L * nrow(built) + seq_len(nrow(built))

  expect_equal(layer$type, "vectors")
  expect_equal(layer$geom, "GeomErrorbarWebGL")
  expect_equal(layer$rows, nrow(built) * 3L)
  expect_equal(layer$x[vertical], built$x)
  expect_equal(layer$y[vertical], built$ymin)
  expect_equal(layer$xend[vertical], built$x)
  expect_equal(layer$yend[vertical], built$ymax)
  expect_equal(layer$x[lower], built$xmin)
  expect_equal(layer$xend[lower], built$xmax)
  expect_equal(layer$y[lower], built$ymin)
  expect_equal(layer$yend[lower], built$ymin)
  expect_equal(layer$x[upper], built$xmin)
  expect_equal(layer$xend[upper], built$xmax)
  expect_equal(layer$y[upper], built$ymax)
  expect_equal(layer$yend[upper], built$ymax)
  expect_equal(layer$head_size, rep(0, nrow(built) * 3L))
})

test_that("geom_pointrange_webgl emits point and range payloads", {
  df <- data.frame(
    x = 1:3,
    y = c(2, 3, 2.5),
    ymin = c(1, 2, 1.8),
    ymax = c(3, 4, 3.2),
    group = c("a", "a", "b")
  )
  plot <- ggplot2::ggplot(
    df,
    ggplot2::aes(x, y, ymin = ymin, ymax = ymax, colour = group)
  ) +
    geom_pointrange_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  render <- range_render(plot)
  layers <- render$panels[[1L]]$layers
  point_layer <- layers[[1L]]
  range_layer <- layers[[2L]]

  expect_equal(vapply(layers, `[[`, character(1), "type"), c("points", "vectors"))
  expect_equal(point_layer$geom, "GeomPointrangeWebGL")
  expect_equal(range_layer$geom, "GeomPointrangeWebGL")
  expect_equal(point_layer$rows, nrow(built))
  expect_equal(range_layer$rows, nrow(built))
  expect_equal(point_layer$x, built$x)
  expect_equal(point_layer$y, built$y)
  expect_equal(range_layer$x, built$x)
  expect_equal(range_layer$y, built$ymin)
  expect_equal(range_layer$xend, built$x)
  expect_equal(range_layer$yend, built$ymax)
  expect_equal(range_layer$head_size, rep(0, nrow(built)))
  expect_equal(render$point_count, nrow(built))
  expect_equal(render$vector_count, nrow(built))
})

test_that("range geoms preserve grouped summary aesthetics", {
  df <- data.frame(
    group = c("a", "b", "c"),
    mean = c(2, 4, 3),
    lower = c(1, 3, 2.2),
    upper = c(3, 5, 3.8),
    alpha = c(0.4, 0.7, 1)
  )
  plot <- ggplot2::ggplot(
    df,
    ggplot2::aes(group, mean, ymin = lower, ymax = upper, colour = group, alpha = alpha)
  ) +
    geom_linerange_webgl(linewidth = 1.1)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- range_layer(plot)

  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$y, built$ymin)
  expect_equal(layer$yend, built$ymax)
  expect_equal(layer$rgba[seq(4, length(layer$rgba), by = 4)], built$alpha)
  expect_true(all(layer$width > 0))
})

test_that("range geoms split across fixed-scale facets", {
  df <- data.frame(
    x = rep(1:3, 2),
    y = c(2, 3, 2.5, 1.5, 2.5, 3.5),
    ymin = c(1, 2, 1.8, 0.8, 1.8, 2.8),
    ymax = c(3, 4, 3.2, 2.1, 3.1, 4.1),
    panel = rep(c("left", "right"), each = 3)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
    geom_pointrange_webgl() +
    ggplot2::facet_wrap(~panel)
  render <- range_render(plot)

  expect_equal(length(render$panels), 2L)
  expect_equal(sort(render$primitives), c("points", "vectors"))
  expect_equal(render$point_count, nrow(df))
  expect_equal(render$vector_count, nrow(df))
  expect_true(all(vapply(render$panels, function(panel) {
    identical(vapply(panel$layers, `[[`, character(1), "type"), c("points", "vectors")) &&
      panel$point_count == 3L &&
      panel$vector_count == 3L
  }, logical(1))))
})
