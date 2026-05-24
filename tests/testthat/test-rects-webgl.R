test_that("internal rectangle layers serialize filled quad payloads", {
  layer <- ggwebgl_layer_rects(
    xmin = c(0, 1),
    xmax = c(0.5, 1.5),
    ymin = c(0, 0.2),
    ymax = c(1, 1.2),
    fill = c("#0f766e", "#f97316"),
    colour = "#334155",
    alpha = 0.5,
    linewidth = c(1, 2),
    frame = c(1L, 2L),
    time = c(0, 0.5),
    panel_id = "A"
  )

  expect_equal(layer$type, "rects")
  expect_equal(layer$rows, 2L)
  expect_equal(layer$panel_id, "A")
  expect_equal(layer$xmin, c(0, 1))
  expect_equal(layer$xmax, c(0.5, 1.5))
  expect_equal(layer$ymin, c(0, 0.2))
  expect_equal(layer$ymax, c(1, 1.2))
  expect_equal(layer$linewidth, c(1, 2))
  expect_equal(layer$frame, c(1L, 2L))
  expect_equal(layer$time, c(0, 0.5))
  expect_length(layer$rgba, 8L)
  expect_length(layer$stroke_rgba, 8L)
  expect_true(all(layer$rgba >= 0 & layer$rgba <= 1))
  expect_equal(layer$rgba[c(4, 8)], c(0.5, 0.5))
})

test_that("internal rectangle layers support empty payloads", {
  layer <- ggwebgl_layer_rects(
    xmin = numeric(),
    xmax = numeric(),
    ymin = numeric(),
    ymax = numeric()
  )

  expect_equal(layer$type, "rects")
  expect_equal(layer$rows, 0L)
  expect_length(layer$xmin, 0L)
  expect_length(layer$rgba, 0L)
})

test_that("internal rectangle validation rejects missing and invalid bounds", {
  expect_error(
    ggwebgl_layer_rects(xmax = 1, ymin = 0, ymax = 1),
    "`xmin` is required",
    fixed = TRUE
  )
  expect_error(
    ggwebgl_layer_rects(xmin = 0, xmax = NA_real_, ymin = 0, ymax = 1),
    "Rectangle bounds must be finite",
    fixed = TRUE
  )
  expect_error(
    ggwebgl_layer_rects(xmin = 2, xmax = 1, ymin = 0, ymax = 1),
    "xmin <= xmax",
    fixed = TRUE
  )
  expect_error(
    ggwebgl_layer_rects(xmin = numeric(), xmax = 1, ymin = 0, ymax = 1),
    "Rectangle bounds must all be empty",
    fixed = TRUE
  )
})

test_that("internal rectangle specs aggregate panels and viewport bounds", {
  panel_a <- ggwebgl_layer_rects(
    xmin = 0,
    xmax = 1,
    ymin = 0,
    ymax = 1,
    panel_id = "A"
  )
  panel_b <- ggwebgl_layer_rects(
    xmin = c(10, 11),
    xmax = c(10.5, 12),
    ymin = c(-2, -1),
    ymax = c(-1, 0),
    panel_id = "B"
  )

  spec <- ggwebgl_spec(
    layers = list(panel_a, panel_b),
    panels = data.frame(
      panel_id = c("A", "B"),
      row = c(1L, 1L),
      col = c(1L, 2L),
      stringsAsFactors = FALSE
    )
  )

  expect_equal(spec$render$primitives, "rects")
  expect_equal(spec$render$rect_count, 3L)
  expect_equal(unname(vapply(spec$render$panels, `[[`, integer(1), "rect_count")), c(1L, 2L))
  expect_equal(spec$render$panels[[1]]$viewport$x, c(0, 1))
  expect_equal(spec$render$panels[[1]]$viewport$y, c(0, 1))
  expect_equal(spec$render$panels[[2]]$viewport$x, c(10, 12))
  expect_equal(spec$render$panels[[2]]$viewport$y, c(-2, 0))
})

test_that("widget source contains internal rectangle draw path", {
  js <- paste(
    readLines(testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(js, "function normalizeLayer", fixed = TRUE)
  expect_match(js, "type === \"rects\"", fixed = TRUE)
  expect_match(js, "function flattenRectLayer", fixed = TRUE)
  expect_match(js, "function drawRectLayer", fixed = TRUE)
  expect_match(js, "function drawRectsLayer", fixed = TRUE)
  expect_match(js, "gl.drawArrays(gl.TRIANGLES, 0, payload.count)", fixed = TRUE)
  expect_match(js, "layer.type === \"rects\"", fixed = TRUE)
})
