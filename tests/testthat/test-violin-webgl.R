violin_layer <- function(plot, panel = 1L) {
  ggplot_webgl(plot)$x$render$panels[[panel]]$layers[[1L]]
}

deterministic_violin_data <- function() {
  data.frame(
    group = rep(c("a", "b"), each = 32),
    value = c(
      seq(-1, 1, length.out = 32),
      seq(-0.25, 1.75, length.out = 32)
    )
  )
}

test_that("geom_violin_webgl serializes one stat_ydensity violin as a mesh strip", {
  data <- data.frame(group = "a", value = seq(-1, 1, length.out = 32))
  plot <- ggplot2::ggplot(data, ggplot2::aes(group, value)) +
    geom_violin_webgl(fill = "#38bdf8", alpha = 0.6)
  layer <- violin_layer(plot)

  expect_equal(layer$type, "mesh")
  expect_equal(layer$geom, "GeomViolinWebGL")
  expect_equal(layer$violin_meta$built_stat, "ydensity")
  expect_equal(layer$violin_meta$triangulation, "strip")
  expect_gt(layer$vertex_count, 0L)
  expect_gt(layer$triangle_count, 0L)
  expect_equal(length(layer$indices), layer$triangle_count * 3L)
  expect_equal(matrix(layer$rgba, ncol = 4L, byrow = TRUE)[, 4L], rep(0.6, layer$vertex_count))
})

test_that("geom_violin_webgl keeps grouped violins separated", {
  data <- deterministic_violin_data()
  plot <- ggplot2::ggplot(data, ggplot2::aes(group, value, fill = group)) +
    geom_violin_webgl(alpha = 0.75)
  layer <- violin_layer(plot)
  rgba <- matrix(layer$rgba, ncol = 4L, byrow = TRUE)

  expect_equal(layer$type, "mesh")
  expect_length(layer$violin_meta$groups, 2L)
  expect_gt(length(unique(layer$id)), 1L)
  expect_gt(length(unique(rgba[, 1L])), 1L)
  expect_equal(unique(rgba[, 4L]), 0.75)
  expect_equal(length(unique(layer$pick_id)), 2L)
})

test_that("geom_violin_webgl serializes flipped orientation from ggplot2-built data", {
  data <- deterministic_violin_data()
  plot <- ggplot2::ggplot(data, ggplot2::aes(value, group, fill = group)) +
    geom_violin_webgl(orientation = "y")
  layer <- violin_layer(plot)

  expect_equal(layer$type, "mesh")
  expect_equal(layer$geom, "GeomViolinWebGL")
  expect_true(isTRUE(layer$violin_meta$flipped))
  expect_gt(diff(range(layer$x)), 0)
  expect_gt(diff(range(layer$y)), 0)
})

test_that("geom_violin_webgl splits grouped violins across fixed-scale facets", {
  data <- deterministic_violin_data()
  data$panel <- rep(c("left", "right"), each = nrow(data) / 2L)
  plot <- ggplot2::ggplot(data, ggplot2::aes(group, value, fill = group)) +
    geom_violin_webgl() +
    ggplot2::facet_wrap(~panel)
  render <- ggplot_webgl(plot)$x$render

  expect_equal(length(render$panels), 2L)
  expect_equal(sort(render$primitives), "mesh")
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$layers[[1L]]$geom, "GeomViolinWebGL") &&
      identical(panel$layers[[1L]]$type, "mesh") &&
      panel$layers[[1L]]$triangle_count > 0L
  }, logical(1))))
})
