locate_schema_v2_file <- function(path, required = TRUE) {
  candidates <- c(
    file.path(getwd(), path),
    file.path(testthat::test_path(), "..", "..", path),
    system.file(sub("^inst/", "", path), package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    if (!isTRUE(required)) {
      return(NA_character_)
    }
    skip(sprintf("%s is unavailable in this test context.", path))
  }

  found[[1L]]
}

read_schema_v2_text <- function(path, required = TRUE) {
  located <- locate_schema_v2_file(path, required = required)
  if (is.na(located)) {
    return("")
  }

  paste(readLines(located, warn = FALSE), collapse = "\n")
}

schema_v2_coordinate_system <- function(render) {
  if (!is.null(render[["coordinate_system"]])) {
    return(render[["coordinate_system"]])
  }

  if (identical(render[["dimension"]], "3d")) {
    "cartesian3d"
  } else {
    "cartesian2d"
  }
}

test_that("render schema v2 documents the required contract boundaries", {
  schema <- read_schema_v2_text("inst/specs/render-schema-v2.md")
  api <- read_schema_v2_text("inst/specs/user-api-v2.md")
  contract <- read_schema_v2_text("internal/RENDERER_CONTRACT.md", required = FALSE)

  if (nzchar(contract)) {
    expect_match(contract, "inst/specs/render-schema-v2.md", fixed = TRUE)
    expect_match(contract, "inst/specs/user-api-v2.md", fixed = TRUE)
  }
  expect_match(schema, "coordinate_system", fixed = TRUE)
  expect_match(schema, "cartesian2d", fixed = TRUE)
  expect_match(schema, "cartesian3d", fixed = TRUE)
  expect_match(schema, "messages", fixed = TRUE)
  expect_match(schema, "legends", fixed = TRUE)
  expect_match(api, "ggWebGL.gpu", fixed = TRUE)
  expect_match(api, "Native GPU", fixed = TRUE)

  for (primitive in c("points", "lines", "raster", "vectors", "mesh", "surface", "path3d")) {
    expect_match(schema, primitive, fixed = TRUE)
  }

  forbidden <- c("SIGGRAPH", "poster", "submission")
  expect_false(any(vapply(forbidden, grepl, logical(1), x = schema, fixed = TRUE)))
  expect_false(any(vapply(forbidden, grepl, logical(1), x = api, fixed = TRUE)))
})

test_that("current ggwebgl_spec payloads satisfy the v2 top-level shape", {
  point_layer <- ggwebgl_layer_points(
    data.frame(x = c(0, 1), y = c(1, 0), z = c(0.2, 0.8), id = c("p1", "p2"), frame = 1:2),
    x = "x",
    y = "y",
    z = "z",
    id = "id",
    frame = "frame",
    panel_id = "main"
  )
  path3d_layer <- ggwebgl_layer_lines(
    data.frame(x = c(0, 0.5, 1), y = c(0, 0.4, 0.2), z = c(0, 0.3, 0.6), group = "path", frame = 1:3),
    x = "x",
    y = "y",
    z = "z",
    group = "group",
    frame = "frame",
    panel_id = "main"
  )
  raster_layer <- ggwebgl_layer_raster(
    rgba = rep(c(20L, 80L, 140L, 255L), 4L),
    width = 2L,
    height = 2L,
    xmin = -0.5,
    xmax = 1.5,
    ymin = -0.5,
    ymax = 1.5,
    panel_id = "main"
  )
  vector_layer <- ggwebgl_layer_vectors(
    data.frame(x = 0.2, y = 0.2, z = 0.1, xend = 0.9, yend = 0.8, zend = 0.6, id = "v1"),
    x = "x",
    y = "y",
    z = "z",
    xend = "xend",
    yend = "yend",
    zend = "zend",
    id = "id",
    panel_id = "main"
  )
  surface_layer <- ggwebgl_layer_surface(
    matrix(c(0, 0.2, 0.4, 0.1), nrow = 2L),
    panel_id = "main",
    material = ggwebgl_material(shading = "lambert", wireframe = TRUE)
  )

  spec <- ggwebgl_spec(
    layers = list(point_layer, path3d_layer, raster_layer, vector_layer, surface_layer),
    labels = list(title = "schema fixture"),
    webgl = list(
      view = ggwebgl_view(dimension = "3d", projection = "perspective", controller = "orbit"),
      selection = ggwebgl_selection("brush_lasso")
    ),
    timeline = ggwebgl_timeline(frames = 1:3, filter = "exact", autoplay = FALSE),
    messages = "schema fixture message"
  )

  expect_true(all(c("labels", "webgl", "layer_count", "layers", "render") %in% names(spec)))
  expect_equal(spec[["scene_version"]], 2L)
  expect_equal(spec[["layer_count"]], 5L)
  expect_equal(spec[["labels"]][["title"]], "schema fixture")
  expect_equal(spec[["render"]][["mode"]], "webgl")
  expect_equal(spec[["render"]][["messages"]], "schema fixture message")
  expect_equal(schema_v2_coordinate_system(spec[["render"]]), "cartesian3d")
  expect_equal(spec[["render"]][["coordinate_system"]], "cartesian3d")
  expect_equal(spec[["render"]][["dimension"]], "3d")
  expect_equal(spec[["render"]][["selection"]][["mode"]], "brush_lasso")
  expect_equal(spec[["render"]][["timeline"]][["filter"]], "exact")
  expect_setequal(spec[["render"]][["primitives"]], c("points", "lines", "raster", "vectors", "mesh"))
})

test_that("ggplot_webgl payloads include scene_version and validate typed panels", {
  widget <- ggplot_webgl(
    ggplot2::ggplot(
      data.frame(x = c(0, 1), y = c(1, 0)),
      ggplot2::aes(x, y)
    ) +
      geom_point_webgl() +
      theme_webgl(interactions = character())
  )

  expect_equal(widget$x[["scene_version"]], 2L)
  expect_equal(widget$x[["render"]][["coordinate_system"]], "cartesian2d")

  invalid <- structure(
    list(
      scene_version = 2L,
      render = list(
        mode = "webgl",
        panels = list(list(row = 1L, col = 1L, layers = list()))
      )
    ),
    class = c("ggwebgl_spec", "list")
  )

  expect_error(ggWebGL(invalid), "panel_id")
})

test_that("v2 aliases map to current line and surface payloads without new runtime primitives", {
  path3d_layer <- ggwebgl_layer_lines(
    data.frame(x = c(0, 1), y = c(0, 1), z = c(0.1, 0.9), group = "a"),
    x = "x",
    y = "y",
    z = "z",
    group = "group"
  )
  surface_layer <- ggwebgl_layer_surface(matrix(seq_len(9), nrow = 3L))

  expect_equal(path3d_layer[["type"]], "lines")
  expect_false(is.null(path3d_layer[["paths"]][[1]][["z"]]))
  expect_equal(surface_layer[["type"]], "mesh")
  expect_equal(surface_layer[["geom"]], "adapter_surface")
  expect_true(surface_layer[["triangle_count"]] > 0L)
  expect_false(is.null(surface_layer[["normal"]]))
})

test_that("single-panel compatibility fields remain derived from render panels", {
  spec <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0, 1), y = c(1, 0)),
        x = "x",
        y = "y"
      )
    )
  )
  render <- spec[["render"]]

  expect_length(render[["panels"]], 1L)
  expect_identical(render[["layers"]], render[["panels"]][[1]][["layers"]])
  expect_identical(render[["viewport"]], render[["panels"]][[1]][["viewport"]])
  expect_identical(render[["panel"]], render[["panels"]][[1]][["panel_id"]])
})

test_that("htmlwidget dependencies register typed scene modules before the widget", {
  yaml <- read_schema_v2_text("inst/htmlwidgets/ggWebGL.yaml")
  expected <- c(
    "lib/scene.js",
    "lib/camera.js",
    "lib/program-registry.js",
    "lib/picking.js"
  )

  for (script in expected) {
    expect_match(yaml, script, fixed = TRUE)
    expect_true(file.exists(locate_schema_v2_file(file.path("inst/htmlwidgets", script))))
  }

  positions <- vapply(expected, function(script) regexpr(script, yaml, fixed = TRUE)[[1L]], integer(1))
  expect_true(all(diff(positions) > 0L))
})

test_that("widget source routes drawing through a typed layer dispatcher", {
  js <- read_schema_v2_text("inst/htmlwidgets/ggWebGL.js")

  expect_match(js, "function drawLayer", fixed = TRUE)
  expect_match(js, "drawLayer(gl, programs, layer, x, panel, viewport, box)", fixed = TRUE)
  expect_match(js, "function drawPointsLayer", fixed = TRUE)
  expect_match(js, "function drawLinesLayer", fixed = TRUE)
  expect_match(js, "function drawRasterLayer", fixed = TRUE)
  expect_match(js, "function drawVectorsLayer", fixed = TRUE)
  expect_match(js, "function drawMeshLayer", fixed = TRUE)
  expect_match(js, "function drawSurfaceLayer", fixed = TRUE)
  expect_match(js, "function getProgramForLayer", fixed = TRUE)
  expect_match(js, "ggWebGLScene.finalizeScene", fixed = TRUE)

  scene_lib <- read_schema_v2_text("inst/htmlwidgets/lib/scene.js")
  program_lib <- read_schema_v2_text("inst/htmlwidgets/lib/program-registry.js")
  expect_match(scene_lib, "Scene.VERSION = 2", fixed = TRUE)
  expect_match(scene_lib, "Scene.finalizeScene", fixed = TRUE)
  expect_match(program_lib, "getProgramForLayer", fixed = TRUE)
})
