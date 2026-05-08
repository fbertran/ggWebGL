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

build_downstream_boids4r_simulations <- function() {
  if (identical(load_renderer_and_boids4r_packages(), FALSE)) {
    return(NULL)
  }

  list(
    schooling_2d = boids4R::boids_scenario(
      "schooling_2d",
      n = 260L,
      steps = 80L,
      record_every = 2L,
      seed = 2601L
    ),
    murmuration_3d = boids4R::boids_scenario(
      "murmuration_3d",
      n = 360L,
      steps = 90L,
      record_every = 3L,
      seed = 2602L
    )
  )
}

downstream_boids4r_specs <- function() {
  sims <- build_downstream_boids4r_simulations()
  if (is.null(sims)) {
    return(NULL)
  }

  list(
    schooling_2d = boids4R::as_ggwebgl_spec(
      sims$schooling_2d,
      vector_every = 12L,
      vector_scale = 0.13,
      shader = "density_splat"
    ),
    murmuration_3d = boids4R::as_ggwebgl_spec(
      sims$murmuration_3d,
      vector_every = 14L,
      vector_scale = 0.12,
      shader = "default"
    )
  )
}

downstream_boids4r_widgets <- function() {
  specs <- downstream_boids4r_specs()
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

widgets <- downstream_boids4r_widgets()
if (is.null(widgets)) {
  cat("boids4R is unavailable; skipping downstream boids4R animation demo.\n")
} else {
  print(widgets$schooling_2d)
  print(widgets$murmuration_3d)
}
