test_that("ggWebGL accepts renderer-ready primitive adapter payloads", {
  payload <- list(
    labels = list(
      title = "Adapter payload",
      x = "dimension 1",
      y = "dimension 2"
    ),
    webgl = list(
      shader = "default",
      antialias = TRUE,
      transparent = TRUE,
      buffer_size = 65536L,
      interactions = c("pan", "zoom", "hover"),
      rendering = "visualization",
      panel_overlay = "auto",
      line_mode = "auto",
      line_join = "bevel",
      line_cap = "round",
      extra = list()
    ),
    layer_count = 1L,
    layers = list(
      list(type = "points", rows = 3L)
    ),
    render = list(
      mode = "webgl",
      grid = list(rows = 1L, cols = 1L),
      panels = list(
        list(
          panel_id = 1L,
          row = 1L,
          col = 1L,
          label = NULL,
          bounds = list(left = 0, right = 1, top = 0, bottom = 1),
          viewport = list(x = c(0, 1), y = c(0, 1)),
          primitives = "points",
          point_count = 3L,
          line_vertex_count = 0L,
          path_count = 0L,
          raster_cell_count = 0L,
          layers = list(
            list(
              type = "points",
              rows = 3L,
              x = c(0.1, 0.5, 0.9),
              y = c(0.2, 0.8, 0.4),
              size = c(4, 4, 4),
              age = c(1, 1, 1),
              rgba = c(
                0.10, 0.35, 0.70, 0.85,
                0.90, 0.30, 0.18, 0.85,
                0.20, 0.62, 0.35, 0.85
              )
            )
          )
        )
      ),
      primitives = "points",
      point_count = 3L,
      line_vertex_count = 0L,
      path_count = 0L,
      raster_cell_count = 0L,
      unsupported_layers = list(),
      messages = character()
    )
  )

  widget <- ggWebGL(payload)

  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$x[["render"]][["panels"]][[1]][["layers"]][[1]][["type"]], "points")
  expect_equal(widget$x[["webgl"]][["rendering"]], "visualization")
  expect_equal(widget$x[["webgl"]][["panel_overlay"]], "auto")
  expect_false(any(grepl("xgeo|shapley|explanation", names(widget$x), ignore.case = TRUE)))
})

test_that("ggwebgl_spec preserves publication-mode renderer options", {
  spec <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0.2, 0.8), y = c(0.3, 0.7)),
        x = "x",
        y = "y",
        colour = "#2563eb",
        size = 4
      )
    ),
    webgl = list(rendering = "publication", panel_overlay = "show")
  )

  expect_equal(spec[["webgl"]][["rendering"]], "publication")
  expect_equal(spec[["webgl"]][["panel_overlay"]], "show")
  expect_equal(spec[["webgl"]][["interactions"]], character())
  expect_false(spec[["webgl"]][["transparent"]])
})

test_that("ggWebGL keeps suggested integrations out of hard dependencies", {
  description_path <- testthat::test_path("..", "..", "DESCRIPTION")

  if (!file.exists(description_path)) {
    description_path <- system.file("DESCRIPTION", package = "ggWebGL")
  }

  expect_true(file.exists(description_path))

  description <- read.dcf(description_path)
  hard_dependency_fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(description))
  hard_dependencies <- paste(description[, hard_dependency_fields, drop = TRUE], collapse = "\n")
  suggests <- if ("Suggests" %in% colnames(description)) description[, "Suggests"] else ""

  for (pkg in c("XGeoRTR", "boids4R", "shapViz3D")) {
    expect_false(grepl(pkg, hard_dependencies, fixed = TRUE), info = pkg)
  }
  expect_true(grepl("XGeoRTR", suggests, fixed = TRUE))
  expect_true(grepl("boids4R", suggests, fixed = TRUE))
  expect_false(grepl("shapViz3D", suggests, fixed = TRUE))
})
