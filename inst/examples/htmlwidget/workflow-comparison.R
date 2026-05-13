workflow_comparison_data <- function(n = 2400L) {
  n <- as.integer(n)[[1L]]
  if (!is.finite(n) || n <= 0L) {
    stop("`n` must be a positive integer scalar.", call. = FALSE)
  }
  index <- seq_len(n)
  group <- ((index - 1L) %% 4L) + 1L
  angle <- index * 0.031 + group * 0.75
  radius <- 0.25 + (index %% 400L) / 400
  data.frame(
    x = cos(angle) * radius + c(-1.4, 0.2, 1.4, -0.2)[group],
    y = sin(angle) * radius + c(-0.8, 1.0, -0.5, 0.2)[group],
    group = factor(group),
    stringsAsFactors = FALSE
  )
}

workflow_comparison_plot <- function(n = 2400L) {
  data <- workflow_comparison_data(n)
  ggplot2::ggplot(data, ggplot2::aes(x, y, colour = group)) +
    ggplot2::geom_point(size = 0.8, alpha = 0.45) +
    ggplot2::scale_colour_manual(
      values = c("#0f766e", "#f97316", "#2563eb", "#9333ea"),
      guide = "none"
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "Workflow preservation comparison",
      subtitle = "The same ggplot object can be rendered statically or as ggWebGL"
    )
}

workflow_comparison_widget <- function(n = 2400L, height = 420) {
  data <- workflow_comparison_data(n)
  plot <- ggplot2::ggplot(data, ggplot2::aes(x, y, colour = group)) +
    ggWebGL::geom_point_webgl(size = 1.0, alpha = 0.45) +
    ggplot2::scale_colour_manual(
      values = c("#0f766e", "#f97316", "#2563eb", "#9333ea"),
      guide = "none"
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "Workflow preservation comparison",
      subtitle = "The same data mapping rendered as browser-native WebGL"
    ) +
    ggWebGL::theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover"))

  ggWebGL::ggplot_webgl(plot, height = height)
}

workflow_comparison_pair <- function(n = 2400L) {
  list(
    static = workflow_comparison_plot(n),
    webgl = workflow_comparison_widget(n)
  )
}
