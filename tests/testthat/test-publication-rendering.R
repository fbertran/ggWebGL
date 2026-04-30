test_that("ggwebgl_publication_figure builds DOM-first layouts with overlays", {
  point_spec <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0.15, 0.48, 0.82), y = c(0.22, 0.76, 0.38)),
        x = "x",
        y = "y",
        colour = c("#0f766e", "#f97316", "#2563eb"),
        alpha = 0.8,
        size = 5
      )
    )
  )

  figure <- ggwebgl_publication_figure(
    panels = list(point_spec, point_spec),
    layout = "row",
    labels = c("raw points", "density splat"),
    annotations = list(list(text = "1M points", x = 0.97, y = 0.94, hjust = 1)),
    inset = list(
      source = point_spec,
      left = 0.68,
      top = 0.08,
      width = 0.24,
      height = 0.24
    ),
    width = 640,
    height = 320,
    preset = "publication"
  )

  rendered <- htmltools::renderTags(figure)$html

  expect_s3_class(figure, "ggwebgl_publication_figure")
  expect_match(rendered, "ggwebgl-publication-figure")
  expect_match(rendered, "raw points")
  expect_match(rendered, "density splat")
  expect_match(rendered, "1M points")
  expect_match(rendered, "ggwebgl-publication-figure__inset")
})

test_that("publication rendering mode is wired through widget JS and CSS", {
  js_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js")
  css_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.css")

  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }
  if (!file.exists(css_path)) {
    css_path <- system.file("htmlwidgets", "ggWebGL.css", package = "ggWebGL")
  }

  expect_true(file.exists(js_path))
  expect_true(file.exists(css_path))

  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  css <- paste(readLines(css_path, warn = FALSE), collapse = "\n")

  expect_match(js, "rendering")
  expect_match(js, "panel_overlay")
  expect_match(js, "ggwebgl--publication")
  expect_match(js, "shouldShowPanelOverlay")

  expect_match(css, "\\.ggwebgl--publication \\{")
  expect_match(css, "\\.ggwebgl--publication \\.ggwebgl__header")
  expect_match(css, "\\.ggwebgl--publication \\.ggwebgl__stage")
})

test_that("compose_ggwebgl_figure routes renderable panels through the publication figure path", {
  body_text <- paste(deparse(body(compose_ggwebgl_figure)), collapse = "\n")

  expect_match(body_text, "ggwebgl_can_use_publication_figure")
  expect_match(body_text, "ggwebgl_build_publication_figure_object")
  expect_match(body_text, "snapshot_ggwebgl")
})
