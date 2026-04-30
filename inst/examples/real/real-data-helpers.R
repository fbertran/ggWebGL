real_data_metadata <- function() {
  list(
    volcano_dem = list(
      title = "Topographic Raster Field",
      subtitle = "Texture-backed raster rendering from a real volcano elevation grid",
      use_case = paste(
        "This example shows the raster path on a real scalar field rather than",
        "a synthetic heatmap."
      ),
      reading_hint = paste(
        "Look for smooth elevation transitions and preserved terrain structure",
        "during pan and zoom."
      )
    ),
    storm_tracks = list(
      title = "Observed Storm Trajectories",
      subtitle = "Real cyclone tracks rendered as many-path geographic trajectories",
      use_case = paste(
        "This example positions ggWebGL as a browser-native scientific-visualization",
        "surface for real trajectory bundles."
      ),
      reading_hint = paste(
        "Each path is one historical storm; endpoints and age shading make",
        "direction and convergence legible."
      )
    ),
    dense_embedding = list(
      title = "Dense Real-World Embedding",
      subtitle = "A dense projection built from packaged real feature data",
      use_case = paste(
        "This example answers the dense-point-cloud question with a real",
        "high-volume dataset instead of a synthetic latent space."
      ),
      reading_hint = paste(
        "Dense regions should accumulate without collapsing into a flat blur,",
        "and categorical structure should remain readable."
      )
    ),
    faceted_embedding = list(
      title = "Faceted Dense Embedding",
      subtitle = "Fixed-scale small multiples showing dense points across price bands",
      use_case = paste(
        "This example exercises the new facet path on a real dense point family",
        "instead of using only single-panel scenes."
      ),
      reading_hint = paste(
        "Each panel should render independently, with clipping preserved and",
        "interaction scoped to the hovered panel."
      )
    )
  )
}

real_data_theme <- function(shader = "default") {
  theme_webgl(
    shader = shader,
    interactions = c("pan", "zoom", "hover")
  )
}

real_data_volcano_plot <- function() {
  volcano_dem <- ggwebgl_example_data("volcano_dem")

  ggplot2::ggplot(volcano_dem, ggplot2::aes(x, y, fill = elevation)) +
    geom_raster_webgl(interpolate = TRUE) +
    ggplot2::scale_fill_gradientn(
      colours = grDevices::hcl.colors(12L, "Terrain 2"),
      guide = "none"
    ) +
    ggplot2::coord_equal(expand = FALSE) +
    ggplot2::labs(
      title = real_data_metadata()$volcano_dem$title,
      subtitle = real_data_metadata()$volcano_dem$subtitle,
      x = "Grid x",
      y = "Grid y"
    ) +
    real_data_theme("default")
}

real_data_storm_tracks_plot <- function() {
  storms <- ggwebgl_example_data("storm_tracks")
  storms$timestamp <- as.POSIXct(storms$timestamp, tz = "UTC")
  storms$storm_name <- factor(storms$storm_name)

  end_idx <- ave(
    seq_len(nrow(storms)),
    storms$storm_id,
    FUN = function(idx) idx == max(idx)
  )
  endpoints <- storms[as.logical(end_idx), , drop = FALSE]
  palette <- c(
    "Florence" = "#0f766e",
    "Ida" = "#c2410c",
    "Irma" = "#7c3aed",
    "Katrina" = "#0ea5e9",
    "Sandy" = "#be123c"
  )

  ggplot2::ggplot(storms, ggplot2::aes(lon, lat, group = storm_id, colour = storm_name)) +
    geom_line_webgl(linewidth = 1.2, alpha = 0.72) +
    geom_point_webgl(
      data = endpoints,
      mapping = ggplot2::aes(lon, lat, colour = storm_name),
      size = 2.0,
      alpha = 0.96,
      inherit.aes = FALSE
    ) +
    ggplot2::scale_colour_manual(values = palette, guide = "none") +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = real_data_metadata()$storm_tracks$title,
      subtitle = real_data_metadata()$storm_tracks$subtitle,
      x = "Longitude",
      y = "Latitude"
    ) +
    real_data_theme("trajectory_age")
}

real_data_dense_embedding_plot <- function() {
  embedding <- ggwebgl_example_data("dense_embedding")

  ggplot2::ggplot(embedding, ggplot2::aes(embed_x, embed_y, colour = cut)) +
    geom_point_webgl(size = 1.1, alpha = 0.22) +
    ggplot2::scale_colour_brewer(palette = "Set2", guide = "none") +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = real_data_metadata()$dense_embedding$title,
      subtitle = real_data_metadata()$dense_embedding$subtitle,
      x = "Projection axis 1",
      y = "Projection axis 2"
    ) +
    real_data_theme("density_splat")
}

real_data_faceted_embedding_plot <- function() {
  embedding <- ggwebgl_example_data("dense_embedding")

  ggplot2::ggplot(embedding, ggplot2::aes(embed_x, embed_y, colour = cut)) +
    geom_point_webgl(size = 1.0, alpha = 0.20) +
    ggplot2::scale_colour_brewer(palette = "Set2", guide = "none") +
    ggplot2::coord_equal() +
    ggplot2::facet_wrap(~price_band, nrow = 2) +
    ggplot2::labs(
      title = real_data_metadata()$faceted_embedding$title,
      subtitle = real_data_metadata()$faceted_embedding$subtitle,
      x = "Projection axis 1",
      y = "Projection axis 2"
    ) +
    real_data_theme("density_splat")
}

real_data_plots <- function() {
  list(
    volcano_dem = real_data_volcano_plot(),
    storm_tracks = real_data_storm_tracks_plot(),
    dense_embedding = real_data_dense_embedding_plot(),
    faceted_embedding = real_data_faceted_embedding_plot()
  )
}
