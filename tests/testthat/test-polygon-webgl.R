polygon_layer <- function(plot, panel = 1L) {
  ggplot_webgl(plot)$x$render$panels[[panel]]$layers[[1L]]
}

test_that("geom_polygon_webgl serializes one simple polygon as mesh triangles", {
  square <- data.frame(
    x = c(0, 1, 1, 0),
    y = c(0, 0, 1, 1)
  )
  plot <- ggplot2::ggplot(square, ggplot2::aes(x, y)) +
    geom_polygon_webgl(fill = "#38bdf8", alpha = 0.7)
  layer <- polygon_layer(plot)

  expect_equal(layer$type, "mesh")
  expect_equal(layer$geom, "GeomPolygonWebGL")
  expect_equal(layer$vertex_count, 4L)
  expect_equal(layer$triangle_count, 2L)
  expect_equal(length(layer$indices), 6L)
  expect_equal(layer$polygon_meta$triangulation, "ear_clipping")
  expect_true(isTRUE(layer$polygon_meta$simple))
})

test_that("geom_polygon_webgl serializes multiple grouped polygons", {
  polygons <- rbind(
    data.frame(group = "a", x = c(0, 1, 1, 0), y = c(0, 0, 1, 1), fill = "#ef4444"),
    data.frame(group = "b", x = c(2, 3, 3, 2), y = c(0, 0, 1, 1), fill = "#2563eb")
  )
  plot <- ggplot2::ggplot(polygons, ggplot2::aes(x, y, group = group, fill = fill)) +
    geom_polygon_webgl()
  layer <- polygon_layer(plot)

  expect_equal(layer$type, "mesh")
  expect_equal(layer$vertex_count, 8L)
  expect_equal(layer$triangle_count, 4L)
  expect_length(layer$polygon_meta$groups, 2L)
  expect_length(unique(matrix(layer$rgba, ncol = 4L, byrow = TRUE)[, 1L]), 2L)
  expect_equal(length(layer$pick_id), 4L)
})

test_that("geom_polygon_webgl preserves fill, outline metadata, and alpha", {
  triangle <- data.frame(
    x = c(0, 1, 0.2),
    y = c(0, 0.1, 1)
  )
  plot <- ggplot2::ggplot(triangle, ggplot2::aes(x, y)) +
    geom_polygon_webgl(fill = "#22c55e", colour = "#0f172a", alpha = 0.4, linewidth = 0.6)
  layer <- polygon_layer(plot)
  rgba <- matrix(layer$rgba, ncol = 4L, byrow = TRUE)

  expect_equal(layer$triangle_count, 1L)
  expect_equal(rgba[, 4L], rep(0.4, 3L))
  expect_true(isTRUE(layer$material$wireframe))
  expect_equal(layer$polygon_meta$outline[[1L]]$colour, "#0f172a")
  expect_gt(layer$polygon_meta$outline[[1L]]$linewidth, 0)
})

test_that("geom_polygon_webgl splits simple polygons across fixed-scale facets", {
  square <- data.frame(
    panel = rep(c("left", "right"), each = 4),
    x = c(0, 1, 1, 0, 0, 2, 2, 0),
    y = c(0, 0, 1, 1, 0, 0, 1, 1)
  )
  plot <- ggplot2::ggplot(square, ggplot2::aes(x, y)) +
    geom_polygon_webgl(fill = "#f59e0b") +
    ggplot2::facet_wrap(~panel)
  render <- ggplot_webgl(plot)$x$render

  expect_equal(length(render$panels), 2L)
  expect_equal(sort(render$primitives), "mesh")
  expect_equal(render$mesh_vertex_count, 8L)
  expect_equal(render$mesh_triangle_count, 4L)
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$layers[[1L]]$geom, "GeomPolygonWebGL") &&
      panel$mesh_vertex_count == 4L &&
      panel$mesh_triangle_count == 2L
  }, logical(1))))
})

test_that("geom_polygon_webgl fails clearly for unsupported complex polygons", {
  bowtie <- data.frame(
    x = c(0, 1, 0, 1),
    y = c(0, 1, 1, 0)
  )
  expect_error(
    ggplot_webgl(
      ggplot2::ggplot(bowtie, ggplot2::aes(x, y)) +
        geom_polygon_webgl()
    ),
    "self-intersecting"
  )

  holed <- data.frame(
    x = c(0, 2, 2, 0, 0.5, 1.5, 1.5, 0.5),
    y = c(0, 0, 2, 2, 0.5, 0.5, 1.5, 1.5),
    group = 1,
    subgroup = rep(c("outer", "inner"), each = 4)
  )
  expect_error(
    ggplot_webgl(
      ggplot2::ggplot(holed, ggplot2::aes(x, y, group = group, subgroup = subgroup)) +
        geom_polygon_webgl()
    ),
    "holes or multiple rings"
  )
})
