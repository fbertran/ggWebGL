registry_layer_type <- function(plot) {
  ggplot_webgl(plot)$x$render$panels[[1L]]$layers[[1L]]
}

test_that("internal geom registry declares current primitive extractors", {
  registry <- ggwebgl_geom_registry()
  names <- vapply(registry, `[[`, character(1), "name")
  primitives <- vapply(registry, `[[`, character(1), "primitive")
  extractors <- vapply(registry, `[[`, character(1), "extractor")

  expect_equal(
    names,
    c("vectors", "mesh", "surface", "path3d", "points", "lines", "raster")
  )
  expect_equal(
    primitives,
    c("vectors", "mesh", "surface", "lines", "points", "lines", "raster")
  )
  expect_equal(
    extractors,
    c(
      "extract_vector_payloads",
      "extract_mesh_payloads",
      "extract_surface_payloads",
      "extract_line_payloads",
      "extract_point_payloads",
      "extract_line_payloads",
      "extract_raster_payloads"
    )
  )
  expect_equal(registry[[4L]]$subtype, "path3d")
})

test_that("geom registry preserves point, line, path3d, raster, vector, mesh, and surface serialization", {
  point <- registry_layer_type(
    ggplot2::ggplot(data.frame(x = 1:3, y = c(3, 1, 2)), ggplot2::aes(x, y)) +
      geom_point_webgl()
  )
  line <- registry_layer_type(
    ggplot2::ggplot(data.frame(x = 1:3, y = c(1, 3, 2)), ggplot2::aes(x, y)) +
      geom_line_webgl()
  )
  path3d <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = c(3, 1, 2), y = c(0, 1, 0.5), z = c(0, 0.4, 0.9)),
      ggplot2::aes(x, y, z = z)
    ) +
      geom_path3d_webgl()
  )
  raster <- registry_layer_type(
    ggplot2::ggplot(expand.grid(x = 1:2, y = 1:2), ggplot2::aes(x, y, fill = x + y)) +
      geom_raster_webgl()
  )
  vector <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 0, y = 0, xend = 1, yend = 1),
      ggplot2::aes(x, y, xend = xend, yend = yend)
    ) +
      geom_vector_webgl()
  )
  mesh <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(
        x = c(0, 1, 0),
        y = c(0, 0, 1),
        z = c(0, 0, 0),
        i = c(1L, 1L, 1L),
        j = c(2L, 2L, 2L),
        k = c(3L, 3L, 3L)
      ),
      ggplot2::aes(x, y, z = z, i = i, j = j, k = k)
    ) +
      geom_mesh_webgl()
  )
  surface_grid <- expand.grid(x = 1:2, y = 1:2)
  surface_grid$z <- with(surface_grid, x + y)
  surface <- registry_layer_type(
    ggplot2::ggplot(surface_grid, ggplot2::aes(x, y, z = z)) +
      geom_surface_webgl()
  )

  expect_equal(point$type, "points")
  expect_equal(line$type, "lines")
  expect_null(line$subtype)
  expect_equal(path3d$type, "lines")
  expect_equal(path3d$subtype, "path3d")
  expect_equal(path3d$paths[[1L]]$subtype, "path3d")
  expect_equal(raster$type, "raster")
  expect_equal(vector$type, "vectors")
  expect_equal(mesh$type, "mesh")
  expect_equal(surface$type, "surface")
})

test_that("unsupported geoms still fall back to unsupported metadata", {
  widget <- ggplot_webgl(
    ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
      ggplot2::geom_smooth(se = FALSE) +
      theme_webgl()
  )
  render <- widget$x$render

  expect_equal(render$mode, "metadata")
  expect_length(render$unsupported_layers, 1L)
  expect_equal(render$unsupported_layers[[1L]]$geom, "GeomSmooth")
  expect_true("messages" %in% names(render))
})
