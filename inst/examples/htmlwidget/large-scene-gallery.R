library(htmlwidgets)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

large_scene_cloud <- function(seed = 2026L, point_count = 120000L) {
  set.seed(seed)
  point_count <- max(100L, as.integer(point_count)[[1L]])
  groups <- c("manifold", "transition", "rare-mode", "background")
  group <- sample(groups, point_count, replace = TRUE, prob = c(0.48, 0.28, 0.14, 0.10))
  x <- numeric(point_count)
  y <- numeric(point_count)

  manifold <- group == "manifold"
  transition <- group == "transition"
  rare_mode <- group == "rare-mode"
  background <- group == "background"

  theta <- stats::runif(sum(manifold), -0.3, 2.45 * pi)
  radius <- 0.45 + 0.12 * theta + stats::rnorm(sum(manifold), sd = 0.05)
  x[manifold] <- cos(theta) * radius - 0.25 + stats::rnorm(sum(manifold), sd = 0.035)
  y[manifold] <- sin(theta) * radius * 0.58 + stats::rnorm(sum(manifold), sd = 0.035)

  t <- stats::runif(sum(transition), -1, 1)
  x[transition] <- 1.15 * t + stats::rnorm(sum(transition), sd = 0.16)
  y[transition] <- 0.65 * sin(t * pi) - 0.28 + stats::rnorm(sum(transition), sd = 0.11)

  x[rare_mode] <- stats::rnorm(sum(rare_mode), mean = 1.45, sd = 0.20)
  y[rare_mode] <- stats::rnorm(sum(rare_mode), mean = 0.62, sd = 0.16)

  x[background] <- stats::runif(sum(background), -1.9, 2.1)
  y[background] <- stats::runif(sum(background), -1.35, 1.35)

  data.frame(
    x = x,
    y = y,
    regime = factor(group, levels = groups),
    stringsAsFactors = FALSE
  )
}

large_scene_facets <- function(seed = 2026L, point_count = 48000L) {
  point_count <- max(400L, as.integer(point_count)[[1L]])
  per_panel <- rep(point_count %/% 4L, 4L)
  per_panel[seq_len(point_count %% 4L)] <- per_panel[seq_len(point_count %% 4L)] + 1L
  panels <- c("raw embedding", "density sharpened", "adapter payload", "static export")

  out <- lapply(seq_along(panels), function(i) {
    data <- large_scene_cloud(seed = seed + i * 17L, point_count = per_panel[[i]])
    data$x <- data$x + c(-0.08, 0.06, 0.02, -0.03)[[i]]
    data$y <- data$y * c(1.04, 0.92, 1.12, 0.98)[[i]]
    data$panel <- panels[[i]]
    data
  })

  do.call(rbind, out)
}

large_scene_hover_data <- function(seed = 2026L, point_count = 24000L, selected_count = 180L) {
  data <- large_scene_cloud(seed = seed, point_count = point_count)
  score <- with(data, abs(x - 1.35) + abs(y - 0.55))
  selected_index <- order(score)[seq_len(min(selected_count, nrow(data)))]
  data$selected <- FALSE
  data$selected[selected_index] <- TRUE
  data$sample <- sprintf("sample-%05d", seq_len(nrow(data)))
  data
}

large_scene_gallery_scenes <- function(seed = 2026L,
                                       point_count = 120000L,
                                       facet_point_count = 48000L,
                                       hover_point_count = 24000L) {
  requireNamespace("ggplot2")

  large_cloud <- large_scene_cloud(seed = seed, point_count = point_count)
  facet_cloud <- large_scene_facets(seed = seed + 11L, point_count = facet_point_count)
  hover_cloud <- large_scene_hover_data(seed = seed + 23L, point_count = hover_point_count)

  selected <- hover_cloud[hover_cloud$selected, , drop = FALSE]
  background <- hover_cloud[!hover_cloud$selected, , drop = FALSE]

  list(
    large_point_cloud = ggplot2::ggplot(large_cloud, ggplot2::aes(x, y, colour = regime)) +
      geom_point_webgl(size = 0.48, alpha = 0.11) +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = "Stable Large Point Cloud",
        subtitle = "Persistent point buffers and count-aware density splats for six-figure 2D scenes",
        x = "embedding axis 1",
        y = "embedding axis 2"
      ) +
      theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover")),
    faceted_density = ggplot2::ggplot(facet_cloud, ggplot2::aes(x, y, colour = regime)) +
      geom_point_webgl(size = 0.52, alpha = 0.12) +
      ggplot2::facet_wrap(~panel, ncol = 2) +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = "Multi-Panel Density Robustness",
        subtitle = "The same renderer contract supports fixed-scale facets for downstream comparison views",
        x = "shared axis 1",
        y = "shared axis 2"
      ) +
      theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover")),
    hover_selection = ggplot2::ggplot() +
      geom_point_webgl(
        data = background,
        mapping = ggplot2::aes(x, y),
        colour = "#7a8797",
        size = 0.55,
        alpha = 0.13
      ) +
      geom_point_webgl(
        data = selected,
        mapping = ggplot2::aes(x, y, colour = regime, label = sample),
        size = 1.7,
        alpha = 0.88
      ) +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = "Hover-Labeled Selected Samples",
        subtitle = "Generic sample labels make dense renderer outputs inspectable without backend semantics",
        x = "embedding axis 1",
        y = "embedding axis 2"
      ) +
      theme_webgl(shader = "default", interactions = c("pan", "zoom", "hover"))
  )
}

write_large_scene_index <- function(output_dir, files) {
  cards <- list(
    large_point_cloud = c(
      "Large-scene demo: six-figure point-cloud stability",
      "Shows persistent point buffers plus count-aware density splats."
    ),
    faceted_density = c(
      "Renderer demo: multi-panel comparison",
      "Shows fixed-scale facets with panel-local pan, zoom, and hover."
    ),
    hover_selection = c(
      "Renderer demo: inspectable selected samples",
      "Shows generic hover labels for downstream adapter payloads."
    )
  )
  html_escape <- function(x) {
    x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    x <- gsub(">", "&gt;", x, fixed = TRUE)
    x <- gsub("\"", "&quot;", x, fixed = TRUE)
    gsub("'", "&#39;", x, fixed = TRUE)
  }
  items <- vapply(names(files), function(name) {
    paste0(
      "<li><a href=\"", html_escape(basename(files[[name]])), "\">",
      html_escape(gsub("_", " ", name, fixed = TRUE)),
      "</a><br><span>", html_escape(cards[[name]][[1L]]), "</span>",
      "<p>", html_escape(cards[[name]][[2L]]), "</p></li>"
    )
  }, character(1))
  index <- file.path(output_dir, "index.html")

  writeLines(c(
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head><meta charset=\"utf-8\"><title>ggWebGL Large-Scene Gallery</title></head>",
    "<body>",
    "<h1>ggWebGL Large-Scene Gallery</h1>",
    "<p>Renderer-generic scenes for large point clouds, density facets, and hover labels.</p>",
    "<ul>",
    items,
    "</ul>",
    "</body>",
    "</html>"
  ), con = index, useBytes = TRUE)

  index
}

export_large_scene_gallery <- function(output_dir = tempfile("ggwebgl-large-scene-"),
                                       selfcontained = FALSE,
                                       point_count = 120000L,
                                       facet_point_count = 48000L,
                                       hover_point_count = 24000L) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  scenes <- large_scene_gallery_scenes(
    point_count = point_count,
    facet_point_count = facet_point_count,
    hover_point_count = hover_point_count
  )
  files <- character(length(scenes))
  names(files) <- names(scenes)

  for (name in names(scenes)) {
    file <- file.path(output_dir, paste0(name, ".html"))
    widget <- ggplot_webgl(scenes[[name]], width = "100%", height = 620)
    htmlwidgets::saveWidget(widget, file = file, selfcontained = selfcontained)
    files[[name]] <- file
  }

  attr(files, "index") <- write_large_scene_index(output_dir, files)
  message("Large-scene renderer gallery written to: ", output_dir)
  invisible(files)
}
