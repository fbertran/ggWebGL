test_that("surface_matrix validates regular numeric grids", {
  expect_error(surface_matrix(matrix(numeric(), nrow = 0L)), "at least two rows")
  expect_error(surface_matrix(matrix(c(1, NA, 2, 3), nrow = 2L)), "finite")
  expect_error(surface_matrix(matrix(1:4, nrow = 2L), x = 1), "match")
  expect_error(surface_matrix(matrix(1:4, nrow = 2L), x = c(1, 1)), "unique")

  surface <- surface_matrix(matrix(1:9, nrow = 3L), x = c(-1, 0, 1), y = c(10, 20, 30))
  expect_s3_class(surface, "ggwebgl_surface_matrix")
  expect_equal(surface$nrow, 3L)
  expect_equal(surface$ncol, 3L)
  expect_equal(surface$x, c(-1, 0, 1))
  expect_equal(surface$y, c(10, 20, 30))
})

test_that("structured surface helper emits first-class surface payloads", {
  layer <- ggwebgl_layer_surface(
    surface_matrix(matrix(seq_len(9), nrow = 3L)),
    shading = "surface_height_colormap",
    wireframe = TRUE,
    contours = TRUE,
    contour_levels = 5
  )

  expect_equal(layer$type, "surface")
  expect_equal(layer$vertex_count, 9L)
  expect_equal(layer$triangle_count, 8L)
  expect_length(layer$positions, 27L)
  expect_length(layer$normals, 27L)
  expect_length(layer$colors, 36L)
  expect_length(layer$indices, 24L)
  expect_true(all(layer$indices >= 0L))
  expect_equal(layer$surface_meta$shading, "surface_height_colormap")
  expect_equal(layer$surface_meta$triangulation, "regular_grid")
  expect_true(layer$wireframe)
  expect_false(is.null(layer$wire_indices))
  expect_false(is.null(layer$contours))
})

test_that("structured surface normals are finite and oriented upward on a flat grid", {
  layer <- ggwebgl_layer_surface(matrix(0, nrow = 3L, ncol = 3L))
  normals <- matrix(layer$normals, ncol = 3L, byrow = TRUE)

  expect_true(all(is.finite(normals)))
  expect_equal(normals[, 1L], rep(0, 9), tolerance = 1e-8)
  expect_equal(normals[, 2L], rep(0, 9), tolerance = 1e-8)
  expect_true(all(normals[, 3L] > 0))
})

test_that("regular triples reject missing cells and serialize as surface primitives", {
  missing_cell <- expand.grid(x = 1:3, y = 1:3)
  missing_cell$z <- with(missing_cell, x + y)
  missing_cell <- missing_cell[-2L, ]

  expect_error(
    ggplot_webgl(
      ggplot2::ggplot(missing_cell, ggplot2::aes(x, y, z = z)) +
        geom_surface_webgl()
    ),
    "complete regular"
  )

  complete_grid <- expand.grid(x = 1:3, y = 1:3)
  complete_grid$z <- with(complete_grid, x + y)
  widget <- ggplot_webgl(
    ggplot2::ggplot(complete_grid, ggplot2::aes(x, y, z = z, fill = z)) +
      geom_surface_webgl(shading = "surface_flat", wireframe = TRUE) +
      coord_webgl_3d()
  )

  expect_equal(widget$x$render$coordinate_system, "cartesian3d")
  expect_true("surface" %in% widget$x$render$primitives)
  expect_equal(widget$x$render$surface_vertex_count, 9L)
  expect_equal(widget$x$render$surface_triangle_count, 8L)
  expect_equal(widget$x$render$panels[[1L]]$layers[[1L]]$type, "surface")
})

test_that("surface shading modes serialize exactly and reject unknown values", {
  expect_equal(ggwebgl_layer_surface(matrix(1:4, nrow = 2L), shading = "surface_flat")$surface_meta$shading, "surface_flat")
  expect_equal(ggwebgl_layer_surface(matrix(1:4, nrow = 2L), shading = "lambert")$surface_meta$shading, "surface_lambert")
  expect_error(ggwebgl_layer_surface(matrix(1:4, nrow = 2L), shading = "unsupported"), "arg")
})

test_that("widget source has a dedicated indexed surface draw path", {
  js <- readLines(testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js"), warn = FALSE)
  js <- paste(js, collapse = "\n")

  expect_match(js, "function drawSurfaceLayer", fixed = TRUE)
  expect_match(js, "function createSurfaceLayerGpuPayload", fixed = TRUE)
  expect_match(js, "gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER", fixed = TRUE)
  expect_match(js, "gl.drawElements(gl.TRIANGLES", fixed = TRUE)
  expect_match(js, "surface_lambert", fixed = TRUE)
  expect_match(js, "surface_height_colormap", fixed = TRUE)
  expect_match(js, "surface_uncertainty_alpha", fixed = TRUE)
  expect_match(js, "wire_indices", fixed = TRUE)
  expect_match(js, "contours", fixed = TRUE)
  expect_false(grepl("lowered_type === \"mesh\"", js, fixed = TRUE))
})
