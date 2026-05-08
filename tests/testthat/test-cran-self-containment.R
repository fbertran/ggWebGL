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

test_that("suggested bridge packages remain out of hard dependencies", {
  description_path <- cran_repo_path("DESCRIPTION")
  if (is.na(description_path)) {
    description_path <- system.file("DESCRIPTION", package = "ggWebGL")
  }
  if (!nzchar(description_path) || !file.exists(description_path)) {
    skip("DESCRIPTION is unavailable in this test context.")
  }

  description <- read.dcf(description_path)
  hard_dependency_fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(description))
  hard_dependencies <- paste(description[, hard_dependency_fields, drop = TRUE], collapse = "\n")
  suggests <- if ("Suggests" %in% colnames(description)) description[, "Suggests"] else ""

  expect_false(grepl("XGeoRTR", hard_dependencies, fixed = TRUE))
  expect_false(grepl("boids4R", hard_dependencies, fixed = TRUE))
  expect_false(grepl("shapViz3D", hard_dependencies, fixed = TRUE))
  expect_true(grepl("XGeoRTR", suggests, fixed = TRUE))
  expect_true(grepl("boids4R", suggests, fixed = TRUE))
  expect_false(grepl("shapViz3D", suggests, fixed = TRUE))
})

test_that("suggested bridge vignettes degrade cleanly when packages are absent", {
  xgeo <- cran_read_text("vignettes/xgeortr-bridge.Rmd")
  boids <- cran_read_text("vignettes/boids4r-animation.Rmd")

  expect_match(xgeo, "requireNamespace(\"XGeoRTR\"", fixed = TRUE)
  expect_match(boids, "requireNamespace(\"boids4R\"", fixed = TRUE)
  expect_match(xgeo, "XGeoRTR is unavailable, so the live bridge widgets are skipped", fixed = TRUE)
  expect_match(boids, "boids4R is unavailable, so live boids animations are skipped", fixed = TRUE)
  expect_true(grepl("boids4R::", boids, fixed = TRUE))
  expect_false(grepl("GGWEBGL_BUILD_OPTIONAL_BRIDGES", xgeo, fixed = TRUE))
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
