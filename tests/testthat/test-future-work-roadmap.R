read_repo_text <- function(path) {
  candidates <- c(
    file.path(getwd(), path),
    file.path(testthat::test_path(), "..", "..", path)
  )
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    skip(sprintf("%s is unavailable in this installed-package test context.", path))
  }

  paste(readLines(found[[1L]], warn = FALSE), collapse = "\n")
}

locate_future_work_example <- function() {
  candidates <- c(
    file.path(getwd(), "inst", "examples", "htmlwidget", "future-work-gallery.R"),
    file.path(getwd(), "tests", "testthat", "..", "..", "inst", "examples", "htmlwidget", "future-work-gallery.R"),
    system.file("examples", "htmlwidget", "future-work-gallery.R", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

locate_interaction_benchmark <- function() {
  candidates <- c(
    file.path(getwd(), "inst", "benchmarks", "benchmark-interaction-fps.R"),
    file.path(getwd(), "tests", "testthat", "..", "..", "inst", "benchmarks", "benchmark-interaction-fps.R"),
    system.file("benchmarks", "benchmark-interaction-fps.R", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

locate_renderer_capabilities_vignette <- function() {
  candidates <- c(
    file.path(getwd(), "vignettes", "renderer-capabilities.Rmd"),
    file.path(testthat::test_path(), "..", "..", "vignettes", "renderer-capabilities.Rmd"),
    system.file("doc", "renderer-capabilities.Rmd", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

test_that("experimental primitive helpers create renderer-ready contracts", {
  vectors <- ggwebgl_layer_vectors(
    data.frame(
      x = 0:1,
      y = 1:0,
      z = c(0.1, 0.4),
      xend = c(0.3, 1.2),
      yend = c(1.1, 0.4),
      zend = c(0.3, 0.8),
      id = c("a", "b"),
      frame = 1:2
    ),
    x = "x",
    y = "y",
    z = "z",
    xend = "xend",
    yend = "yend",
    zend = "zend",
    id = "id",
    frame = "frame",
    colour = "#0f766e",
    width = 2,
    head_size = 8
  )

  expect_equal(vectors$type, "vectors")
  expect_equal(vectors$rows, 2L)
  expect_equal(vectors$z, c(0.1, 0.4))
  expect_equal(vectors$zend, c(0.3, 0.8))
  expect_equal(vectors$id, c("a", "b"))
  expect_equal(vectors$frame, 1:2)
  expect_length(vectors$rgba, 8L)

  mesh <- ggwebgl_layer_mesh(
    vertices = data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0.2, 0.4)),
    x = "x",
    y = "y",
    z = "z",
    triangles = data.frame(i = 1L, j = 2L, k = 3L),
    colour = "#2563eb",
    material = ggwebgl_material(shading = "lambert", wireframe = TRUE),
    pick_id = "face-a"
  )

  expect_equal(mesh$type, "mesh")
  expect_equal(mesh$vertex_count, 3L)
  expect_equal(mesh$triangle_count, 1L)
  expect_equal(mesh$indices, c(0L, 1L, 2L))
  expect_equal(mesh$material$shading, "lambert")
  expect_length(mesh$normal, 9L)
  expect_equal(mesh$pick_id, "face-a")
  expect_true(mesh$wireframe)

  surface <- ggwebgl_layer_surface(matrix(seq_len(9), nrow = 3L), material = ggwebgl_material(shading = "lambert", wireframe = TRUE))
  expect_equal(surface$type, "surface")
  expect_equal(surface$vertex_count, 9L)
  expect_equal(surface$triangle_count, 8L)
  expect_equal(surface$surface_meta$shading, "surface_lambert")
  expect_equal(surface$surface_meta$triangulation, "regular_grid")
  expect_equal(surface$material$shading, "lambert")
  expect_length(surface$normals, surface$vertex_count * 3L)
  expect_length(surface$positions, surface$vertex_count * 3L)
  expect_length(surface$colors, surface$vertex_count * 4L)
})

test_that("experimental scene options normalize through ggwebgl_spec", {
  points <- ggwebgl_layer_points(
    data.frame(x = c(0, 1), y = c(1, 0), z = c(-0.2, 0.4), frame = 1:2, id = c("p1", "p2")),
    x = "x",
    y = "y",
    z = "z",
    frame = "frame",
    id = "id"
  )
  vectors <- ggwebgl_layer_vectors(
    data.frame(x = 0, y = 0, xend = 1, yend = 1),
    x = "x",
    y = "y",
    xend = "xend",
    yend = "yend"
  )
  mesh <- ggwebgl_layer_mesh(
    vertices = data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0)),
    x = "x",
    y = "y",
    z = "z",
    triangles = data.frame(i = 1L, j = 2L, k = 3L)
  )

  spec <- ggwebgl_spec(
    list(points, vectors, mesh),
    webgl = list(
      view = ggwebgl_view(
        dimension = "3d",
        projection = "perspective",
        controller = "trackball",
        state = list(yaw = 0.5, pitch = 0.25, distance = 3.1, target = c(1, 2, 3))
      ),
      selection = ggwebgl_selection("brush_lasso")
    ),
    timeline = ggwebgl_timeline(frames = 1:2, autoplay = TRUE, speed = 1.5, filter = "exact")
  )

  expect_equal(spec$webgl$view$controller, "trackball")
  expect_equal(spec$webgl$selection$mode, "brush_lasso")
  expect_equal(spec$webgl$dimension, "3d")
  expect_equal(spec$webgl$camera, "trackball")
  expect_equal(spec$webgl$projection, "perspective")
  expect_equal(spec$webgl$camera_state$target, c(1, 2, 3))
  expect_length(spec$webgl$camera_state$rotation, 4L)
  expect_equal(spec$render$dimension, "3d")
  expect_equal(spec$render$camera$mode, "trackball")
  expect_equal(spec$render$camera$controller, "trackball")
  expect_equal(spec$render$camera$projection, "perspective")
  expect_equal(spec$render$selection$mode, "brush_lasso")
  expect_equal(spec$render$timeline$frames, 1:2)
  expect_true(spec$render$timeline$autoplay)
  expect_equal(spec$render$timeline$filter, "exact")
  expect_equal(spec$render$point_count, 2L)
  expect_equal(spec$render$vector_count, 1L)
  expect_equal(spec$render$mesh_triangle_count, 1L)
  expect_true(all(c("points", "vectors", "mesh") %in% spec$render$primitives))
})

test_that("ggplot vector and surface geoms enter the WebGL render plan", {
  arrows <- data.frame(x = 1:3, y = 1:3, xend = 1:3 + 0.2, yend = 1:3 + 0.3)
  vector_widget <- ggplot_webgl(
    ggplot2::ggplot(arrows, ggplot2::aes(x, y, xend = xend, yend = yend)) +
      geom_vector_webgl(head_size = 6) +
      theme_webgl(selection = ggwebgl_selection("none"), interactions = character())
  )

  expect_equal(vector_widget$x$render$vector_count, 3L)
  expect_true("vectors" %in% vector_widget$x$render$primitives)

  surface <- expand.grid(x = 1:3, y = 1:3)
  surface$z <- with(surface, sin(x) + cos(y))
  surface_widget <- ggplot_webgl(
    ggplot2::ggplot(surface, ggplot2::aes(x, y, z = z, fill = z)) +
      geom_surface_webgl(wireframe = TRUE) +
      theme_webgl(view = ggwebgl_view(dimension = "3d", controller = "orbit"), selection = ggwebgl_selection("none"), interactions = character())
  )

  expect_equal(surface_widget$x$render$dimension, "3d")
  expect_equal(surface_widget$x$render$surface_triangle_count, 8L)
  expect_true("surface" %in% surface_widget$x$render$primitives)
})

test_that("widget source contains experimental renderer paths", {
  js <- read_repo_text("inst/htmlwidgets/ggWebGL.js")

  expect_match(js, "function drawVectorLayer", fixed = TRUE)
  expect_match(js, "function drawMeshLayer", fixed = TRUE)
  expect_match(js, "function drawSurfaceLayer", fixed = TRUE)
  expect_match(js, "gl.drawElements(gl.TRIANGLES", fixed = TRUE)
  expect_match(js, "surface_height_colormap", fixed = TRUE)
  expect_match(js, "function normalizeView", fixed = TRUE)
  expect_match(js, "function normalizeSelection", fixed = TRUE)
  expect_match(js, "function applyTrackballDrag", fixed = TRUE)
  expect_match(js, "function orbitQuaternion", fixed = TRUE)
  expect_match(js, "function meshShade", fixed = TRUE)
  expect_match(js, "function ensureMeshLayerGpuPayload", fixed = TRUE)
  expect_match(js, "OES_element_index_uint", fixed = TRUE)
  expect_match(js, "function emitSelection", fixed = TRUE)
  expect_match(js, "function renderSelectionOverlay", fixed = TRUE)
  expect_match(js, "function drawSelectionHighlights", fixed = TRUE)
  expect_match(js, "function applyMagnifierRegion", fixed = TRUE)
  expect_match(js, "ggwebgl__selection-controls", fixed = TRUE)
  expect_match(js, "ggwebgl__selection-status", fixed = TRUE)
  expect_match(js, "function bindTimelineHandlers", fixed = TRUE)
  expect_match(js, "function project3dPoint", fixed = TRUE)
  expect_match(js, "ggwebgl__timeline", fixed = TRUE)
  expect_match(js, "setInputValue(el.id + \"_selection\"", fixed = TRUE)
  expect_match(js, "filter: String(source.filter", fixed = TRUE)
  expect_match(js, "zend", fixed = TRUE)
  expect_match(js, "pick_id", fixed = TRUE)
})

test_that("experimental gallery examples render htmlwidgets", {
  example_path <- locate_future_work_example()
  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  example_env <- new.env(parent = globalenv())
  sys.source(example_path, envir = example_env)
  widgets <- evalq(future_work_demo_widgets(), envir = example_env)

  expect_named(widgets, c("vectors", "selection", "timeline", "camera_3d", "mesh_surface"))
  expect_true(all(vapply(widgets, inherits, logical(1), what = "htmlwidget")))
  expect_equal(widgets$vectors$x$render$vector_count, 247L)
  expect_equal(widgets$selection$x$webgl$selection$mode, "brush_lasso")
  expect_true(all(c("brush", "lasso") %in% widgets$selection$x$webgl$interactions))
  expect_false(is.null(widgets$timeline$x$render$timeline))
  expect_equal(widgets$timeline$x$render$timeline$filter, "exact")
  timeline_frames <- widgets$timeline$x$render$panels[[1L]]$layers[[1L]]$frame
  expect_gt(length(unique(timeline_frames)), 2L)
  expect_equal(table(timeline_frames)[[1L]], table(timeline_frames)[[length(table(timeline_frames))]])
  expect_equal(widgets$camera_3d$x$render$dimension, "3d")
  expect_gt(widgets$camera_3d$x$render$vector_count, 10L)
  expect_gt(widgets$mesh_surface$x$render$surface_triangle_count, 0L)
  expect_equal(widgets$mesh_surface$x$render$panels[[1L]]$layers[[1L]]$surface_meta$shading, "surface_lambert")
})

test_that("experimental renderer capabilities vignette is registered and scoped", {
  vignette_path <- locate_renderer_capabilities_vignette()
  if (is.na(vignette_path)) {
    skip("renderer-capabilities vignette is unavailable in this installed-package test context.")
  }

  vignette <- paste(readLines(vignette_path, warn = FALSE), collapse = "\n")
  required_demos <- c(
    "future_work_vector_field_demo",
    "future_work_selection_demo",
    "future_work_timeline_demo",
    "future_work_3d_camera_demo",
    "future_work_mesh_surface_demo"
  )

  expect_true(all(vapply(required_demos, grepl, logical(1), x = vignette, fixed = TRUE)))
  expect_true(grepl("future-work-gallery.R", vignette, fixed = TRUE))
  expect_true(grepl("ggwebgl_magnify_region", vignette, fixed = TRUE))
  expect_true(grepl("interactive = TRUE", vignette, fixed = TRUE))
  expect_true(grepl("render$links$magnifiers", vignette, fixed = TRUE))
  expect_true(grepl("brush-driven local zoom", vignette, fixed = TRUE))
  expect_false(grepl("\\b[0-9]+\\s*FPS\\b", vignette, ignore.case = TRUE, perl = TRUE))
  expect_false(grepl("XGeoRTR|shapViz3D|Shapley|TDA", vignette, ignore.case = TRUE, perl = TRUE))

  pkgdown <- read_repo_text("inst/_pkgdown.yml")
  expect_match(pkgdown, "- renderer-capabilities", fixed = TRUE)
})

test_that("interaction frame benchmark emits the performance schema without fixed rates", {
  benchmark_path <- locate_interaction_benchmark()
  expect_false(is.na(benchmark_path))
  if (is.na(benchmark_path)) {
    return(invisible())
  }

  bench_env <- new.env(parent = globalenv())
  sys.source(benchmark_path, envir = bench_env)
  out <- tempfile(fileext = ".csv")
  metrics <- bench_env$benchmark_interaction_frame_times(
    output_file = out,
    dataset_size = 1000L,
    include_browser = FALSE
  )

  expect_true(file.exists(out))
  expect_true(bench_env$validate_fps_claim_metrics(metrics))
  expect_true(all(bench_env$fps_claim_required_columns() %in% names(utils::read.csv(out))))
  expect_true(all(c(
    "claim_id", "package_version", "primitive_counts", "browser_version",
    "gpu_renderer", "rendering_mode", "dimension", "interaction",
    "warmup_frames", "median_fps", "p95_fps", "artifact_html",
    "artifact_csv", "created_at"
  ) %in% bench_env$fps_claim_required_columns()))
  expect_true(is.na(metrics$median_frame_time_ms[[1L]]))
  expect_true(is.na(metrics$median_fps[[1L]]))
  expect_equal(metrics$status[[1L]], "browser_unavailable")
})

test_that("roadmap documents implemented experimental features and performance-evidence discipline", {
  contract <- read_repo_text("RENDERER_CONTRACT.md")
  validation <- read_repo_text("VALIDATION.md")

  expect_match(contract, "Experimental interactions: `brush` and `lasso`", fixed = TRUE)
  expect_match(contract, "Experimental linked magnifier fields", fixed = TRUE)
  expect_match(contract, "Primitive: `vectors`", fixed = TRUE)
  expect_match(contract, "optional `zend`", fixed = TRUE)
  expect_match(contract, "Structured camera fields", fixed = TRUE)
  expect_match(contract, "Lambert lighting metadata", fixed = TRUE)
  expect_match(contract, "Experimental primitive: `mesh`", fixed = TRUE)
  expect_match(validation, "First-class 2D/3D vector arrows render as WebGL primitives | `real_now`", fixed = TRUE)
  expect_match(validation, "Brushing and lasso selection visibly select primitive ids | `real_now`", fixed = TRUE)
  expect_match(validation, "Distinct 3D orbit and trackball camera controls are available | `real_now`", fixed = TRUE)
  expect_match(validation, "Fixed frame-rate or million-point real-time rates are documented | `future_work`", fixed = TRUE)
})
