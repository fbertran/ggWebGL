locate_adapter_example <- function() {
  candidates <- c(
    file.path(getwd(), "inst", "examples", "htmlwidget", "downstream-adapter-interfaces.R"),
    file.path(getwd(), "tests", "testthat", "..", "..", "inst", "examples", "htmlwidget", "downstream-adapter-interfaces.R"),
    system.file("examples", "htmlwidget", "downstream-adapter-interfaces.R", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

test_that("generic adapter layer helpers create renderer-ready primitives", {
  points <- data.frame(
    x = c(0, 1, 2),
    y = c(2, 1, 0),
    colour = c("#0f766e", "#f97316", "#2563eb"),
    id = c("a", "b", "c")
  )
  point_layer <- ggwebgl_layer_points(
    points,
    x = "x",
    y = "y",
    colour = "colour",
    alpha = 0.5,
    size = 3,
    label = "id"
  )

  expect_equal(point_layer$type, "points")
  expect_equal(point_layer$rows, 3L)
  expect_equal(point_layer$label, points$id)
  expect_length(point_layer$rgba, 12L)
  expect_true(all(point_layer$rgba >= 0 & point_layer$rgba <= 1))

  lines <- data.frame(
    x = c(0, 1, 2, 0, 1, 2),
    y = c(0, 1, 0, 1, 2, 1),
    group = c("a", "a", "a", "b", "b", "b")
  )
  line_layer <- ggwebgl_layer_lines(
    lines,
    x = "x",
    y = "y",
    group = "group",
    colour = "#334155",
    alpha = 0.75,
    width = 2
  )

  expect_equal(line_layer$type, "lines")
  expect_equal(line_layer$rows, 6L)
  expect_equal(line_layer$path_count, 2L)
  expect_equal(vapply(line_layer$paths, `[[`, character(1), "group"), c("a", "b"))

  raster_layer <- ggwebgl_layer_raster(
    rgba = rep(c(10L, 20L, 30L, 255L), 6L),
    width = 3L,
    height = 2L,
    xmin = -1,
    xmax = 1,
    ymin = 0,
    ymax = 2,
    interpolate = TRUE
  )

  expect_equal(raster_layer$type, "raster")
  expect_equal(raster_layer$rows, 6L)
  expect_true(raster_layer$interpolate)
  expect_length(raster_layer$rgba, 24L)
})

test_that("ggwebgl_spec aggregates panels and derives compatibility shims", {
  panel_a <- ggwebgl_layer_points(
    data.frame(x = 1:2, y = 2:1),
    x = "x",
    y = "y",
    panel_id = "A"
  )
  panel_b <- ggwebgl_layer_lines(
    data.frame(x = c(0, 1, 2), y = c(0, 1, 0)),
    x = "x",
    y = "y",
    panel_id = "B"
  )
  spec <- ggwebgl_spec(
    layers = list(panel_a, panel_b),
    labels = list(title = "adapter spec"),
    panels = data.frame(
      panel_id = c("A", "B"),
      row = c(1L, 1L),
      col = c(1L, 2L),
      label = c("left", "right"),
      stringsAsFactors = FALSE
    )
  )

  expect_s3_class(spec, "ggwebgl_spec")
  expect_equal(spec$render$mode, "webgl")
  expect_equal(spec$render$grid, list(rows = 1L, cols = 2L))
  expect_length(spec$render$panels, 2L)
  expect_equal(spec$render$point_count, 2L)
  expect_equal(spec$render$line_vertex_count, 3L)
  expect_equal(spec$render$path_count, 1L)
  expect_null(spec$render$layers)
  expect_equal(spec$labels$title, "adapter spec")

  single <- ggwebgl_spec(layers = list(panel_a))
  expect_identical(single$render$layers, single$render$panels[[1]]$layers)
  expect_identical(single$render$viewport, single$render$panels[[1]]$viewport)
  expect_identical(single$render$panel, single$render$panels[[1]]$panel_id)
})

test_that("ggWebGL dispatches classed adapter objects through as_ggwebgl_spec", {
  adapter_object <- structure(
    list(data = data.frame(x = c(0, 1), y = c(1, 0))),
    class = "adapter_dispatch_demo"
  )
  as_ggwebgl_spec.adapter_dispatch_demo <- function(x, ...) {
    ggwebgl_spec(
      layers = list(ggwebgl_layer_points(x$data, x = "x", y = "y")),
      labels = list(title = "dispatch demo")
    )
  }
  registerS3method(
    "as_ggwebgl_spec",
    "adapter_dispatch_demo",
    as_ggwebgl_spec.adapter_dispatch_demo,
    envir = asNamespace("ggWebGL")
  )

  widget <- ggWebGL(adapter_object)

  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$x$labels$title, "dispatch demo")
  expect_equal(widget$x$render$point_count, 2L)

  raw_payload <- list(render = list(mode = "metadata", panels = list()), labels = list())
  raw_widget <- ggWebGL(raw_payload)
  expect_identical(raw_widget$x, raw_payload)
})

test_that("downstream adapter example signatures render through ggWebGL", {
  example_path <- locate_adapter_example()

  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  example_env <- new.env(parent = globalenv())
  sys.source(example_path, envir = example_env)

  expect_true(exists("as_ggwebgl_spec.embedding_table_demo", envir = example_env))
  expect_true(exists("as_ggwebgl_spec.path_bundle_demo", envir = example_env))
  expect_true(exists("as_ggwebgl_spec.raster_field_demo", envir = example_env))

  widgets <- evalq(lapply(downstream_adapter_demo_objects(), ggWebGL), envir = example_env)

  expect_named(widgets, c("embedding_table", "path_bundle", "raster_field"))
  expect_true(all(vapply(widgets, inherits, logical(1), what = "htmlwidget")))
  expect_equal(widgets$embedding_table$x$render$primitives, "points")
  expect_true("lines" %in% widgets$path_bundle$x$render$primitives)
  expect_equal(widgets$raster_field$x$render$primitives, "raster")
})

test_that("generic adapter files do not encode downstream package semantics", {
  files <- c(
    file.path(getwd(), "R", "adapter-primitives.R"),
    locate_adapter_example()
  )
  files <- files[file.exists(files)]
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  forbidden <- c("shapViz3D", "rTDA3D", "RJEPAvis", "bigPCAcpp", "bigKNN", "bigANNOY")

  expect_false(any(vapply(forbidden, grepl, logical(1), x = text, fixed = TRUE)))
})
