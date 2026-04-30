locate_boids4r_renderer_example <- function() {
  path <- file.path(
    normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = TRUE),
    "inst",
    "examples",
    "htmlwidget",
    "downstream-boids4r-animation.R"
  )
  if (!file.exists(path)) {
    return(NA_character_)
  }
  path
}

locate_boids4r_vignette <- function() {
  candidates <- c(
    file.path(getwd(), "vignettes", "boids4r-animation.Rmd"),
    testthat::test_path("..", "..", "vignettes", "boids4r-animation.Rmd"),
    system.file("doc", "boids4r-animation.Rmd", package = "ggWebGL")
  )
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    return(NA_character_)
  }
  found[[1L]]
}

test_that("downstream boids4R renderer example is guarded and renderer-focused", {
  example_path <- locate_boids4r_renderer_example()

  if (is.na(example_path)) {
    skip("downstream boids4R example is unavailable in this installed-package test context.")
  }

  text <- paste(readLines(example_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("requireNamespace\\(\"boids4R\"", text))
  expect_true(grepl("boids4R::as_ggwebgl_spec", text, fixed = TRUE))
  expect_true(grepl("ggWebGL::ggWebGL", text, fixed = TRUE))
  expect_true(grepl("density_splat", text, fixed = TRUE))
  expect_false(grepl("library\\(boids4R", text))
  expect_false(grepl("XGeoRTR", text, fixed = TRUE))
  expect_false(grepl("camera_state", text, fixed = TRUE))
})

test_that("boids4R swarm-art documentation is registered and boundary-focused", {
  vignette_path <- locate_boids4r_vignette()
  if (is.na(vignette_path)) {
    skip("boids4R vignette is unavailable in this installed-package test context.")
  }

  article <- paste(readLines(vignette_path, warn = FALSE), collapse = "\n")
  expect_match(article, "Swarm Art in the Browser", fixed = TRUE)
  expect_match(article, "boids4R` owns simulation semantics", fixed = TRUE)
  expect_match(article, "ggWebGL` owns WebGL rendering", fixed = TRUE)

  pkgdown_path <- file.path(getwd(), "inst", "_pkgdown.yml")
  if (!file.exists(pkgdown_path)) {
    pkgdown_path <- testthat::test_path("..", "..", "inst", "_pkgdown.yml")
  }
  if (!file.exists(pkgdown_path)) {
    skip("pkgdown config is unavailable in this installed-package test context.")
  }
  pkgdown <- paste(readLines(pkgdown_path, warn = FALSE), collapse = "\n")
  expect_match(pkgdown, "- boids4r-animation", fixed = TRUE)

  readme_path <- file.path(getwd(), "README.Rmd")
  if (!file.exists(readme_path)) {
    readme_path <- testthat::test_path("..", "..", "README.Rmd")
  }
  readme <- paste(readLines(readme_path, warn = FALSE), collapse = "\n")
#  expect_match(readme, "Optional swarm art with boids4R", fixed = TRUE)
#  expect_match(readme, "inst/examples/htmlwidget/downstream-boids4r-animation.R", fixed = TRUE)
})

test_that("downstream boids4R renderer example skips cleanly or returns widgets", {
  example_path <- locate_boids4r_renderer_example()

  if (is.na(example_path)) {
    skip("downstream boids4R example is unavailable in this installed-package test context.")
  }

  env <- new.env(parent = globalenv())
  expect_no_error(sys.source(example_path, envir = env))
  expect_true(exists("downstream_boids4r_widgets", envir = env))

  widgets <- env$downstream_boids4r_widgets()
  if (is.null(widgets)) {
    succeed()
    return(invisible())
  }

  expect_named(widgets, c("schooling_2d", "murmuration_3d"))
  expect_true(all(vapply(widgets, inherits, logical(1), what = "htmlwidget")))
  expect_equal(widgets$schooling_2d$x$render$timeline$filter, "exact")
  expect_equal(widgets$murmuration_3d$x$render$dimension, "3d")
  expect_true("vectors" %in% widgets$schooling_2d$x$render$primitives)
  expect_true("vectors" %in% widgets$murmuration_3d$x$render$primitives)
})
