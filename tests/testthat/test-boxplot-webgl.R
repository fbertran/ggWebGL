boxplot_render <- function(plot) {
  ggplot_webgl(plot)$x$render
}

boxplot_layers <- function(plot, panel = 1L) {
  boxplot_render(plot)$panels[[panel]]$layers
}

test_that("geom_boxplot_webgl serializes box body, median, and whiskers", {
  df <- data.frame(
    group = rep(c("a", "b"), each = 6),
    value = c(1:6, 2:7)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(group, value)) +
    geom_boxplot_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layers <- boxplot_layers(plot)
  body <- layers[[1L]]
  segments <- layers[[2L]]
  n <- nrow(built)
  lower <- seq_len(n)
  upper <- n + seq_len(n)
  median <- 2L * n + seq_len(n)

  expect_equal(vapply(layers, `[[`, character(1), "type"), c("rects", "vectors"))
  expect_equal(body$geom, "GeomBoxplotWebGL")
  expect_equal(segments$geom, "GeomBoxplotWebGL")
  expect_equal(body$rows, n)
  expect_equal(body$xmin, built$xmin)
  expect_equal(body$xmax, built$xmax)
  expect_equal(body$ymin, built$lower)
  expect_equal(body$ymax, built$upper)
  expect_equal(segments$rows, n * 3L)
  expect_equal(segments$x[lower], built$x)
  expect_equal(segments$y[lower], built$ymin)
  expect_equal(segments$yend[lower], built$lower)
  expect_equal(segments$x[upper], built$x)
  expect_equal(segments$y[upper], built$upper)
  expect_equal(segments$yend[upper], built$ymax)
  expect_equal(segments$x[median], built$xmin)
  expect_equal(segments$xend[median], built$xmax)
  expect_equal(segments$y[median], built$middle)
  expect_equal(segments$yend[median], built$middle)
  expect_equal(segments$head_size, rep(0, n * 3L))
})

test_that("geom_boxplot_webgl preserves grouped fill and colour payloads", {
  df <- data.frame(
    group = rep(c("a", "b", "c"), each = 6),
    value = c(1:6, 2:7, c(1, 2, 2, 3, 5, 8))
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group, colour = group)) +
    geom_boxplot_webgl(alpha = 0.65, linewidth = 0.8)
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layers <- boxplot_layers(plot)
  body <- layers[[1L]]
  segments <- layers[[2L]]

  expect_equal(body$rows, nrow(built))
  expect_equal(body$rgba[seq(4, length(body$rgba), by = 4)], rep(0.65, nrow(built)))
  expect_length(unique(matrix(body$rgba, ncol = 4, byrow = TRUE)[, 1]), 3L)
  expect_equal(segments$rows, nrow(built) * 3L)
  expect_true(all(segments$width > 0))
  expect_length(unique(matrix(segments$rgba, ncol = 4, byrow = TRUE)[, 1]), 3L)
})

test_that("geom_boxplot_webgl serializes built outliers as points", {
  df <- data.frame(
    group = rep(c("a", "b"), each = 8),
    value = c(1:7, 20, 2:9)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group, colour = group)) +
    geom_boxplot_webgl()
  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layers <- boxplot_layers(plot)
  outlier_layer <- layers[[3L]]
  outlier_values <- unlist(built$outliers, use.names = FALSE)
  outlier_x <- rep(built$x, lengths(built$outliers))

  expect_equal(vapply(layers, `[[`, character(1), "type"), c("rects", "vectors", "points"))
  expect_equal(outlier_layer$geom, "GeomBoxplotWebGL")
  expect_equal(outlier_layer$rows, length(outlier_values))
  expect_equal(outlier_layer$x, outlier_x)
  expect_equal(outlier_layer$y, as.numeric(outlier_values))

  no_outlier_layers <- boxplot_layers(
    ggplot2::ggplot(df, ggplot2::aes(group, value)) +
      geom_boxplot_webgl(outliers = FALSE)
  )
  expect_equal(vapply(no_outlier_layers, `[[`, character(1), "type"), c("rects", "vectors"))
})

test_that("geom_boxplot_webgl splits mixed payloads across fixed-scale facets", {
  df <- data.frame(
    panel = rep(c("left", "right"), each = 12),
    group = rep(rep(c("a", "b"), each = 6), 2),
    value = c(1:6, 2:7, 3:8, 4:9)
  )
  plot <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group)) +
    geom_boxplot_webgl() +
    ggplot2::facet_wrap(~panel)
  render <- boxplot_render(plot)

  expect_equal(length(render$panels), 2L)
  expect_equal(sort(render$primitives), c("rects", "vectors"))
  expect_equal(render$rect_count, 4L)
  expect_equal(render$vector_count, 12L)
  expect_true(all(vapply(render$panels, function(panel) {
    identical(vapply(panel$layers, `[[`, character(1), "type"), c("rects", "vectors")) &&
      panel$rect_count == 2L &&
      panel$vector_count == 6L
  }, logical(1))))
})
