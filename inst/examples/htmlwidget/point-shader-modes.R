point_shader_mode_data <- function(seed = 2026L, n = 3000L) {
  set.seed(seed)
  groups <- c("core", "bridge", "halo")
  group <- sample(groups, n, replace = TRUE, prob = c(0.50, 0.30, 0.20))
  x <- numeric(n)
  y <- numeric(n)

  core <- group == "core"
  bridge <- group == "bridge"
  halo <- group == "halo"

  x[core] <- stats::rnorm(sum(core), mean = -0.7, sd = 0.28)
  y[core] <- stats::rnorm(sum(core), mean = 0.2, sd = 0.22)

  t <- stats::runif(sum(bridge), -1, 1)
  x[bridge] <- t + stats::rnorm(sum(bridge), sd = 0.12)
  y[bridge] <- sin(t * pi) * 0.45 + stats::rnorm(sum(bridge), sd = 0.10)

  angle <- stats::runif(sum(halo), 0, 2 * pi)
  radius <- stats::rnorm(sum(halo), mean = 1.25, sd = 0.18)
  x[halo] <- cos(angle) * radius + 0.55
  y[halo] <- sin(angle) * radius * 0.55 - 0.15

  data.frame(
    x = x,
    y = y,
    group = factor(group, levels = groups),
    stringsAsFactors = FALSE
  )
}

point_shader_mode_examples <- function(seed = 2026L) {
  requireNamespace("ggplot2")
  modes <- c("default", "density_splat", "trajectory_age", "trajectory_age_glow")
  data <- point_shader_mode_data(seed = seed)

  stats::setNames(lapply(modes, function(mode) {
    ggplot2::ggplot(data, ggplot2::aes(x, y, colour = group)) +
      geom_point_webgl(size = 1.05, alpha = 0.30) +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = paste("Point shader mode:", mode),
        subtitle = "Same deterministic point cloud rendered through each point shader mode",
        x = "Embedding axis 1",
        y = "Embedding axis 2"
      ) +
      theme_webgl(shader = mode, interactions = c("pan", "zoom", "hover"))
  }), modes)
}

export_point_shader_mode_gallery <- function(output_dir = tempfile("ggwebgl-point-shaders-"),
                                             selfcontained = FALSE) {
  requireNamespace("htmlwidgets")

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  examples <- point_shader_mode_examples()

  files <- Map(function(name, plot) {
    widget <- ggplot_webgl(plot, width = "100%", height = 640)
    path <- file.path(output_dir, paste0(name, ".html"))
    htmlwidgets::saveWidget(widget, file = path, selfcontained = selfcontained)
    path
  }, names(examples), examples)

  index <- file.path(output_dir, "index.html")
  links <- paste(
    sprintf('<li><a href="%s">%s</a></li>', basename(unlist(files)), names(examples)),
    collapse = "\n"
  )
  writeLines(c(
    "<!doctype html>",
    "<html>",
    "<head><meta charset=\"utf-8\"><title>ggWebGL point shader modes</title></head>",
    "<body>",
    "<h1>ggWebGL point shader modes</h1>",
    "<p>Regression gallery for default, density_splat, trajectory_age, and trajectory_age_glow.</p>",
    "<ul>",
    links,
    "</ul>",
    "</body>",
    "</html>"
  ), index)

  files <- unname(unlist(files))
  attr(files, "index") <- index
  files
}
