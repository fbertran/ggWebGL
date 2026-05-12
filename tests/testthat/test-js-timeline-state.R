locate_timeline_js <- function() {
  candidates <- c(
    file.path(getwd(), "inst/htmlwidgets/ggWebGL.js"),
    file.path(testthat::test_path(), "..", "..", "inst/htmlwidgets/ggWebGL.js"),
    system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    skip("ggWebGL.js is unavailable in this test context.")
  }
  found[[1L]]
}

read_timeline_js <- function() {
  paste(readLines(locate_timeline_js(), warn = FALSE), collapse = "\n")
}

test_that("JavaScript defines one normalized timeline state contract", {
  js <- read_timeline_js()

  expect_match(js, "function createTimelineState(spec, previous)", fixed = TRUE)
  expect_match(js, "values: []", fixed = TRUE)
  expect_match(js, "value: null", fixed = TRUE)
  expect_match(js, "index: 0", fixed = TRUE)
  expect_match(js, "source: \"frame\"", fixed = TRUE)
  expect_match(js, "filter: \"exact\"", fixed = TRUE)
  expect_match(js, "enabled: false", fixed = TRUE)
  expect_match(js, "state.timeline = createTimelineState(next, state.timeline)", fixed = TRUE)
})

test_that("JavaScript initializes timeline UI before deferred redraw", {
  js <- read_timeline_js()

  expect_match(
    js,
    "initialiseCameraFromScene\\(next\\);[[:space:]]+redrawCurrent\\(\\);[[:space:]]+requestAnimationFrame\\(function\\(\\)",
    perl = TRUE
  )
  expect_match(js, "requestAnimationFrame(function()", fixed = TRUE)
})

test_that("JavaScript centralizes timeline access and visibility helpers", {
  js <- read_timeline_js()

  expect_match(js, "function getTimelineValue(layer, rowOrVertexIndex, timeline)", fixed = TRUE)
  expect_match(js, "function isTimelineVisible(value, timeline)", fixed = TRUE)
  expect_match(js, "function findTimelineIndex(values, value, source)", fixed = TRUE)
  expect_match(js, "function setTimelineIndex(timeline, index)", fixed = TRUE)
  expect_match(js, "function setTimelineValue(timeline, value)", fixed = TRUE)
  expect_match(js, "timeline.filter === \"cumulative\"", fixed = TRUE)
  expect_match(js, "Math.abs(candidate - current) < 1e-9", fixed = TRUE)
})

test_that("JavaScript implements segment-aware line and path clipping", {
  js <- read_timeline_js()

  expect_match(js, "function pathSegmentVisible(path, i0, i1, x)", fixed = TRUE)
  expect_match(js, "pathSegmentVisible(path, s, s + 1, xScene)", fixed = TRUE)
  expect_match(js, "pathSegmentVisible(path, s, s + 1, x)", fixed = TRUE)
  expect_match(js, "payload.mode === \"lines\" ? gl.LINES : gl.LINE_STRIP", fixed = TRUE)
  expect_match(js, "pathSegmentVisible(path, i - 1, i, xScene)", fixed = TRUE)
  expect_match(js, "pathSegmentVisible(path, Math.min(index, neighbor), Math.max(index, neighbor), xScene)", fixed = TRUE)
})

test_that("JavaScript timeline milestone preserves scoped feature boundaries", {
  js <- read_timeline_js()

  expect_match(js, "trajectory_age", fixed = TRUE)
  expect_match(js, "trajectory_age_glow", fixed = TRUE)
  expect_match(js, "function createTimelineState(spec, previous)", fixed = TRUE)
})

test_that("non-timeline draw paths remain available", {
  js <- read_timeline_js()

  expect_match(js, "function drawPointLayer(gl, programs, layer, x, viewport)", fixed = TRUE)
  expect_match(js, "function drawLineLayer(gl, programs, layer, x, viewport, box)", fixed = TRUE)
  expect_match(js, "function drawRasterLayer(gl, programs, layer, scene, viewport)", fixed = TRUE)
  expect_match(js, "function drawVectorLayer(gl, programs, layer, x, viewport, box)", fixed = TRUE)
})
