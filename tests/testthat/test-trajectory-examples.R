locate_trajectory_example <- function(filename) {
  candidates <- c(
    file.path(getwd(), "inst", "examples", "htmlwidget", filename),
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "inst", "examples", "htmlwidget", filename
    ),
    system.file("examples", "htmlwidget", filename, package = "ggWebGL")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) {
    return(NA_character_)
  }

  candidates[[1L]]
}

locate_shiny_trajectory_example <- function(filename) {
  candidates <- c(
    file.path(getwd(), "inst", "examples", "shiny", filename),
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "inst", "examples", "shiny", filename
    ),
    system.file("examples", "shiny", filename, package = "ggWebGL")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) {
    return(NA_character_)
  }

  candidates[[1L]]
}

locate_trajectory_vignette <- function(filename = "temporal-trajectories.Rmd") {
  candidates <- c(
    file.path(getwd(), "vignettes", filename),
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "vignettes", filename
    ),
    system.file("doc", filename, package = "ggWebGL")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) {
    return(NA_character_)
  }

  candidates[[1L]]
}

load_trajectory_examples <- function() {
  path <- locate_trajectory_example("temporal-trajectories.R")
  if (is.na(path)) {
    skip("temporal trajectory examples are unavailable in this test context.")
  }

  env <- new.env(parent = asNamespace("ggWebGL"))
  sys.source(path, envir = env)
  env
}

expect_no_unsafe_writes <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  unsafe <- c(
    "write\\.csv",
    "writeLines",
    "saveRDS",
    "save\\(",
    "save\\.image",
    "htmlwidgets::saveWidget",
    "htmltools::save_html",
    "dir\\.create",
    "file\\.create",
    "download\\.file",
    "unzip",
    "setwd",
    "getwd",
    "png\\(",
    "jpeg\\(",
    "pdf\\(",
    "ggsave",
    "set\\.seed"
  )

  for (pattern in unsafe) {
    expect_false(grepl(pattern, text), info = paste(basename(path), pattern))
  }
}

timeline_equal <- function(a, b, source) {
  if (identical(source, "frame")) {
    return(round(as.numeric(a)) == round(as.numeric(b)))
  }

  abs(as.numeric(a) - as.numeric(b)) < 1e-9
}

timeline_visible <- function(value, current, filter, source) {
  if (identical(filter, "cumulative")) {
    if (identical(source, "frame")) {
      return(round(as.numeric(value)) <= round(as.numeric(current)))
    }
    return(as.numeric(value) <= as.numeric(current) + 1e-9)
  }

  timeline_equal(value, current, source)
}

count_initial_path_segments <- function(widget) {
  timeline <- widget$x$render$timeline
  current <- timeline$values[[1L]]
  source <- timeline$source
  filter <- timeline$filter
  count <- 0L

  for (panel in widget$x$render$panels) {
    for (layer in panel$layers) {
      if (!identical(layer$type, "lines")) {
        next
      }
      for (path in layer$paths) {
        values <- path[[source]]
        if (is.null(values) || length(values) < 2L) {
          next
        }
        for (index in seq_len(length(values) - 1L)) {
          if (timeline_visible(values[[index]], current, filter, source) &&
              timeline_visible(values[[index + 1L]], current, filter, source)) {
            count <- count + 1L
          }
        }
      }
    }
  }

  count
}

count_initial_points <- function(widget) {
  timeline <- widget$x$render$timeline
  current <- timeline$values[[1L]]
  source <- timeline$source
  filter <- timeline$filter
  count <- 0L

  for (panel in widget$x$render$panels) {
    for (layer in panel$layers) {
      if (!identical(layer$type, "points")) {
        next
      }
      values <- layer[[source]]
      if (is.null(values)) {
        next
      }
      count <- count + sum(vapply(values, timeline_visible, logical(1), current, filter, source))
    }
  }

  count
}

expect_timeline_controls_ready <- function(widget) {
  expect_true(widget$x$render$timeline$autoplay)
  expect_true(widget$x$render$timeline$controls)
  expect_gt(length(widget$x$render$timeline$values), 1L)
}

test_that("temporal trajectory examples build htmlwidgets with timeline metadata", {
  examples <- load_trajectory_examples()

  spiral <- examples$temporal_spiral_widget(height = 240)
  expect_s3_class(spiral, "htmlwidget")
  expect_equal(spiral$x$webgl$shader, "trajectory_age")
  expect_equal(spiral$x$render$dimension, "2d")
  expect_equal(spiral$x$render$timeline$filter, "cumulative")
  expect_equal(spiral$x$render$timeline$source, "frame")
  expect_timeline_controls_ready(spiral)
  expect_gt(count_initial_path_segments(spiral), 0L)
  expect_equal(spiral$x$render$panels[[1L]]$layers[[1L]]$subtype, "path3d")

  helix <- examples$temporal_helix_widget(height = 240)
  expect_s3_class(helix, "htmlwidget")
  expect_equal(helix$x$webgl$shader, "trajectory_age")
  expect_equal(helix$x$render$dimension, "3d")
  expect_equal(helix$x$render$coordinate_system, "cartesian3d")
  expect_equal(helix$x$render$timeline$source, "time")
  expect_equal(helix$x$render$timeline$filter, "cumulative")
  expect_timeline_controls_ready(helix)
  expect_gt(count_initial_path_segments(helix), 0L)
})

test_that("trajectory shader examples use implemented renderer modes", {
  examples <- load_trajectory_examples()

  velocity <- examples$temporal_velocity_widget(height = 240)
  expect_s3_class(velocity, "htmlwidget")
  expect_equal(velocity$x$webgl$shader, "trajectory_velocity")
  expect_equal(velocity$x$render$timeline$filter, "cumulative")
  expect_timeline_controls_ready(velocity)
  expect_gt(count_initial_path_segments(velocity), 0L)

  direction <- examples$temporal_direction_widget(height = 240)
  expect_s3_class(direction, "htmlwidget")
  expect_equal(direction$x$webgl$shader, "trajectory_direction")
  expect_equal(direction$x$render$timeline$source, "time")
  expect_timeline_controls_ready(direction)
  expect_gt(count_initial_path_segments(direction), 0L)

  exact <- examples$temporal_exact_particles_widget(height = 220)
  expect_s3_class(exact, "htmlwidget")
  expect_equal(exact$x$webgl$shader, "default")
  expect_equal(exact$x$render$timeline$filter, "exact")
  expect_equal(exact$x$render$timeline$source, "frame")
  expect_timeline_controls_ready(exact)
  expect_gt(count_initial_points(exact), 0L)
})

test_that("temporal trajectory widget list is stable", {
  examples <- load_trajectory_examples()

  widgets <- examples$temporal_trajectory_widgets()
  expect_named(widgets, c("spiral", "helix", "velocity", "direction", "exact_particles"))
  expect_true(all(vapply(widgets, inherits, logical(1), what = "htmlwidget")))
})

test_that("temporal trajectory vignette covers trajectory and Shiny APIs", {
  vignette <- locate_trajectory_vignette()
  if (is.na(vignette)) {
    skip("temporal trajectory vignette is unavailable in this test context.")
  }

  text <- paste(readLines(vignette, warn = FALSE), collapse = "\n")
  expect_match(text, "geom_path3d_webgl", fixed = TRUE)
  expect_match(text, "animation_spec", fixed = TRUE)
  expect_match(text, "trajectory_age", fixed = TRUE)
  expect_match(text, "trajectory_velocity", fixed = TRUE)
  expect_match(text, "trajectory_direction", fixed = TRUE)
  expect_match(text, "input\\$<outputId>_timeline")
  expect_match(text, "updateGgWebGLTimeline", fixed = TRUE)

  forbidden <- c(
    paste0("SIG", "GRAPH"),
    paste0("po", "ster"),
    paste("claim", "matrix"),
    paste0("sub", "mission")
  )
  for (term in forbidden) {
    expect_false(grepl(term, text, ignore.case = TRUE), info = term)
  }
})

test_that("temporal trajectory examples are CRAN-safe source files", {
  html_example <- locate_trajectory_example("temporal-trajectories.R")
  shiny_example <- locate_shiny_trajectory_example("timeline-control-demo.R")

  expect_false(is.na(html_example))
  expect_false(is.na(shiny_example))
  expect_no_unsafe_writes(html_example)
  expect_no_unsafe_writes(shiny_example)
})

test_that("pkgdown navigation lists temporal trajectory article", {
  candidates <- c(
    file.path(getwd(), "inst", "_pkgdown.yml"),
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "inst", "_pkgdown.yml"
    )
  )
  candidates <- candidates[file.exists(candidates)]
  if (!length(candidates)) {
    skip("pkgdown configuration is unavailable in this test context.")
  }

  pkgdown <- paste(readLines(candidates[[1L]], warn = FALSE), collapse = "\n")
  expect_match(pkgdown, "- temporal-trajectories", fixed = TRUE)
})
