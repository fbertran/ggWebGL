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
    c(
      "vectors", "segments", "linerange", "errorbar", "pointrange", "rects", "tiles", "bars", "bin2d", "ribbon", "area", "mesh", "surface",
      "path3d", "path", "freqpoly", "density", "points", "lines", "raster"
    )
  )
  expect_equal(
    primitives,
    c(
      "vectors", "vectors", "vectors", "vectors", "mixed", "rects", "rects", "rects", "rects", "ribbons", "ribbons", "mesh", "surface",
      "lines", "lines", "lines", "lines", "points", "lines", "raster"
    )
  )
  expect_equal(
    extractors,
    c(
      "extract_vector_payloads",
      "extract_vector_payloads",
      "extract_linerange_payloads",
      "extract_errorbar_payloads",
      "extract_pointrange_payloads",
      "extract_rect_payloads",
      "extract_rect_payloads",
      "extract_rect_payloads",
      "extract_rect_payloads",
      "extract_ribbon_payloads",
      "extract_ribbon_payloads",
      "extract_mesh_payloads",
      "extract_surface_payloads",
      "extract_line_payloads",
      "extract_line_payloads",
      "extract_line_payloads",
      "extract_line_payloads",
      "extract_point_payloads",
      "extract_line_payloads",
      "extract_raster_payloads"
    )
  )
  path3d_entry <- registry[[match("path3d", names)]]
  expect_equal(path3d_entry$subtype, "path3d")
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
  segment <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 0, y = 0, xend = 1, yend = 1),
      ggplot2::aes(x, y, xend = xend, yend = yend)
    ) +
      geom_segment_webgl()
  )
  linerange <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 1, y = 2, ymin = 1, ymax = 3),
      ggplot2::aes(x, y, ymin = ymin, ymax = ymax)
    ) +
      geom_linerange_webgl()
  )
  errorbar <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 1, y = 2, ymin = 1, ymax = 3),
      ggplot2::aes(x, y, ymin = ymin, ymax = ymax)
    ) +
      geom_errorbar_webgl(width = 0.2)
  )
  pointrange_widget <- ggplot_webgl(
    ggplot2::ggplot(
      data.frame(x = 1, y = 2, ymin = 1, ymax = 3),
      ggplot2::aes(x, y, ymin = ymin, ymax = ymax)
    ) +
      geom_pointrange_webgl()
  )
  pointrange_layers <- pointrange_widget$x$render$panels[[1L]]$layers
  rect <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(xmin = 0, xmax = 1, ymin = 0, ymax = 1),
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
    ) +
      geom_rect_webgl()
  )
  tile <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 1, y = 1),
      ggplot2::aes(x, y)
    ) +
      geom_tile_webgl()
  )
  bar <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = c("a", "a", "b")),
      ggplot2::aes(x)
    ) +
      geom_bar_webgl()
  )
  bin2d <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(
        x = c(0.1, 0.2, 0.7, 1.2, 1.8, 2.1),
        y = c(0.1, 0.5, 0.6, 1.1, 1.3, 1.8)
      ),
      ggplot2::aes(x, y)
    ) +
      geom_bin2d_webgl(binwidth = c(1, 1), boundary = c(0, 0))
  )
  ribbon <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 1:3, ymin = c(0, 0.2, 0.1), ymax = c(1, 0.9, 1.2)),
      ggplot2::aes(x, ymin = ymin, ymax = ymax)
    ) +
      geom_ribbon_webgl()
  )
  area <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = 1:3, y = c(1, 2, 1)),
      ggplot2::aes(x, y)
    ) +
      geom_area_webgl()
  )
  freqpoly <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = c(0.1, 0.2, 0.7, 1.2, 1.6, 2.1)),
      ggplot2::aes(x)
    ) +
      geom_freqpoly_webgl(binwidth = 0.5)
  )
  density <- registry_layer_type(
    ggplot2::ggplot(
      data.frame(x = seq(-2, 2, length.out = 40)),
      ggplot2::aes(x)
    ) +
      geom_density_webgl()
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
  expect_equal(segment$type, "vectors")
  expect_equal(segment$geom, "GeomSegmentWebGL")
  expect_equal(segment$head_size, 0)
  expect_equal(linerange$type, "vectors")
  expect_equal(linerange$geom, "GeomLinerangeWebGL")
  expect_equal(linerange$head_size, 0)
  expect_equal(errorbar$type, "vectors")
  expect_equal(errorbar$geom, "GeomErrorbarWebGL")
  expect_equal(errorbar$head_size, rep(0, 3))
  expect_equal(vapply(pointrange_layers, `[[`, character(1), "type"), c("points", "vectors"))
  expect_equal(vapply(pointrange_layers, `[[`, character(1), "geom"), rep("GeomPointrangeWebGL", 2))
  expect_equal(rect$type, "rects")
  expect_equal(rect$geom, "GeomRectWebGL")
  expect_equal(tile$type, "rects")
  expect_equal(tile$geom, "GeomTileWebGL")
  expect_equal(bar$type, "rects")
  expect_equal(bar$geom, "GeomBarWebGL")
  expect_equal(bin2d$type, "rects")
  expect_equal(bin2d$geom, "GeomBin2dWebGL")
  expect_equal(ribbon$type, "ribbons")
  expect_equal(ribbon$geom, "GeomRibbonWebGL")
  expect_equal(area$type, "ribbons")
  expect_equal(area$geom, "GeomAreaWebGL")
  expect_equal(freqpoly$type, "lines")
  expect_equal(freqpoly$geom, "GeomFreqpolyWebGL")
  expect_equal(density$type, "lines")
  expect_equal(density$geom, "GeomDensityWebGL")
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
