embedding_cloud_data <- function(point_count = 1000000L) {
  point_count <- as.integer(point_count)[[1L]]
  if (!is.finite(point_count) || point_count <= 0L) {
    stop("`point_count` must be a positive integer scalar.", call. = FALSE)
  }

  index <- seq_len(point_count)
  cluster <- ((index - 1L) %% 8L) + 1L
  center_x <- c(-4.2, -2.3, -0.9, 0.7, 2.2, 3.8, -3.2, 1.8)
  center_y <- c(-1.7, 1.5, -0.4, 2.2, -1.1, 1.1, 2.8, -2.5)
  scale_x <- c(0.48, 0.72, 0.52, 0.86, 0.56, 0.62, 0.44, 0.70)
  scale_y <- c(0.32, 0.44, 0.30, 0.52, 0.38, 0.34, 0.40, 0.46)
  angle <- c(0.15, -0.65, 0.80, -0.35, 0.55, -0.95, 1.15, -1.25)

  fract <- function(x) x - floor(x)
  u1 <- pmax(fract(sin(index * 12.9898) * 43758.5453), 1e-7)
  u2 <- fract(sin(index * 78.233 + 11.135) * 24634.6345)
  radius <- sqrt(-2 * log(u1))
  theta <- 2 * pi * u2 + angle[cluster]
  bridge <- sin(index * 0.0009)

  data.frame(
    x = center_x[cluster] + scale_x[cluster] * radius * cos(theta) + 0.35 * bridge,
    y = center_y[cluster] + scale_y[cluster] * radius * sin(theta) + 0.25 * cos(index * 0.0011),
    cluster = factor(cluster),
    stringsAsFactors = FALSE
  )
}

embedding_widget <- function(point_count = 1000000L,
                             height = 620,
                             shader = "density_splat",
                             brush = TRUE,
                             transport_threshold = 100000L) {
  data <- embedding_cloud_data(point_count)
  interactions <- ggWebGL::ggwebgl_interactions(
    hover = FALSE,
    click = FALSE,
    brush = isTRUE(brush),
    lasso = FALSE,
    camera = TRUE,
    shiny = TRUE
  )
  selection <- if (isTRUE(brush)) {
    ggWebGL::ggwebgl_selection(mode = "brush", highlight = TRUE, emit = TRUE)
  } else {
    ggWebGL::ggwebgl_selection(mode = "none")
  }

  plot <- ggplot2::ggplot(data, ggplot2::aes(x, y, colour = cluster)) +
    ggWebGL::geom_point_webgl(size = 1.05, alpha = 0.42) +
    ggplot2::scale_colour_manual(
      values = c("#0f766e", "#e76f51", "#457b9d", "#e9c46a", "#8d5cf6", "#d1495b", "#0891b2", "#b45309"),
      guide = "none"
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "Million-point embedding",
      subtitle = "Manual dense-scene demo with compact transport and brush selection"
    ) +
    ggWebGL::theme_webgl(
      shader = shader,
      interactions_spec = interactions,
      selection = selection,
      transport = ggWebGL::ggwebgl_transport(
        mode = "auto",
        threshold = transport_threshold,
        progressive = "auto",
        chunk_size = 100000L,
        colors = "auto",
        lod = "auto"
      )
    )

  ggWebGL::ggplot_webgl(plot, height = height)
}

run_manual_million_point_embedding <- function(output = tempfile(fileext = ".html"),
                                               point_count = 1000000L,
                                               browse = interactive(),
                                               selfcontained = FALSE) {
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  if (!dir.exists(dirname(output))) {
    stop("The parent directory for `output` does not exist: ", dirname(output), call. = FALSE)
  }

  htmlwidgets::saveWidget(
    embedding_widget(point_count = point_count),
    file = output,
    selfcontained = selfcontained
  )

  if (isTRUE(browse)) {
    utils::browseURL(output)
  }

  invisible(output)
}
