locate_trajectory_shader_js <- function() {
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

read_trajectory_shader_js <- function() {
  paste(readLines(locate_trajectory_shader_js(), warn = FALSE), collapse = "\n")
}

test_that("trajectory shader modes normalize through theme_webgl", {
  expect_equal(theme_webgl(shader = "trajectory_velocity")$shader, "trajectory_velocity")
  expect_equal(theme_webgl(shader = "velocity")$shader, "trajectory_velocity")
  expect_equal(theme_webgl(shader = "trajectory-velocity")$shader, "trajectory_velocity")

  expect_equal(theme_webgl(shader = "trajectory_direction")$shader, "trajectory_direction")
  expect_equal(theme_webgl(shader = "direction")$shader, "trajectory_direction")
  expect_equal(theme_webgl(shader = "trajectory-direction")$shader, "trajectory_direction")

  expect_equal(theme_webgl(shader = "trajectory_age")$shader, "trajectory_age")
  expect_equal(theme_webgl(shader = "trajectory_age_glow")$shader, "trajectory_age_glow")
})

test_that("trajectory shader modes serialize into widget options", {
  path_data <- data.frame(
    x = c(0, 1, 2),
    y = c(0, 1, 1),
    z = c(0, 0.5, 1),
    group = 1L,
    frame = 1:3,
    time = c(0, 0.5, 1)
  )

  velocity_widget <- ggplot_webgl(
    ggplot2::ggplot(path_data, ggplot2::aes(x, y, z = z, group = group, frame = frame)) +
      geom_path3d_webgl() +
      theme_webgl(shader = "trajectory_velocity", interactions = character())
  )
  expect_equal(velocity_widget$x$webgl$shader, "trajectory_velocity")

  direction_widget <- ggplot_webgl(
    ggplot2::ggplot(path_data, ggplot2::aes(x, y, z = z, group = group, time = time)) +
      geom_path3d_webgl() +
      theme_webgl(shader = "trajectory_direction", interactions = character())
  )
  expect_equal(direction_widget$x$webgl$shader, "trajectory_direction")
})

test_that("JavaScript computes trajectory velocity and direction metrics", {
  js <- read_trajectory_shader_js()

  expect_match(js, "function computeTrajectoryVelocity(path)", fixed = TRUE)
  expect_match(js, "function computeTrajectoryDirection(path)", fixed = TRUE)
  expect_match(js, "function rawTrajectoryVelocity(path)", fixed = TRUE)
  expect_match(js, "function normalizeFiniteMetric(values, range)", fixed = TRUE)
  expect_match(js, "function computeLayerTrajectoryMetrics(layer, shaderMode)", fixed = TRUE)
  expect_match(js, "trajectoryDistance(path, i - 1, i)", fixed = TRUE)
  expect_match(js, "Math.atan2(dy, dx)", fixed = TRUE)
})

test_that("JavaScript routes trajectory shader modes through primitive line shaders", {
  js <- read_trajectory_shader_js()

  expect_match(js, "trajectory_age", fixed = TRUE)
  expect_match(js, "trajectory_age_glow", fixed = TRUE)
  expect_match(js, "trajectory_velocity", fixed = TRUE)
  expect_match(js, "trajectory_direction", fixed = TRUE)
  expect_match(js, "return 4;", fixed = TRUE)
  expect_match(js, "return 5;", fixed = TRUE)
  expect_match(js, "attribute float a_metric;", fixed = TRUE)
  expect_match(js, "varying float v_metric;", fixed = TRUE)
  expect_match(js, "bindMetricAttribute(gl, primitive, payload.metrics)", fixed = TRUE)
})

test_that("trajectory shader milestone does not add additional trajectory modes", {
  js <- read_trajectory_shader_js()

  expect_false(grepl("trajectory_acceleration", js, fixed = TRUE))
  expect_false(grepl("trajectory_curvature", js, fixed = TRUE))
})
