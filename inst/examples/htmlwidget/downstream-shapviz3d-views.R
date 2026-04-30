library(htmlwidgets)

load_renderer_and_downstream_packages <- function() {
  if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
  } else if (!requireNamespace("ggWebGL", quietly = TRUE)) {
    stop("ggWebGL is not available. Install the package or run from the repo with pkgload.")
  }

  if (requireNamespace("shapViz3D", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  sibling_repo <- normalizePath("../shapViz3D", winslash = "/", mustWork = FALSE)
  if (requireNamespace("pkgload", quietly = TRUE) && file.exists(file.path(sibling_repo, "DESCRIPTION"))) {
    loaded <- tryCatch({
      if (file.exists(file.path(sibling_repo, "..", "XGeoRTR", "DESCRIPTION"))) {
        pkgload::load_all(
          file.path(sibling_repo, "..", "XGeoRTR"),
          export_all = FALSE,
          helpers = FALSE,
          quiet = TRUE
        )
      }
      pkgload::load_all(sibling_repo, export_all = FALSE, helpers = FALSE, quiet = TRUE)
      requireNamespace("shapViz3D", quietly = TRUE)
    }, error = function(e) {
      FALSE
    })
    if (isTRUE(loaded)) {
      return(invisible(TRUE))
    }
  }

  FALSE
}

locate_shapviz3d_case <- function() {
  installed <- system.file("extdata", "package_user_diffusion_slice.csv", package = "shapViz3D")
  if (nzchar(installed)) {
    return(installed)
  }

  sibling <- normalizePath(
    file.path("..", "shapViz3D", "inst", "extdata", "package_user_diffusion_slice.csv"),
    winslash = "/",
    mustWork = FALSE
  )
  if (file.exists(sibling)) {
    return(sibling)
  }

  NA_character_
}

build_downstream_shapviz3d_case <- function() {
  if (identical(load_renderer_and_downstream_packages(), FALSE)) {
    return(NULL)
  }

  case_path <- locate_shapviz3d_case()
  if (is.na(case_path) || !file.exists(case_path)) {
    return(NULL)
  }

  data <- utils::read.csv(case_path, stringsAsFactors = FALSE)
  shapViz3D::compute_shap3d(
    data = data,
    x_col = "x",
    y_col = "y",
    z_col = "z",
    value_col = "value",
    feature_col = "feature",
    meta = list(
      downstream_case = "diffusion",
      downstream_source = "shapViz3D"
    )
  )
}

downstream_shapviz3d_plots <- function() {
  sv <- build_downstream_shapviz3d_case()
  if (is.null(sv)) {
    return(NULL)
  }

  surface_tbl <- shapViz3D::layout_shap_surface(sv)
  cloud_tbl <- shapViz3D::layout_shap_attribution_cloud(sv, threshold = 0.1)

  surface_plot <- ggplot2::ggplot(
    surface_tbl,
    ggplot2::aes(x = x, y = y, fill = value)
  ) +
    ggWebGL::geom_raster_webgl(interpolate = FALSE) +
    ggplot2::coord_equal() +
    ggplot2::scale_fill_gradient2(
      low = "#20639B",
      mid = "#F7F7F7",
      high = "#D1495B",
      midpoint = 0
    ) +
    ggplot2::labs(
      title = "Downstream raster-compatible field from shapViz3D",
      subtitle = "ggWebGL consumes raster primitives and interaction settings; semantics stay upstream",
      x = "x",
      y = "y",
      fill = "value"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggWebGL::theme_webgl(
      shader = "default",
      interactions = c("pan", "zoom", "hover")
    )

  cloud_plot <- ggplot2::ggplot(
    cloud_tbl,
    ggplot2::aes(
      x = x,
      y = y,
      colour = sign,
      size = radius,
      alpha = weight
    )
  ) +
    ggWebGL::geom_point_webgl() +
    ggplot2::coord_equal() +
    ggplot2::scale_colour_manual(
      values = c(negative = "#20639B", positive = "#D1495B"),
      drop = FALSE
    ) +
    ggplot2::scale_size_continuous(range = c(1.4, 7), guide = "none") +
    ggplot2::scale_alpha_continuous(range = c(0.18, 0.82), guide = "none") +
    ggplot2::labs(
      title = "Downstream point primitives from shapViz3D",
      subtitle = "ggWebGL consumes point primitives with polarity colour, hover, pan, and zoom",
      x = "x",
      y = "y",
      colour = "polarity"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggWebGL::theme_webgl(
      shader = "density_splat",
      interactions = c("pan", "zoom", "hover")
    )

  list(surface = surface_plot, cloud = cloud_plot)
}

downstream_shapviz3d_widgets <- function() {
  plots <- downstream_shapviz3d_plots()
  if (is.null(plots)) {
    return(NULL)
  }

  list(
    surface = ggWebGL::ggplot_webgl(plots$surface, height = 560),
    cloud = ggWebGL::ggplot_webgl(plots$cloud, height = 560)
  )
}

export_downstream_shapviz3d_gallery <- function(output_dir = tempfile("ggwebgl-shapviz3d-gallery-"),
                                                selfcontained = FALSE) {
  widgets <- downstream_shapviz3d_widgets()
  if (is.null(widgets)) {
    return(NULL)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  files <- c(
    surface = file.path(output_dir, "surface.html"),
    cloud = file.path(output_dir, "cloud.html")
  )

  htmlwidgets::saveWidget(widgets$surface, files[["surface"]], selfcontained = selfcontained)
  htmlwidgets::saveWidget(widgets$cloud, files[["cloud"]], selfcontained = selfcontained)
  invisible(files)
}

widgets <- downstream_shapviz3d_widgets()
if (is.null(widgets)) {
  cat("shapViz3D is unavailable; skipping downstream shapViz3D renderer demo.\n")
} else {
  print(widgets$surface)
  print(widgets$cloud)
}
