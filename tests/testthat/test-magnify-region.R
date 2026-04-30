test_that("ggwebgl_magnify_region builds a linked two-panel zoom spec", {
  source <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0, 1, 2, 3), y = c(0, 2, 1, 3)),
        x = "x",
        y = "y",
        colour = "#2563eb",
        alpha = 0.75,
        size = 4,
        panel_id = "source"
      )
    ),
    panels = list(
      list(
        panel_id = "source",
        row = 1L,
        col = 1L,
        viewport = list(x = c(0, 3), y = c(0, 3))
      )
    )
  )

  zoom <- ggwebgl_magnify_region(
    source,
    region = list(x = c(0.75, 2.25), y = c(0.50, 2.50)),
    display = "panel"
  )

  expect_s3_class(zoom, "ggwebgl_spec")
  expect_equal(zoom$render$grid, list(rows = 1L, cols = 2L))
  expect_equal(vapply(zoom$render$panels, `[[`, character(1), "panel_id"), c("global", "local"))
  expect_equal(zoom$render$panels[[2L]]$viewport, list(x = c(0.75, 2.25), y = c(0.50, 2.50)))

  global_layer_geoms <- vapply(zoom$render$panels[[1L]]$layers, function(layer) layer$geom %||% "", character(1))
  expect_true("ggwebgl_magnify_region_box" %in% global_layer_geoms)
})

test_that("ggwebgl_magnify_region can mark two-panel specs for live linked zoom", {
  source <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0, 1, 2, 3), y = c(0, 2, 1, 3)),
        x = "x",
        y = "y",
        panel_id = "source"
      )
    ),
    panels = list(
      list(
        panel_id = "source",
        row = 1L,
        col = 1L,
        viewport = list(x = c(0, 3), y = c(0, 3))
      )
    ),
    webgl = list(interactions = c("pan", "zoom"))
  )

  zoom <- ggwebgl_magnify_region(
    source,
    region = list(x = c(0.75, 2.25), y = c(0.50, 2.50)),
    display = "panel",
    interactive = TRUE
  )

  expect_true("brush" %in% zoom$webgl$interactions)
  expect_equal(zoom$render$links$magnifiers[[1L]]$source_panel, "global")
  expect_equal(zoom$render$links$magnifiers[[1L]]$target_panel, "local")
  expect_equal(zoom$render$links$magnifiers[[1L]]$region, list(x = c(0.75, 2.25), y = c(0.50, 2.50)))
  expect_error(
    ggwebgl_magnify_region(source, region = list(x = c(1, 2), y = c(1, 2)), display = "inset", interactive = TRUE),
    "display = \"panel\""
  )
})

test_that("magnifier regions normalize xmin/xmax and reject empty rectangles", {
  source <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(1, 2), y = c(1, 2)),
        x = "x",
        y = "y"
      )
    )
  )

  zoom <- ggwebgl_magnify_region(
    source,
    region = list(xmin = 2, xmax = 1, ymin = 3, ymax = 0),
    display = "panel"
  )

  expect_equal(zoom$render$panels[[2L]]$viewport, list(x = c(1, 2), y = c(0, 3)))
  expect_error(
    ggwebgl_magnify_region(source, region = list(x = c(1, 1), y = c(0, 1))),
    "positive width and height"
  )
})

test_that("ggwebgl_magnify_region builds publication insets before capture", {
  source <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0, 1, 2, 3), y = c(0, 2, 1, 3)),
        x = "x",
        y = "y",
        colour = "#0f766e",
        alpha = 0.8,
        size = 4
      )
    )
  )

  figure <- ggwebgl_magnify_region(
    source,
    region = list(x = c(0.5, 2.0), y = c(0.5, 2.5)),
    display = "inset",
    width = 640,
    height = 360,
    preset = "publication"
  )

  expect_s3_class(figure, "ggwebgl_publication_figure")
  spec <- ggwebgl_publication_figure_spec(figure)
  expect_equal(spec$inset$source$render$panels[[1L]]$viewport, list(x = c(0.5, 2.0), y = c(0.5, 2.5)))

  rendered <- htmltools::renderTags(figure)$html
  expect_match(rendered, "ggwebgl-publication-figure__inset")
  expect_match(rendered, "ggwebgl_magnify_region_box")
})
