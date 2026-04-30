cran_repo_path <- function(...) {
  candidates <- c(
    file.path(getwd(), ...),
    testthat::test_path("..", "..", ...)
  )
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    return(NA_character_)
  }
  found[[1L]]
}

cran_read_text <- function(...) {
  path <- cran_repo_path(...)
  if (is.na(path)) {
    skip(paste("Could not locate", file.path(...), "in this test context."))
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

test_that("optional bridge guard reports clear runtime errors", {
  expect_error(
    ggwebgl_require_optional("ggwebglDefinitelyMissingPackage", "the optional bridge"),
    "Package 'ggwebglDefinitelyMissingPackage' is required for the optional bridge",
    fixed = TRUE
  )
})

test_that("optional ecosystem examples do not attach GitHub-only packages", {
  files <- c(
    "inst/examples/htmlwidget/xgeortr-bridge-gallery.R",
    "inst/examples/htmlwidget/downstream-boids4r-animation.R",
    "inst/examples/htmlwidget/downstream-shapviz3d-views.R"
  )
  optional <- c("XGeoRTR", "boids4R", "shapViz3D")

  for (file in files) {
    text <- cran_read_text(file)
    for (pkg in optional) {
      attach_pattern <- paste0("(library|require)\\([\"']?", pkg, "[\"']?")
      expect_false(grepl(attach_pattern, text, perl = TRUE), info = paste(file, pkg))
    }
  }
})

test_that("CRAN-built optional bridge vignettes are gated by default", {
  xgeo <- cran_read_text("vignettes/xgeortr-bridge.Rmd")
  boids <- cran_read_text("vignettes/boids4r-animation.Rmd")

  expect_match(xgeo, "GGWEBGL_BUILD_OPTIONAL_BRIDGES", fixed = TRUE)
  expect_match(boids, "documentation-only", fixed = TRUE)
  expect_false(grepl("boids4R::", boids, fixed = TRUE))
  expect_match(xgeo, "not a\nCRAN dependency", fixed = TRUE)
  expect_match(boids, "not required for installation, examples, tests, or\nvignettes", fixed = TRUE)
})

# test_that("README describes ecosystem bridges as optional development integrations", {
#   readme <- cran_read_text("README.Rmd")
#
#   expect_match(readme, "optional development ecosystem", ignore.case = TRUE)
#   expect_match(readme, "installed separately", fixed = TRUE)
#   expect_match(readme, "Optional XGeoRTR development bridge", fixed = TRUE)
#   expect_match(readme, "Optional shapViz3D development consumer", fixed = TRUE)
#   expect_match(readme, "Optional boids4R development consumer", fixed = TRUE)
# })
