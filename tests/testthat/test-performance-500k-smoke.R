locate_performance_500k_smoke <- function() {
  candidates <- c(
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "inst", "examples", "htmlwidget", "performance-500k-smoke-test.R"
    ),
    system.file("examples", "htmlwidget", "performance-500k-smoke-test.R", package = "ggWebGL")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) {
    return(NA_character_)
  }

  candidates[[1L]]
}

load_performance_500k_smoke <- function() {
  path <- locate_performance_500k_smoke()
  if (is.na(path)) {
    skip("500k performance smoke example is unavailable in this test context.")
  }

  env <- new.env(parent = asNamespace("ggWebGL"))
  sys.source(path, envir = env)
  env
}

test_that("500k performance smoke script exposes manual and browser helpers", {
  path <- locate_performance_500k_smoke()
  expect_false(is.na(path))
  if (is.na(path)) {
    return(invisible())
  }

  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  expect_match(text, "performance_500k_cloud <- function", fixed = TRUE)
  expect_match(text, "performance_500k_widget <- function", fixed = TRUE)
  expect_match(text, "run_manual_500k_performance_smoke_test <- function", fixed = TRUE)
  expect_match(text, "run_chromote_500k_performance_smoke_test <- function", fixed = TRUE)
  expect_match(text, "point_count = 500000L", fixed = TRUE)
  expect_match(text, "density_splat", fixed = TRUE)
  expect_match(text, "requestAnimationFrame", fixed = TRUE)
  expect_match(text, "performance.now", fixed = TRUE)
  expect_match(text, "window.__ggwebgl_500k_smoke_metrics", fixed = TRUE)
  expect_match(text, "Manual smoke metrics", fixed = TRUE)
})

test_that("500k performance smoke script stays manual and temp-path safe", {
  path <- locate_performance_500k_smoke()
  expect_false(is.na(path))
  if (is.na(path)) {
    return(invisible())
  }

  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  expect_match(text, "output = tempfile\\(fileext = \"\\.html\"\\)")
  expect_match(text, "output_dir = tempdir\\(\\)")
  expect_match(text, "requireNamespace\\(\"chromote\", quietly = TRUE\\)")
  expect_false(grepl("chromote::", text, fixed = TRUE))
  expect_false(grepl("setwd\\(|download\\.file\\(|set\\.seed\\(", text))
  expect_false(grepl("60 FPS|120 FPS|fixed FPS|guaranteed FPS", text))
  expect_false(grepl("dir\\.create\\(", text))
  expect_false(grepl("getwd\\(", text))
})

test_that("500k performance smoke data is deterministic and reduced widgets build", {
  env <- load_performance_500k_smoke()

  first <- env$performance_500k_cloud(point_count = 1000L)
  second <- env$performance_500k_cloud(point_count = 1000L)
  expect_equal(first, second)
  expect_equal(nrow(first), 1000L)
  expect_true(all(c("x", "y", "cluster") %in% names(first)))
  expect_true(all(is.finite(first$x)))
  expect_true(all(is.finite(first$y)))

  widget <- env$performance_500k_widget(point_count = 1000L, frame_count = 6L, warmup_frames = 2L)
  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$x$webgl$shader, "density_splat")
  expect_equal(widget$x$render$point_count, 1000L)
})
