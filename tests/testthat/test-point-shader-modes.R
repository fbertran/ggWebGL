test_that("point color alpha is normalized before renderer serialization", {
  rgba <- colour_to_rgba(rep("#336699", 3), alpha = c(-1, 0.25, 2))

  expect_equal(unname(rgba[, "alpha"]), c(0, 0.25, 1))
})

test_that("all point shader modes serialize stable point payloads", {
  modes <- c("default", "density_splat", "trajectory_age", "trajectory_age_glow")
  data <- data.frame(
    x = c(-0.8, -0.2, 0.1, 0.7, 1.1),
    y = c(0.1, 0.5, -0.2, 0.4, -0.1),
    group = factor(c("a", "a", "b", "b", "c"))
  )

  for (mode in modes) {
    plot <- ggplot2::ggplot(data, ggplot2::aes(x, y, colour = group)) +
      geom_point_webgl(size = 1.1, alpha = 0.35) +
      theme_webgl(shader = mode)
    widget <- ggplot_webgl(plot)
    render <- widget$x[["render"]]
    layer <- render[["layers"]][[1]]

    expect_equal(widget$x[["webgl"]][["shader"]], mode, info = mode)
    expect_equal(render[["mode"]], "webgl", info = mode)
    expect_equal(layer[["type"]], "points", info = mode)
    expect_equal(layer[["rows"]], nrow(data), info = mode)
    expect_true(all(layer[["rgba"]] >= 0 & layer[["rgba"]] <= 1), info = mode)
  }
})

test_that("density_splat uses source alpha and straight-alpha blending", {
  js_path <- file.path(getwd(), "inst", "htmlwidgets", "ggWebGL.js")

  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }

  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")

  expect_match(js, "float sourceAlpha = clamp\\(color\\.a, 0\\.0, 1\\.0\\);")
  expect_match(js, "uniform float u_density_alpha_boost;")
  expect_match(js, "uniform float u_density_alpha_ceiling;")
  expect_match(js, "color\\.a = clamp\\(sourceAlpha \\* w \\* u_density_alpha_boost, 0\\.0, u_density_alpha_ceiling\\);")
  expect_match(js, "function densitySplatTuning\\(pointCount\\)")
  expect_match(js, "uniform float u_min_point_size;")
  expect_match(
    js,
    "if \\(shaderMode === 1\\)[\\s\\S]*gl\\.blendFuncSeparate\\([\\s\\S]*gl\\.SRC_ALPHA[\\s\\S]*gl\\.ONE_MINUS_SRC_ALPHA[\\s\\S]*gl\\.ONE[\\s\\S]*gl\\.ONE_MINUS_SRC_ALPHA",
    perl = TRUE
  )
})

test_that("point layers use persistent GPU buffers across redraws", {
  js_path <- file.path(getwd(), "inst", "htmlwidgets", "ggWebGL.js")

  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }

  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  live_js <- gsub("/\\*[\\s\\S]*?\\*/", "", js, perl = TRUE)

  expect_match(live_js, "function createPointLayerGpuPayload\\(gl, layer\\)")
  expect_match(live_js, "function ensurePointLayerGpuPayload\\(gl, layer\\)")
  expect_match(live_js, "layer\\._ggwebglPointPayload")
  expect_match(live_js, "disposeSceneResources\\(state\\.x\\);")

  draw_point_layer <- sub(
    "^[\\s\\S]*function drawPointLayer\\(gl, programs, layer, x, viewport\\)",
    "function drawPointLayer(gl, programs, layer, x, viewport)",
    live_js,
    perl = TRUE
  )
  draw_point_layer <- sub(
    "function drawLineLayerNative[\\s\\S]*$",
    "",
    draw_point_layer,
    perl = TRUE
  )

  expect_match(draw_point_layer, "ensurePointLayerGpuPayload\\(gl, layer\\)")
  expect_false(grepl("deleteBuffer", draw_point_layer, fixed = TRUE))
})

test_that("point hover labels are serialized as generic primitive metadata", {
  data <- data.frame(
    x = c(-0.4, 0.1, 0.8),
    y = c(0.2, 0.6, -0.1),
    sample = c("sample-a", "sample-b", "sample-c")
  )

  plot <- expect_warning(
    ggplot2::ggplot(data, ggplot2::aes(x, y, label = sample)) +
      geom_point_webgl(size = 1.4, alpha = 0.8) +
      theme_webgl(interactions = c("pan", "zoom", "hover")),
    NA
  )
  widget <- ggplot_webgl(plot)
  layer <- widget$x[["render"]][["layers"]][[1]]

  expect_equal(layer[["type"]], "points")
  expect_equal(layer[["label"]], data$sample)

  js_path <- file.path(getwd(), "inst", "htmlwidgets", "ggWebGL.js")
  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }
  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")

  expect_match(js, "var pointLabel = Array\\.isArray\\(source\\.label\\)")
  expect_match(js, "<strong>sample</strong>")
})

test_that("point shader mode example gallery exports every mode", {
  example_path <- file.path(getwd(), "inst", "examples", "htmlwidget", "point-shader-modes.R")

  if (!file.exists(example_path)) {
    example_path <- system.file("examples", "htmlwidget", "point-shader-modes.R", package = "ggWebGL")
  }

  env <- new.env(parent = globalenv())
  sys.source(example_path, envir = env)

  examples <- env$point_shader_mode_examples(seed = 101L)
  expect_equal(names(examples), c("default", "density_splat", "trajectory_age", "trajectory_age_glow"))

  output_dir <- tempfile("ggwebgl-point-shaders-test-")
  files <- env$export_point_shader_mode_gallery(output_dir = output_dir, selfcontained = FALSE)

  expect_true(all(file.exists(files)))
  expect_true(file.exists(attr(files, "index")))
})
