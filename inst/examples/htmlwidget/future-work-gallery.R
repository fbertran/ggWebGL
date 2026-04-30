# Renderer capabilities for ggWebGL.
#
# These examples are renderer-generic. They demonstrate primitive contracts and
# widget behavior without assigning package-specific scientific semantics.

future_work_vector_field_demo <- function(seed = 2026L) {
  set.seed(seed)
  grid <- expand.grid(
    x = seq(-2.2, 2.2, length.out = 19L),
    y = seq(-1.4, 1.4, length.out = 13L)
  )
  grid$u <- with(grid, -y + 0.35 * sin(2 * x))
  grid$v <- with(grid, x + 0.25 * cos(3 * y))
  magnitude <- sqrt(grid$u^2 + grid$v^2)
  scale <- 0.10 / max(magnitude)
  grid$xend <- grid$x + grid$u * scale * magnitude
  grid$yend <- grid$y + grid$v * scale * magnitude
  grid$id <- sprintf("vector-%03d", seq_len(nrow(grid)))
  grid$colour <- grDevices::hcl.colors(64L, "BluYl")[pmax(1L, pmin(64L, round(magnitude / max(magnitude) * 63L) + 1L))]

  layer <- ggwebgl_layer_vectors(
    grid,
    x = "x",
    y = "y",
    xend = "xend",
    yend = "yend",
    colour = "colour",
    alpha = 0.88,
    width = 1.25,
    head_size = 7,
    id = "id"
  )

  ggWebGL(
    ggwebgl_spec(
      list(layer),
      labels = list(title = "Vector arrows"),
      webgl = list(selection = ggwebgl_selection("none"), interactions = c("pan", "zoom", "hover"))
    ),
    height = 420
  )
}

future_work_selection_demo <- function(seed = 2027L, n = 1800L) {
  set.seed(seed)
  cluster <- sample(letters[1:4], n, replace = TRUE)
  centers <- data.frame(
    cluster = letters[1:4],
    cx = c(-1.4, 1.2, -0.4, 1.8),
    cy = c(0.8, 0.6, -1.0, -0.9),
    stringsAsFactors = FALSE
  )
  idx <- match(cluster, centers$cluster)
  points <- data.frame(
    x = stats::rnorm(n, centers$cx[idx], 0.22),
    y = stats::rnorm(n, centers$cy[idx], 0.18),
    id = sprintf("point-%04d", seq_len(n)),
    label = cluster,
    colour = grDevices::hcl.colors(4L, "Dark 3")[idx]
  )

  layer <- ggwebgl_layer_points(
    points,
    x = "x",
    y = "y",
    colour = "colour",
    alpha = 0.42,
    size = 2.4,
    label = "label",
    id = "id"
  )

  ggWebGL(
    ggwebgl_spec(
      list(layer),
      labels = list(title = "Brush/lasso selection"),
      webgl = list(selection = ggwebgl_selection("brush_lasso"), interactions = "hover")
    ),
    height = 420
  )
}

future_work_timeline_demo <- function(seed = 2028L, frames = 12L, n = 160L) {
  set.seed(seed)
  base <- data.frame(
    id = seq_len(n),
    phase = stats::runif(n, 0, 2 * pi),
    radius = stats::runif(n, 0.25, 1.2),
    drift = stats::runif(n, -0.55, 0.55)
  )
  points <- do.call(rbind, lapply(seq_len(frames), function(frame) {
    t <- (frame - 1) / max(1, frames - 1)
    theta <- base$phase + t * 2.4 * pi
    data.frame(
      x = base$radius * cos(theta) + base$drift * t + stats::rnorm(n, 0, 0.012),
      y = base$radius * sin(theta) + 0.55 * sin(t * 2 * pi + base$phase) + stats::rnorm(n, 0, 0.012),
      id = sprintf("particle-%03d", base$id),
      frame = frame,
      colour = grDevices::hcl.colors(frames, "Temps")[frame],
      stringsAsFactors = FALSE
    )
  }))

  layer <- ggwebgl_layer_points(
    points,
    x = "x",
    y = "y",
    colour = "colour",
    alpha = 0.34,
    size = 2,
    id = "id",
    frame = "frame"
  )

  ggWebGL(
    ggwebgl_spec(
      list(layer),
      labels = list(title = "Timeline controls"),
      webgl = list(selection = ggwebgl_selection("none"), interactions = c("pan", "zoom")),
      timeline = ggwebgl_timeline(
        frames = seq_len(frames),
        autoplay = FALSE,
        controls = TRUE,
        filter = "exact"
      )
    ),
    height = 420
  )
}

future_work_3d_camera_demo <- function(seed = 2029L, n = 1600L) {
  set.seed(seed)
  t <- seq(0, 7 * pi, length.out = n)
  points <- data.frame(
    x = cos(t) * (1 + 0.15 * sin(3 * t)) + stats::rnorm(n, 0, 0.018),
    y = sin(t) * (1 + 0.15 * cos(2 * t)) + stats::rnorm(n, 0, 0.018),
    z = seq(-1, 1, length.out = n) + stats::rnorm(n, 0, 0.025),
    colour = grDevices::hcl.colors(n, "Viridis"),
    id = sprintf("helix-%04d", seq_len(n))
  )
  path <- points[seq(1L, n, by = 16L), ]

  point_layer <- ggwebgl_layer_points(
    points,
    x = "x",
    y = "y",
    z = "z",
    colour = "colour",
    alpha = 0.55,
    size = 2.1,
    id = "id"
  )
  line_layer <- ggwebgl_layer_lines(
    path,
    x = "x",
    y = "y",
    z = "z",
    group = "trajectory",
    colour = "#334155",
    alpha = 0.55,
    width = 1.1
  )
  vector_path <- path[seq(1L, nrow(path) - 1L, by = 3L), , drop = FALSE]
  vector_next <- path[match(vector_path$id, path$id) + 1L, , drop = FALSE]
  vector_layer <- ggwebgl_layer_vectors(
    data.frame(
      x = vector_path$x,
      y = vector_path$y,
      z = vector_path$z,
      xend = vector_next$x,
      yend = vector_next$y,
      zend = vector_next$z,
      id = sprintf("helix-vector-%03d", seq_len(nrow(vector_path)))
    ),
    x = "x",
    y = "y",
    z = "z",
    xend = "xend",
    yend = "yend",
    zend = "zend",
    colour = "#0f172a",
    alpha = 0.75,
    width = 1.4,
    head_size = 8,
    id = "id"
  )

  ggWebGL(
    ggwebgl_spec(
      list(line_layer, point_layer, vector_layer),
      labels = list(title = "3D orbit camera with vectors"),
      webgl = list(
        view = ggwebgl_view(
          dimension = "3d",
          projection = "perspective",
          controller = "orbit",
          state = list(yaw = 0.7, pitch = 0.35, distance = 3.4)
        ),
        selection = ggwebgl_selection("none"),
        interactions = c("pan", "zoom", "hover")
      )
    ),
    height = 460
  )
}

future_work_mesh_surface_demo <- function() {
  z <- volcano[seq(1, nrow(volcano), length.out = 24L), seq(1, ncol(volcano), length.out = 32L)]
  layer <- ggwebgl_layer_surface(
    z,
    material = ggwebgl_material(shading = "lambert", ambient = 0.32, diffuse = 0.86, wireframe = TRUE),
    pick_id = sprintf("surface-face-%04d", seq_len((nrow(z) - 1L) * (ncol(z) - 1L) * 2L))
  )

  ggWebGL(
    ggwebgl_spec(
      list(layer),
      labels = list(title = "Lit triangulated surface mesh"),
      webgl = list(
        view = ggwebgl_view(
          dimension = "3d",
          projection = "orthographic",
          controller = "trackball",
          state = list(yaw = -0.45, pitch = 0.7, distance = 3.2)
        ),
        selection = ggwebgl_selection("none"),
        interactions = c("pan", "zoom")
      )
    ),
    height = 460
  )
}

future_work_demo_widgets <- function() {
  list(
    vectors = future_work_vector_field_demo(),
    selection = future_work_selection_demo(),
    timeline = future_work_timeline_demo(),
    camera_3d = future_work_3d_camera_demo(),
    mesh_surface = future_work_mesh_surface_demo()
  )
}

export_future_work_gallery <- function(output_dir = file.path(tempdir(), "ggwebgl-future-work"),
                                       selfcontained = FALSE) {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("The htmlwidgets package is required to export the future-work gallery.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  widgets <- future_work_demo_widgets()
  files <- vapply(names(widgets), function(name) {
    file <- file.path(output_dir, paste0(name, ".html"))
    htmlwidgets::saveWidget(widgets[[name]], file = file, selfcontained = selfcontained)
    file
  }, character(1))

  index <- file.path(output_dir, "index.html")
  writeLines(
    c(
      "<!doctype html>",
      "<html><head><meta charset=\"utf-8\"><title>ggWebGL gallery</title></head><body>",
      "<h1>ggWebGL renderer gallery</h1>",
      "<ul>",
      sprintf("<li><a href=\"%s\">%s</a></li>", basename(files), names(files)),
      "</ul>",
      "</body></html>"
    ),
    con = index
  )

  c(files, index = index)
}
