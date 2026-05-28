load_renderer_and_boids4r_packages <- function() {
  if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
  } else if (!requireNamespace("ggWebGL", quietly = TRUE)) {
    stop("ggWebGL is not available. Install the package or run from the repo with pkgload.")
  }

  if (requireNamespace("boids4R", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  FALSE
}

build_downstream_boids4r_simulations <- function(demo_steps = 240L) {
  if (identical(load_renderer_and_boids4r_packages(), FALSE)) {
    return(NULL)
  }
  demo_steps <- as.integer(demo_steps)

  list(
    schooling_2d = boids4R::boids_scenario(
      "schooling_2d",
      n = 260L,
      steps = demo_steps,
      record_every = 3L,
      seed = 2601L
    ),
    murmuration_3d = boids4R::boids_scenario(
      "murmuration_3d",
      n = 360L,
      steps = demo_steps,
      record_every = 4L,
      seed = 2602L
    )
  )
}

downstream_boids4r_specs <- function(boid_size = 3.6,
                                     prey_size = 4.8,
                                     predator_size = 7.5,
                                     boid_alpha = 0.88,
                                     trail_alpha = 0.18,
                                     vector_mode = c("current", "sampled", "all", "none"),
                                     vector_every = 1L,
                                     vector_scale = NULL,
                                     obstacle_mode = c("ring", "disc", "none"),
                                     obstacle_segments = 48L,
                                     trail = c("recent", "none", "all"),
                                     trail_length = 32L,
                                     shader = "default",
                                     demo_steps = 240L,
                                     fps = 24L,
                                     playback_speed = 1.4) {
  sims <- build_downstream_boids4r_simulations(demo_steps = demo_steps)
  if (is.null(sims)) {
    return(NULL)
  }
  vector_mode <- match.arg(vector_mode)
  obstacle_mode <- match.arg(obstacle_mode)
  trail <- match.arg(trail)
  vector_scale_2d <- if (is.null(vector_scale)) 0.15 else vector_scale
  vector_scale_3d <- if (is.null(vector_scale)) 0.12 else vector_scale

  list(
    schooling_2d = ggWebGL:::ggwebgl_boids_display_spec(
      sims$schooling_2d,
      boid_size = boid_size,
      prey_size = prey_size,
      predator_size = predator_size,
      current_alpha = boid_alpha,
      trail_alpha = trail_alpha,
      vector_mode = vector_mode,
      vector_every = vector_every,
      vector_scale = vector_scale_2d,
      obstacle_mode = obstacle_mode,
      obstacle_segments = obstacle_segments,
      trail = trail,
      trail_length = trail_length,
      shader = shader,
      fps = fps,
      playback_speed = playback_speed
    ),
    murmuration_3d = ggWebGL:::ggwebgl_boids_display_spec(
      sims$murmuration_3d,
      boid_size = max(3, boid_size - 0.2),
      prey_size = prey_size,
      predator_size = predator_size,
      current_alpha = boid_alpha,
      trail_alpha = trail_alpha,
      vector_mode = vector_mode,
      vector_every = vector_every,
      vector_scale = vector_scale_3d,
      obstacle_mode = obstacle_mode,
      obstacle_segments = obstacle_segments,
      trail = trail,
      trail_length = trail_length,
      shader = shader,
      fps = fps,
      playback_speed = playback_speed
    )
  )
}

downstream_boids4r_widgets <- function(...) {
  specs <- downstream_boids4r_specs(...)
  if (is.null(specs)) {
    return(NULL)
  }

  list(
    schooling_2d = ggWebGL::ggWebGL(specs$schooling_2d, height = 500),
    murmuration_3d = ggWebGL::ggWebGL(specs$murmuration_3d, height = 540)
  )
}

export_downstream_boids4r_gallery <- function(output_dir = tempfile("ggwebgl-boids4r-gallery-"),
                                              selfcontained = FALSE) {
  widgets <- downstream_boids4r_widgets()
  if (is.null(widgets)) {
    return(NULL)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  files <- c(
    schooling_2d = file.path(output_dir, "schooling_2d.html"),
    murmuration_3d = file.path(output_dir, "murmuration_3d.html")
  )

  htmlwidgets::saveWidget(widgets$schooling_2d, files[["schooling_2d"]], selfcontained = selfcontained)
  htmlwidgets::saveWidget(widgets$murmuration_3d, files[["murmuration_3d"]], selfcontained = selfcontained)
  invisible(files)
}

if (identical(environment(), globalenv())) {
  widgets <- downstream_boids4r_widgets()
  if (is.null(widgets)) {
    cat("boids4R is unavailable; skipping downstream boids4R animation demo.\n")
  } else {
    print(widgets$schooling_2d)
    print(widgets$murmuration_3d)
  }
}
