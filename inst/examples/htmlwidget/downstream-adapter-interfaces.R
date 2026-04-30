library(htmlwidgets)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

embedding_table_demo <- function(seed = 2026L, n = 1800L) {
  set.seed(seed)
  group <- sample(c("core", "bridge", "halo"), n, replace = TRUE, prob = c(0.55, 0.30, 0.15))
  t <- stats::runif(n, -1, 1)
  data <- data.frame(
    sample_id = sprintf("sample-%04d", seq_len(n)),
    dim1 = t + stats::rnorm(n, sd = 0.18),
    dim2 = sin(t * pi) * 0.55 + stats::rnorm(n, sd = 0.16),
    group = group,
    stringsAsFactors = FALSE
  )
  palette <- c(core = "#0f766e", bridge = "#f97316", halo = "#2563eb")
  data$colour <- unname(palette[data$group])

  structure(list(data = data), class = "embedding_table_demo")
}

as_ggwebgl_spec.embedding_table_demo <- function(x, ...) {
  ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data = x$data,
        x = "dim1",
        y = "dim2",
        colour = "colour",
        alpha = 0.28,
        size = 2.2,
        label = "sample_id"
      )
    ),
    labels = list(
      title = "Adapter Demo: Embedding Table",
      subtitle = "A downstream method provides renderer-ready point primitives",
      x = "dimension 1",
      y = "dimension 2"
    ),
    webgl = list(shader = "density_splat", interactions = c("pan", "zoom", "hover"))
  )
}

path_bundle_demo <- function(seed = 2026L, paths = 18L, steps = 90L) {
  set.seed(seed)
  path_id <- rep(seq_len(paths), each = steps)
  time <- rep(seq(0, 1, length.out = steps), times = paths)
  phase <- rep(stats::runif(paths, 0, 2 * pi), each = steps)
  drift <- rep(stats::rnorm(paths, sd = 0.18), each = steps)
  data <- data.frame(
    path_id = path_id,
    x = time * 2 - 1 + drift + 0.12 * sin(time * 4 * pi + phase),
    y = cos(time * 2 * pi + phase) * (1 - time * 0.35) + stats::rnorm(paths * steps, sd = 0.025),
    age = time,
    stringsAsFactors = FALSE
  )

  structure(list(data = data), class = "path_bundle_demo")
}

as_ggwebgl_spec.path_bundle_demo <- function(x, ...) {
  ggwebgl_spec(
    layers = list(
      ggwebgl_layer_lines(
        data = x$data,
        x = "x",
        y = "y",
        group = "path_id",
        colour = "#0f766e",
        alpha = 0.36,
        width = 1.4,
        age = "age"
      )
    ),
    labels = list(
      title = "Adapter Demo: Path Bundle",
      subtitle = "A downstream method provides grouped line primitives",
      x = "state dimension 1",
      y = "state dimension 2"
    ),
    webgl = list(shader = "trajectory_age", interactions = c("pan", "zoom", "hover"))
  )
}

raster_field_demo <- function(nx = 80L, ny = 54L) {
  x <- seq(-2, 2, length.out = nx)
  y <- seq(-1.35, 1.35, length.out = ny)
  grid <- expand.grid(x = x, y = y)
  z <- with(grid, sin(x * 2.8) * cos(y * 3.4) + exp(-((x - 0.7)^2 + (y + 0.2)^2) * 2.4))
  scaled <- (z - min(z)) / diff(range(z))
  rgba <- grDevices::colorRamp(c("#0f172a", "#2dd4bf", "#f8fafc", "#f97316"))(scaled)
  rgba <- cbind(rgba, alpha = 235)

  structure(
    list(
      rgba = as.integer(t(rgba)),
      width = nx,
      height = ny,
      xmin = min(x),
      xmax = max(x),
      ymin = min(y),
      ymax = max(y)
    ),
    class = "raster_field_demo"
  )
}

as_ggwebgl_spec.raster_field_demo <- function(x, ...) {
  ggwebgl_spec(
    layers = list(
      ggwebgl_layer_raster(
        rgba = x$rgba,
        width = x$width,
        height = x$height,
        xmin = x$xmin,
        xmax = x$xmax,
        ymin = x$ymin,
        ymax = x$ymax,
        interpolate = TRUE
      )
    ),
    labels = list(
      title = "Adapter Demo: Raster Field",
      subtitle = "A downstream method provides texture-ready RGBA bytes",
      x = "field x",
      y = "field y"
    ),
    webgl = list(shader = "default", interactions = c("pan", "zoom", "hover"))
  )
}

register_downstream_adapter_demo_methods <- function() {
  registerS3method(
    "as_ggwebgl_spec",
    "embedding_table_demo",
    as_ggwebgl_spec.embedding_table_demo,
    envir = asNamespace("ggWebGL")
  )
  registerS3method(
    "as_ggwebgl_spec",
    "path_bundle_demo",
    as_ggwebgl_spec.path_bundle_demo,
    envir = asNamespace("ggWebGL")
  )
  registerS3method(
    "as_ggwebgl_spec",
    "raster_field_demo",
    as_ggwebgl_spec.raster_field_demo,
    envir = asNamespace("ggWebGL")
  )
  invisible(TRUE)
}

register_downstream_adapter_demo_methods()

downstream_adapter_demo_objects <- function() {
  list(
    embedding_table = embedding_table_demo(),
    path_bundle = path_bundle_demo(),
    raster_field = raster_field_demo()
  )
}

export_downstream_adapter_gallery <- function(output_dir = tempfile("ggwebgl-adapter-gallery-"),
                                              selfcontained = FALSE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  objects <- downstream_adapter_demo_objects()
  files <- character(length(objects))
  names(files) <- names(objects)

  for (name in names(objects)) {
    file <- file.path(output_dir, paste0(name, ".html"))
    widget <- ggWebGL(objects[[name]], width = "100%", height = 560)
    htmlwidgets::saveWidget(widget, file = file, selfcontained = selfcontained)
    files[[name]] <- file
  }

  index <- file.path(output_dir, "index.html")
  links <- sprintf("<li><a href=\"%s\">%s</a></li>", basename(files), names(files))
  writeLines(c(
    "<!doctype html>",
    "<html>",
    "<head><meta charset=\"utf-8\"><title>ggWebGL downstream adapter demos</title></head>",
    "<body>",
    "<h1>ggWebGL downstream adapter demos</h1>",
    "<p>Renderer-generic examples for point, line, and raster adapter methods.</p>",
    "<ul>",
    links,
    "</ul>",
    "</body>",
    "</html>"
  ), con = index, useBytes = TRUE)

  attr(files, "index") <- index
  invisible(files)
}
