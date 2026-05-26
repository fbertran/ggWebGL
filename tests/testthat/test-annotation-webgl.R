annotation_layer <- function(plot, panel = 1L, layer = 1L) {
  ggplot_webgl(plot)$x$render$panels[[panel]]$layers[[layer]]
}

test_that("geom_text_webgl serializes static text overlay metadata", {
  labels <- data.frame(
    x = c(1, 2),
    y = c(2, 1),
    label = c("alpha", "beta")
  )
  plot <- ggplot2::ggplot(labels, ggplot2::aes(x, y, label = label)) +
    geom_text_webgl(colour = "#0f172a", alpha = 0.8, size = 3.5, angle = 25, hjust = 0.1, vjust = 0.9)
  layer <- annotation_layer(plot)

  expect_equal(layer$type, "text")
  expect_equal(layer$geom, "GeomTextWebGL")
  expect_true(isTRUE(layer$overlay))
  expect_equal(layer$label, labels$label)
  expect_equal(layer$angle, rep(25, 2))
  expect_equal(layer$hjust, rep(0.1, 2))
  expect_equal(layer$vjust, rep(0.9, 2))
  expect_equal(matrix(layer$rgba, ncol = 4L, byrow = TRUE)[, 4L], rep(0.8, 2))
})

test_that("geom_label_webgl serializes background-box metadata", {
  labels <- data.frame(x = 1, y = 1, label = "boxed")
  plot <- ggplot2::ggplot(labels, ggplot2::aes(x, y, label = label)) +
    geom_label_webgl(fill = "#fef3c7", colour = "#92400e", alpha = 0.9, linewidth = 0.4)
  layer <- annotation_layer(plot)

  expect_equal(layer$type, "text")
  expect_equal(layer$geom, "GeomLabelWebGL")
  expect_equal(layer$label, "boxed")
  expect_false(is.null(layer$label_box))
  expect_true(isTRUE(layer$label_box$metadata_only))
  expect_equal(length(layer$label_box$fill_rgba), 4L)
  expect_gt(layer$label_box$linewidth, 0)
})

test_that("geom_text_webgl splits overlay metadata across fixed-scale facets", {
  labels <- data.frame(
    panel = c("left", "right"),
    x = c(1, 2),
    y = c(2, 1),
    label = c("L", "R")
  )
  plot <- ggplot2::ggplot(labels, ggplot2::aes(x, y, label = label)) +
    geom_text_webgl() +
    ggplot2::facet_wrap(~panel)
  render <- ggplot_webgl(plot)$x$render

  expect_equal(length(render$panels), 2L)
  expect_equal(render$text_count, 2L)
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$layers[[1L]]$type, "text") &&
      panel$text_count == 1L
  }, logical(1))))
})

test_that("geom_rug_webgl serializes requested sides as pure segments", {
  data <- data.frame(x = c(1, 2, 3), y = c(2, 1, 3))
  plot <- ggplot2::ggplot(data, ggplot2::aes(x, y)) +
    geom_rug_webgl(sides = "tr", linewidth = 0.5)
  layer <- annotation_layer(plot)

  expect_equal(layer$type, "vectors")
  expect_equal(layer$geom, "GeomRugWebGL")
  expect_equal(layer$rows, nrow(data) * 2L)
  expect_equal(layer$head_size, rep(0, layer$rows))
  expect_equal(sum(layer$x == layer$xend), nrow(data))
  expect_equal(sum(layer$y == layer$yend), nrow(data))
})

test_that("geom_rug_webgl preserves mapped colour metadata", {
  data <- data.frame(
    x = c(1, 2, 3, 4),
    y = c(2, 1, 3, 2),
    group = c("a", "b", "a", "b")
  )
  plot <- ggplot2::ggplot(data, ggplot2::aes(x, y, colour = group)) +
    geom_rug_webgl(sides = "b")
  layer <- annotation_layer(plot)
  rgba <- matrix(layer$rgba, ncol = 4L, byrow = TRUE)

  expect_equal(layer$rows, nrow(data))
  expect_gt(length(unique(rgba[, 1L])), 1L)
})
