mock_xgeo_state <- function(regular_grid = TRUE, include_lod = TRUE) {
  points <- data.frame(
    point_id = c("p1", "p2", "p3", "p4"),
    x = c(0, 1, 0, 1),
    y = c(0, 0, 1, 1),
    z = c(0, 0, 0, 0),
    stringsAsFactors = FALSE
  )

  if (!regular_grid) {
    points <- points[-4, , drop = FALSE]
  }

  explanations <- data.frame(
    point_id = points$point_id,
    feature = "value",
    value = c(0.1, 0.6, 0.4, 0.9)[seq_len(nrow(points))],
    stringsAsFactors = FALSE
  )

  embeddings <- list(
    active = "spatial",
    items = list(
      spatial = list(
        name = "spatial",
        method = "identity",
        source = "points",
        coords = data.frame(
          point_id = points$point_id,
          dim1 = points$x,
          dim2 = points$y,
          stringsAsFactors = FALSE
        )
      )
    )
  )

  lod <- list(
    active = list(name = NULL, level = NULL),
    items = list(),
    auto = list(point_threshold = 200L)
  )

  if (include_lod) {
    lod$active <- list(name = "density_grid_spatial", level = "2")
    lod$items <- list(
      density_grid_spatial = list(
        name = "density_grid_spatial",
        embedding = "spatial",
        color_by = "count",
        default_level = "2",
        levels = list(
          `2` = list(
            x = c(0, 1),
            y = c(0, 1),
            z = matrix(c(1, 2, 3, 4), nrow = 2, byrow = TRUE)
          )
        )
      )
    )
  }

  structure(
    list(
      geometry = list(points = points),
      attributes = list(
        explanations = explanations,
        point_meta = data.frame(point_id = points$point_id, stringsAsFactors = FALSE),
        feature_meta = data.frame(feature = "value", stringsAsFactors = FALSE),
        predictions = data.frame(point_id = points$point_id, stringsAsFactors = FALSE),
        uncertainty = data.frame(point_id = points$point_id, stringsAsFactors = FALSE),
        embeddings = embeddings,
        diagnostics = list(active = NULL, items = list()),
        baseline = NULL,
        method = "mock",
        structure = "spatial"
      ),
      indices = list(
        point_ids = points$point_id,
        feature_ids = "value"
      ),
      selection = list(point_ids = character(), features = character()),
      lod = lod,
      metadata = list(title = "mock-state")
    ),
    class = "xgeo_state"
  )
}

test_that("default as_ggwebgl_spec method errors for unsupported classes", {
  expect_error(
    as_ggwebgl_spec(list(a = 1)),
    "No as_ggwebgl_spec\\(\\) method"
  )
})

test_that("xgeo_state points adapter returns a webgl points render spec", {
  state <- mock_xgeo_state()
  spec <- as_ggwebgl_spec(state, primitive = "points", point_size = 5, alpha = 0.9)

  expect_true(all(c("labels", "webgl", "layer_count", "layers", "render") %in% names(spec)))
  expect_equal(spec$render$mode, "webgl")
  expect_equal(spec$render$primitives, "points")
  expect_equal(spec$render$point_count, nrow(state$geometry$points))
  expect_equal(spec$render$layers[[1]]$type, "points")
  expect_length(spec$render$layers[[1]]$x, nrow(state$geometry$points))
  expect_equal(spec$labels$title, "mock-state")
})

test_that("xgeo_state density adapter uses LOD bundle and produces raster payload", {
  state <- mock_xgeo_state(include_lod = TRUE)
  spec <- as_ggwebgl_spec(state, primitive = "density", lod = "density_grid_spatial/2")

  expect_equal(spec$render$mode, "webgl")
  expect_equal(spec$render$primitives, "raster")
  expect_equal(spec$render$layers[[1]]$type, "raster")
  expect_equal(spec$render$layers[[1]]$width, 2L)
  expect_equal(spec$render$layers[[1]]$height, 2L)
})

test_that("xgeo_state density adapter reports metadata mode when no LOD is available", {
  state <- mock_xgeo_state(include_lod = FALSE)
  spec <- as_ggwebgl_spec(state, primitive = "density")

  expect_equal(spec$render$mode, "metadata")
  expect_length(spec$render$messages, 1L)
  expect_match(spec$render$messages[[1]], "no valid LOD bundle")
})

test_that("xgeo_state surface adapter maps regular grids to raster payloads", {
  state <- mock_xgeo_state(regular_grid = TRUE)
  spec <- as_ggwebgl_spec(state, primitive = "surface")

  expect_equal(spec$render$mode, "webgl")
  expect_equal(spec$render$primitives, "raster")
  expect_equal(spec$render$layers[[1]]$type, "raster")
  expect_true(any(grepl("projected as a raster payload", spec$render$messages)))
})

test_that("xgeo_state surface adapter falls back to metadata on irregular grids", {
  state <- mock_xgeo_state(regular_grid = FALSE)
  spec <- as_ggwebgl_spec(state, primitive = "surface")

  expect_equal(spec$render$mode, "metadata")
  expect_length(spec$render$messages, 1L)
  expect_match(spec$render$messages[[1]], "requires a complete regular")
})
