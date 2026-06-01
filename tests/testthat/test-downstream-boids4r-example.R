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

skip_if_no_boids4r_display_adapter <- function() {
  if (!requireNamespace("boids4R", quietly = TRUE)) {
    skip("boids4R is unavailable in this test context.")
  }
  if (!ggWebGL:::ggwebgl_boids_adapter_supports_display_args()) {
    skip("Installed boids4R does not expose the display-aware ggWebGL adapter.")
  }
}

test_that("downstream boids4R renderer example is guarded and renderer-focused", {
  example_path <- locate_boids4r_renderer_example()

  if (is.na(example_path)) {
    skip("downstream boids4R example is unavailable in this installed-package test context.")
  }

  text <- paste(readLines(example_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("requireNamespace\\(\"boids4R\"", text))
  expect_true(grepl("ggwebgl_boids_display_spec", text, fixed = TRUE))
  expect_true(grepl("ggWebGL::ggWebGL", text, fixed = TRUE))
  expect_true(grepl("vector_mode = c(\"current\"", text, fixed = TRUE))
  expect_true(grepl("vector_colour_mode = c(\"species\"", text, fixed = TRUE))
  expect_true(grepl("obstacle_mode = c(\"ring\"", text, fixed = TRUE))
  expect_true(grepl("shader = \"default\"", text, fixed = TRUE))
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

boids_fixture_spec <- function(n_boids = 4L, frames = c(0L, 2L, 4L, 6L)) {
  grid <- expand.grid(
    id = seq_len(n_boids),
    frame = frames,
    KEEP.OUT.ATTRS = FALSE
  )
  grid$time <- grid$frame / 10
  grid$x <- grid$id * 0.1 + grid$frame * 0.01
  grid$y <- grid$id * 0.2
  grid$z <- 0
  grid$xend <- grid$x + 0.05
  grid$yend <- grid$y + 0.02
  grid$zend <- 0
  grid$label <- paste0("boid-", grid$id)

  points <- ggwebgl_layer_points(
    grid,
    x = "x",
    y = "y",
    z = "z",
    id = "label",
    frame = "frame",
    time = "time",
    colour = "#38bdf8",
    alpha = 0.2,
    size = 1.1
  )
  vectors <- ggwebgl_layer_vectors(
    grid,
    x = "x",
    y = "y",
    z = "z",
    xend = "xend",
    yend = "yend",
    zend = "zend",
    id = "label",
    frame = "frame",
    time = "time",
    colour = "#0f172a",
    alpha = 0.6,
    width = 1.1,
    head_size = 6
  )

  ggwebgl_spec(
    layers = list(points, vectors),
    labels = list(title = "boids fixture"),
    webgl = webgl_spec(
      shader = "density_splat",
      timeline = ggwebgl_timeline(
        frames = frames,
        time = frames / 10,
        source = "time",
        filter = "exact",
        controls = TRUE
      )
    )
  )
}

boids_fixture_sim <- function(n_boids = 4L, frames = c(0L, 2L, 4L, 6L)) {
  grid <- expand.grid(
    id = seq_len(n_boids),
    frame = frames,
    KEEP.OUT.ATTRS = FALSE
  )
  grid$time <- grid$frame / 10
  grid$id <- paste0("boid-", sprintf("%03d", grid$id))
  grid$species <- rep(c("school", "scout"), length.out = nrow(grid))
  grid$x <- seq_len(nrow(grid)) / 100
  grid$y <- rep(seq_len(n_boids), times = length(frames)) / 10
  grid$z <- 0
  grid$vx <- 0.4
  grid$vy <- 0.1
  grid$vz <- 0
  grid$speed <- sqrt(grid$vx^2 + grid$vy^2)

  list(
    frames = grid,
    world = list(
      obstacles = data.frame(x = 0.2, y = 0.4, radius = 0.1, z = 0),
      predators = data.frame(x = -0.3, y = 0.5, radius = 0.2, strength = 1, z = 0),
      attractors = data.frame(x = 0.8, y = -0.2, strength = 0.8, z = 0)
    ),
    dimension = "2d"
  )
}

test_that("boids display palette separates species, prey, predators, obstacles, and vectors", {
  palette <- ggWebGL:::ggwebgl_boids_palette()
  keys <- c("species_1", "species_2", "species_3", "prey", "predator", "obstacle", "vector")
  expect_true(all(keys %in% names(palette)))
  expect_equal(length(unique(unname(palette[keys]))), length(keys))
})

test_that("downstream boids4R demo defaults use a longer behavioural timeline", {
  example_path <- locate_boids4r_renderer_example()
  if (is.na(example_path)) {
    skip("downstream boids4R example is unavailable in this installed-package test context.")
  }

  env <- new.env(parent = globalenv())
  expect_no_error(sys.source(example_path, envir = env))

  if (!requireNamespace("boids4R", quietly = TRUE)) {
    skip("boids4R is unavailable in this test context.")
  }

  sims <- env$build_downstream_boids4r_simulations(demo_steps = 240L)
  expect_gte(max(sims$schooling_2d$frames$frame), 240L)
  expect_gte(length(unique(sims$schooling_2d$frames$frame)), 60L)
})

test_that("boids display wrapper preserves species-aware vector colours from boids4R", {
  skip_if_no_boids4r_display_adapter()

  sim <- boids4R::boids_scenario(
    "mixed_species_3d",
    n = 36L,
    steps = 12L,
    record_every = 3L,
    seed = 314L
  )
  spec <- ggWebGL:::ggwebgl_boids_display_spec(
    sim,
    trail = "recent",
    trail_length = 8L,
    vector_mode = "current",
    vector_colour_mode = "species",
    vector_alpha = 0.68,
    vector_width = 1.25,
    obstacle_mode = "ring",
    shader = "default",
    autoplay = FALSE,
    loop = FALSE,
    speed = 1.7,
    fps = 12L
  )

  vector_layer <- spec$render$layers[[which(vapply(spec$render$layers, function(layer) identical(layer$type, "vectors"), logical(1)))[[1L]]]]
  vector_rgba <- matrix(vector_layer$rgba, ncol = 4L, byrow = TRUE)
  point_layers <- spec$render$layers[vapply(spec$render$layers, function(layer) identical(layer$type, "points"), logical(1))]
  point_alphas <- unlist(lapply(point_layers, function(layer) matrix(layer$rgba, ncol = 4L, byrow = TRUE)[, 4L]), use.names = FALSE)

  expect_gt(nrow(unique(round(vector_rgba[, 1:3, drop = FALSE], 3))), 1L)
  expect_equal(unique(round(vector_rgba[, 4L], 2)), 0.68)
  expect_true(any(vapply(spec$render$layers, function(layer) identical(layer$type, "lines"), logical(1))))
  expect_true(any(point_alphas < 0.3))
  expect_true(any(point_alphas > 0.85))
  expect_equal(spec$render$timeline$speed, 1.7)
  expect_equal(spec$render$timeline$fps, 12L)
  expect_false(spec$render$timeline$autoplay)
  expect_false(spec$render$timeline$loop)
})

test_that("boids display wrapper still supports fixed neutral vector colours", {
  skip_if_no_boids4r_display_adapter()

  sim <- boids4R::boids_scenario(
    "mixed_species_3d",
    n = 24L,
    steps = 9L,
    record_every = 3L,
    seed = 315L
  )
  spec <- ggWebGL:::ggwebgl_boids_display_spec(
    sim,
    trail = "none",
    vector_mode = "current",
    vector_colour_mode = "fixed",
    vector_colour = "#334155",
    vector_alpha = 0.44,
    obstacle_mode = "none",
    shader = "default"
  )

  vector_layer <- spec$render$layers[[which(vapply(spec$render$layers, function(layer) identical(layer$type, "vectors"), logical(1)))[[1L]]]]
  vector_rgba <- unique(round(matrix(vector_layer$rgba, ncol = 4L, byrow = TRUE), 3))
  expected_rgb <- round(grDevices::col2rgb("#334155")[, 1L] / 255, 3)

  expect_equal(nrow(vector_rgba), 1L)
  expect_equal(unname(vector_rgba[1L, 1:3]), unname(expected_rgb))
  expect_equal(vector_rgba[1L, 4L], 0.44)
})

test_that("boids display current vectors include one velocity per current boid", {
  spec <- boids_fixture_spec(n_boids = 4L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    obstacles = data.frame(x = 0.2, y = 0.4, radius = 0.1),
    vector_mode = "current",
    trail = "recent",
    trail_length = 2L,
    boid_size = 3.8,
    boid_alpha = 0.75
  )

  vectors <- out$render$layers[[which(vapply(out$render$layers, `[[`, character(1), "type") == "vectors")]]
  current_frame <- max(out$render$timeline$frames)
  expect_equal(sum(vectors$frame == current_frame), 4L)
  expect_equal(out$render$vector_count, 8L)
  expect_equal(out$render$timeline$frames, c(0L, 2L, 4L, 6L))
})

test_that("boids display splits current boids from faint recent trails", {
  spec <- boids_fixture_spec(n_boids = 4L)
  sim <- boids_fixture_sim(n_boids = 4L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    sim = sim,
    vector_mode = "current",
    trail = "recent",
    trail_length = 2L,
    boid_size = 4.4,
    current_alpha = 0.96,
    trail_alpha = 0.16
  )

  geoms <- vapply(out$render$layers, function(layer) layer$geom %||% "", character(1))
  current <- out$render$layers[[which(geoms == "boids_current")]]
  trail <- out$render$layers[[which(geoms == "boids_recent_trail")]]
  current_rgba <- matrix(current$rgba, ncol = 4L, byrow = TRUE)
  trail_rgba <- matrix(trail$rgba, ncol = 4L, byrow = TRUE)

  expect_equal(unique(current$size), 4.4)
  expect_equal(unique(current_rgba[, 4L]), 0.96)
  expect_equal(unique(trail_rgba[, 4L]), 0.16)
  expect_lt(max(trail$size), min(current$size))
})

test_that("boids display current vector layer has one vector per boid in active frames", {
  spec <- boids_fixture_spec(n_boids = 4L)
  sim <- boids_fixture_sim(n_boids = 4L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    sim = sim,
    vector_mode = "current",
    obstacle_mode = "none",
    trail = "none"
  )

  geoms <- vapply(out$render$layers, function(layer) layer$geom %||% "", character(1))
  vectors <- out$render$layers[[which(geoms == "boids_velocity_current")]]
  frame_counts <- table(vectors$frame)
  expect_true(all(frame_counts == 4L))
})

test_that("boids display renders predators and attractors as distinct role points", {
  spec <- boids_fixture_spec(n_boids = 4L)
  sim <- boids_fixture_sim(n_boids = 4L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    sim = sim,
    predator_size = 7.5,
    obstacle_mode = "none",
    trail = "none"
  )

  geoms <- vapply(out$render$layers, function(layer) layer$geom %||% "", character(1))
  predator <- out$render$layers[[which(geoms == "boids_predator")]]
  attractor <- out$render$layers[[which(geoms == "boids_attractor")]]
  expect_equal(predator$size, 7.5)
  expect_equal(predator$rows, 1L)
  expect_equal(attractor$rows, 1L)
})

test_that("boids display sampled vectors respect vector_every", {
  spec <- boids_fixture_spec(n_boids = 4L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    vector_mode = "sampled",
    vector_every = 3L,
    obstacle_mode = "none",
    trail = "all"
  )

  vectors <- out$render$layers[[which(vapply(out$render$layers, `[[`, character(1), "type") == "vectors")]]
  expect_equal(vectors$rows, 6L)
  expect_equal(out$render$vector_count, 6L)
})

test_that("boids display obstacle rings are visible line primitives", {
  spec <- boids_fixture_spec(n_boids = 3L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    obstacles = data.frame(
      x = c(0, 0.5),
      y = c(0.1, 0.3),
      radius = c(0.2, 0.15)
    ),
    obstacle_mode = "ring",
    obstacle_segments = 12L,
    trail = "none"
  )

  ring <- out$render$layers[[which(vapply(out$render$layers, function(layer) layer$geom %||% "", character(1)) == "boids_obstacle_ring")]]
  expect_equal(ring$type, "lines")
  expect_equal(ring$path_count, 2L)
  expect_equal(ring$rows, 26L)
  expect_true("lines" %in% out$render$primitives)
  expect_equal(out$render$line_vertex_count, 26L)
})

test_that("boids display obstacle none leaves obstacle primitives out", {
  spec <- boids_fixture_spec(n_boids = 3L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    obstacles = data.frame(x = 0, y = 0, radius = 0.2),
    obstacle_mode = "none",
    trail = "none"
  )

  geoms <- vapply(out$render$layers, function(layer) layer$geom %||% "", character(1))
  expect_false(any(grepl("boids_obstacle", geoms, fixed = TRUE)))
  expect_false("lines" %in% out$render$primitives)
})

test_that("boids display propagates boid size and alpha to point payloads", {
  spec <- boids_fixture_spec(n_boids = 3L)
  out <- ggWebGL:::ggwebgl_boids_apply_display_spec(
    spec,
    obstacle_mode = "none",
    trail = "none",
    boid_size = 4.2,
    boid_alpha = 0.66
  )

  points <- out$render$layers[[which(vapply(out$render$layers, `[[`, character(1), "type") == "points")]]
  rgba <- matrix(points$rgba, ncol = 4L, byrow = TRUE)
  expect_equal(unique(points$size), 4.2)
  expect_equal(unique(rgba[, 4L]), 0.66)
  expect_equal(points$rows, 3L)
})
