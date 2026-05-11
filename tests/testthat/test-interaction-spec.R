test_that("structured interaction specs normalize through themes and specs", {
  interaction <- ggwebgl_interactions(brush = TRUE, lasso = TRUE)

  expect_s3_class(interaction, "ggwebgl_interactions")
  expect_true(interaction$hover)
  expect_true(interaction$click)
  expect_true(interaction$brush)
  expect_true(interaction$lasso)
  expect_true(interaction$camera)
  expect_true(interaction$shiny)
  expect_true(all(c("hover", "click", "brush", "lasso", "camera") %in% interaction$modes))

  theme <- theme_webgl(interactions_spec = interaction)
  expect_true(all(c("pan", "zoom", "hover", "click", "brush", "lasso", "camera") %in% theme$interactions))
  expect_equal(theme$selection$mode, "brush_lasso")
  expect_true(theme$interactions_spec$click)
  expect_true(theme$interactions_spec$brush)

  points <- ggwebgl_layer_points(
    data.frame(x = c(0, 1), y = c(0, 1), id = c("a", "b")),
    x = "x",
    y = "y",
    id = "id"
  )
  spec <- ggwebgl_spec(
    list(points),
    webgl = list(interactions_spec = ggwebgl_interactions(brush = TRUE))
  )

  expect_true(spec$render$interactions$hover)
  expect_true(spec$render$interactions$click)
  expect_true(spec$render$interactions$brush)
  expect_false(spec$render$interactions$lasso)
  expect_equal(spec$render$selection$mode, "brush")
  expect_false(is.null(spec$render$interactions))
  expect_false(is.null(spec$render$selection))
})

test_that("legacy interactions and selection still map to structured interactions", {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    geom_point_webgl() +
    theme_webgl(interactions = c("pan", "hover"), selection = ggwebgl_selection("brush"))

  expect_equal(plot$ggwebgl$selection$mode, "brush")
  expect_true("brush" %in% plot$ggwebgl$interactions)
  expect_true(plot$ggwebgl$interactions_spec$hover)
  expect_true(plot$ggwebgl$interactions_spec$brush)
  expect_false(plot$ggwebgl$interactions_spec$lasso)
})

test_that("widget source exposes the Milestone 6 Shiny event contract", {
  js_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js")
  yaml_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.yaml")
  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }
  if (!file.exists(yaml_path)) {
    yaml_path <- system.file("htmlwidgets", "ggWebGL.yaml", package = "ggWebGL")
  }
  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  yaml <- paste(readLines(yaml_path, warn = FALSE), collapse = "\n")

  interaction_modules <- c(
    "lib/interactions/hover.js",
    "lib/interactions/brush.js",
    "lib/interactions/lasso.js",
    "lib/interactions/select.js",
    "lib/interactions/raycast.js"
  )
  for (module in interaction_modules) {
    expect_match(yaml, module, fixed = TRUE)
  }
  expect_lt(
    regexpr("lib/picking.js", yaml, fixed = TRUE)[[1]],
    regexpr("lib/interactions/hover.js", yaml, fixed = TRUE)[[1]]
  )

  expect_match(js, "function normalizeInteractionsSpec", fixed = TRUE)
  expect_match(js, "function emitHover", fixed = TRUE)
  expect_match(js, "function emitClickSelection", fixed = TRUE)
  expect_match(js, "function emitCameraState", fixed = TRUE)
  expect_match(js, "pickSurfaceFaceAt", fixed = TRUE)
  expect_match(js, "raster_cell", fixed = TRUE)
  expect_match(js, "selectedIds", fixed = TRUE)
  expect_match(js, "_hover", fixed = TRUE)
  expect_match(js, "_selection", fixed = TRUE)
  expect_match(js, "_brush", fixed = TRUE)
  expect_match(js, "_camera", fixed = TRUE)
  expect_match(js, "_time", fixed = TRUE)
  expect_match(js, "{ priority: \"event\" }", fixed = TRUE)
  expect_match(js, "el.id + \"_timeline\"", fixed = TRUE)
})

test_that("CRAN-safe Shiny interaction demo builds a widget", {
  demo_path <- testthat::test_path("..", "..", "inst", "examples", "shiny", "interaction-demo.R")
  if (!file.exists(demo_path)) {
    demo_path <- system.file("examples", "shiny", "interaction-demo.R", package = "ggWebGL")
  }
  expect_true(file.exists(demo_path))

  demo <- paste(readLines(demo_path, warn = FALSE), collapse = "\n")
  expect_match(demo, "input$scene_hover", fixed = TRUE)
  expect_match(demo, "input$scene_selection", fixed = TRUE)
  expect_match(demo, "input$scene_brush", fixed = TRUE)
  expect_match(demo, "input$scene_camera", fixed = TRUE)
  expect_match(demo, "input$scene_time", fixed = TRUE)
  expect_false(grepl("download.file|write.csv|saveWidget|setwd|getwd", demo))

  env <- new.env(parent = baseenv())
  sys.source(demo_path, envir = env)
  widget <- env$interaction_demo_widget()
  expect_s3_class(widget, "htmlwidget")
  expect_true(widget$x$render$interactions$brush)
  expect_true(widget$x$render$interactions$lasso)
  expect_true(widget$x$render$interactions$camera)
  expect_false(is.null(widget$x$render$timeline))
})
