#' Convert backend objects to a ggWebGL renderer specification
#'
#' `ggWebGL` exposes a renderer-adapter protocol for converting explicit
#' backend inputs into normalized primitive scenes. Backend-specific methods
#' must resolve semantics before the widget consumes the payload.
#'
#' @param x Input object.
#' @param ... Passed to method-specific implementations.
#'
#' @return A normalized ggWebGL renderer specification.
#'
#' @examples
#' point_layer <- ggwebgl_layer_points(
#'   data.frame(x = c(0, 1), y = c(1, 0)),
#'   x = "x",
#'   y = "y"
#' )
#' spec <- ggwebgl_spec(layers = list(point_layer))
#'
#' as_ggwebgl_spec(spec)
#' @export
as_ggwebgl_spec <- function(x, ...) {
  UseMethod("as_ggwebgl_spec")
}

#' @export
as_ggwebgl_spec.default <- function(x, ...) {
  rlang::abort(
    paste0(
      "No as_ggwebgl_spec() method is available for class ",
      paste(class(x), collapse = "/"),
      "."
    )
  )
}

#' Convert an `xgeo_state` object to a ggWebGL renderer specification
#'
#' @param x An `xgeo_state` object.
#' @param embedding Optional embedding name. Defaults to the active embedding.
#' @param primitive Primitive family to project to renderer payloads.
#' @param lod Optional LOD selector for `primitive = "density"`. Accepts
#'   `NULL`, a single bundle name, a `bundle/level` string, or a list with
#'   `name` and optional `level`.
#' @param webgl Renderer options passed through `normalise_webgl_options()`.
#' @param labels Optional labels list (`title`, `subtitle`, `x`, `y`) that
#'   overrides metadata-derived defaults.
#' @param point_size Point size used for point payloads.
#' @param alpha Alpha used for generated payload colors.
#' @param ... Reserved for future adapters.
#'
#' @return A normalized ggWebGL renderer specification.
#'
#' @examples
#' toy_state <- list(
#'   attributes = list(
#'     embeddings = list(
#'       active = "toy",
#'       items = list(
#'         toy = list(
#'           coords = data.frame(
#'             point_id = paste0("p", 1:4),
#'             dim1 = c(0, 1, 0, 1),
#'             dim2 = c(0, 0, 1, 1)
#'           )
#'         )
#'       )
#'     ),
#'     explanations = data.frame(
#'       point_id = paste0("p", 1:4),
#'       value = c(0.2, 0.4, 0.8, 0.5)
#'     )
#'   ),
#'   metadata = list(title = "Toy backend state")
#' )
#' class(toy_state) <- "xgeo_state"
#'
#' xgeo_spec <- as_ggwebgl_spec(toy_state, primitive = "points")
#' xgeo_spec$render$primitives
#' @export
as_ggwebgl_spec.xgeo_state <- function(x,
                                       embedding = NULL,
                                       primitive = c("points", "density", "surface"),
                                       lod = NULL,
                                       webgl = list(),
                                       labels = list(),
                                       point_size = 4,
                                       alpha = 0.85,
                                       ...) {
  primitive <- match.arg(primitive)

  if (!is.numeric(point_size) || length(point_size) != 1L ||
      !is.finite(point_size) || point_size <= 0) {
    rlang::abort("`point_size` must be a positive numeric scalar.")
  }

  if (!is.numeric(alpha) || length(alpha) != 1L ||
      !is.finite(alpha) || alpha <= 0 || alpha > 1) {
    rlang::abort("`alpha` must be in the interval (0, 1].")
  }

  embeddings <- x$attributes$embeddings$items %||% list()
  active_embedding <- x$attributes$embeddings$active %||% NULL
  embedding_name <- embedding %||% active_embedding

  if (!is.character(embedding_name) || length(embedding_name) != 1L ||
      !(embedding_name %in% names(embeddings))) {
    rlang::abort("Unable to resolve a valid embedding from `xgeo_state`.")
  }

  messages <- character()
  payload <- NULL

  if (identical(primitive, "points")) {
    payload <- xgeo_point_payload_from_state(
      state = x,
      embedding = embedding_name,
      point_size = point_size,
      alpha = alpha
    )
  } else if (identical(primitive, "density")) {
    grid <- xgeo_lod_grid_from_state(x, lod = lod)
    if (is.null(grid)) {
      messages <- c(
        messages,
        "Density primitive requested but no valid LOD bundle/level could be resolved."
      )
    } else {
      payload <- xgeo_raster_payload_from_grid(
        grid = grid,
        geom = "xgeo_state_density",
        alpha = alpha
      )
    }
  } else {
    grid <- xgeo_surface_grid_from_state(x)
    if (is.null(grid)) {
      messages <- c(
        messages,
        paste(
          "Surface primitive currently requires a complete regular x/y grid;",
          "falling back to metadata mode."
        )
      )
    } else {
      payload <- xgeo_raster_payload_from_grid(
        grid = grid,
        geom = "xgeo_state_surface",
        alpha = alpha
      )
      messages <- c(
        messages,
        "Surface primitive is currently projected as a raster payload."
      )
    }
  }

  mode <- if (is.null(payload)) "metadata" else "webgl"
  viewport <- xgeo_viewport_from_payload(payload)

  panel <- compact_list(list(
    panel_id = 1L,
    row = 1L,
    col = 1L,
    bounds = list(left = 0, right = 1, top = 0, bottom = 1),
    viewport = viewport,
    primitives = if (is.null(payload)) character() else payload$type,
    point_count = if (!is.null(payload) && identical(payload$type, "points")) payload$rows else 0L,
    line_vertex_count = 0L,
    path_count = 0L,
    raster_cell_count = if (!is.null(payload) && identical(payload$type, "raster")) payload$rows else 0L,
    layers = if (is.null(payload)) list() else list(payload)
  ))

  render <- add_single_panel_compatibility(compact_list(list(
    mode = mode,
    grid = list(rows = 1L, cols = 1L),
    panels = list(panel),
    primitives = if (is.null(payload)) character() else payload$type,
    point_count = panel$point_count,
    line_vertex_count = 0L,
    path_count = 0L,
    raster_cell_count = panel$raster_cell_count,
    unsupported_layers = list(),
    messages = unname(messages)
  )))

  layer_rows <- if (is.null(payload)) 0L else payload$rows
  layer_primitives <- if (is.null(payload)) character() else payload$type
  layer_mapping <- if (!is.null(payload) && identical(payload$type, "points")) {
    c("x", "y", "value")
  } else if (!is.null(payload) && identical(payload$type, "raster")) {
    c("x", "y", "value")
  } else {
    character()
  }

  compact_list(list(
    package_version = as.character(utils::packageVersion("ggWebGL")),
    labels = xgeo_resolve_labels(labels, metadata = x$metadata %||% list()),
    webgl = normalise_webgl_options(webgl),
    layer_count = 1L,
    layers = list(compact_list(list(
      geom = paste0("xgeo_state_", primitive),
      stat = "identity",
      supported = identical(mode, "webgl"),
      mapping = layer_mapping,
      primitive = layer_primitives,
      rows = as.integer(layer_rows)
    ))),
    render = render
  ))
}

xgeo_point_payload_from_state <- function(state, embedding, point_size, alpha) {
  point_tbl <- xgeo_point_table_from_state(state, embedding)
  rgba <- xgeo_values_to_rgba(point_tbl$value, alpha = alpha)

  compact_list(list(
    panel_id = 1L,
    type = "points",
    geom = "xgeo_state_points",
    rows = nrow(point_tbl),
    x = unname(as.numeric(point_tbl$x)),
    y = unname(as.numeric(point_tbl$y)),
    size = rep(as.numeric(point_size), nrow(point_tbl)),
    age = rep(1, nrow(point_tbl)),
    rgba = unname(as.numeric(t(rgba)))
  ))
}

xgeo_point_table_from_state <- function(state, embedding) {
  coords <- state$attributes$embeddings$items[[embedding]]$coords
  coords <- as.data.frame(coords, stringsAsFactors = FALSE)

  if (!all(c("point_id") %in% names(coords))) {
    rlang::abort("Embedding coordinates must include `point_id`.")
  }

  coord_cols <- setdiff(names(coords), "point_id")
  if (length(coord_cols) < 2L) {
    rlang::abort("Embedding coordinates must include at least two dimensions.")
  }

  out <- data.frame(
    point_id = as.character(coords$point_id),
    x = as.numeric(coords[[coord_cols[[1L]]]]),
    y = as.numeric(coords[[coord_cols[[2L]]]]),
    stringsAsFactors = FALSE
  )

  values <- xgeo_point_values_from_explanations(state$attributes$explanations %||% NULL)
  value_idx <- match(out$point_id, values$point_id)
  out$value <- values$value[value_idx]
  out$value[is.na(out$value)] <- 0

  out
}

xgeo_point_values_from_explanations <- function(explanations) {
  if (is.null(explanations) || !is.data.frame(explanations) ||
      !all(c("point_id", "value") %in% names(explanations)) ||
      nrow(explanations) == 0L) {
    return(data.frame(point_id = character(), value = numeric(), stringsAsFactors = FALSE))
  }

  agg <- stats::aggregate(
    value ~ point_id,
    data = explanations,
    FUN = mean
  )

  agg$point_id <- as.character(agg$point_id)
  agg$value <- as.numeric(agg$value)
  agg
}

xgeo_values_to_rgba <- function(values, alpha = 0.85) {
  values <- as.numeric(values)
  values[!is.finite(values)] <- 0

  if (!length(values)) {
    return(matrix(numeric(), ncol = 4L))
  }

  if (diff(range(values)) == 0) {
    scaled <- rep(0.5, length(values))
  } else {
    scaled <- (values - min(values)) / (max(values) - min(values))
  }

  rgb <- grDevices::colorRamp(c("#2166AC", "#F7F7F7", "#B2182B"))(scaled) / 255

  cbind(
    red = rgb[, 1],
    green = rgb[, 2],
    blue = rgb[, 3],
    alpha = rep(alpha, length(values))
  )
}

xgeo_lod_grid_from_state <- function(state, lod = NULL) {
  lod_items <- state$lod$items %||% list()
  active <- state$lod$active %||% list(name = NULL, level = NULL)
  selector <- xgeo_parse_lod_selector(lod, active_name = active$name, active_level = active$level)

  if (is.null(selector$name) || !(selector$name %in% names(lod_items))) {
    return(NULL)
  }

  bundle <- lod_items[[selector$name]]
  level <- selector$level %||% bundle$default_level
  level <- as.character(level)

  if (!(level %in% names(bundle$levels))) {
    return(NULL)
  }

  bundle$levels[[level]]
}

xgeo_parse_lod_selector <- function(lod, active_name, active_level) {
  if (is.null(lod)) {
    return(list(name = active_name, level = active_level))
  }

  if (is.list(lod)) {
    return(list(
      name = lod$name %||% active_name,
      level = lod$level %||% active_level
    ))
  }

  if (is.character(lod) && length(lod) == 1L) {
    if (grepl("[:/]", lod)) {
      parts <- strsplit(lod, "[:/]")[[1L]]
      return(list(
        name = parts[[1L]],
        level = if (length(parts) >= 2L) parts[[2L]] else active_level
      ))
    }

    return(list(name = lod, level = active_level))
  }

  list(name = active_name, level = active_level)
}

xgeo_surface_grid_from_state <- function(state) {
  points <- state$geometry$points %||% NULL
  if (is.null(points) || !is.data.frame(points) ||
      !all(c("point_id", "x", "y") %in% names(points))) {
    return(NULL)
  }

  values <- xgeo_point_values_from_explanations(state$attributes$explanations %||% NULL)
  points <- as.data.frame(points, stringsAsFactors = FALSE)
  points$point_id <- as.character(points$point_id)

  value_idx <- match(points$point_id, values$point_id)
  points$value <- values$value[value_idx]
  points$value[is.na(points$value)] <- 0

  xgeo_regular_grid_from_points(points[, c("x", "y", "value"), drop = FALSE])
}

xgeo_regular_grid_from_points <- function(points) {
  points$x <- as.numeric(points$x)
  points$y <- as.numeric(points$y)
  points$value <- as.numeric(points$value)

  x_vals <- sort(unique(points$x))
  y_vals <- sort(unique(points$y))

  if (nrow(points) != length(x_vals) * length(y_vals)) {
    return(NULL)
  }

  z <- matrix(NA_real_, nrow = length(x_vals), ncol = length(y_vals))
  for (i in seq_len(nrow(points))) {
    ix <- match(points$x[[i]], x_vals)
    iy <- match(points$y[[i]], y_vals)

    if (is.na(ix) || is.na(iy) || !is.na(z[ix, iy])) {
      return(NULL)
    }

    z[ix, iy] <- points$value[[i]]
  }

  if (anyNA(z)) {
    return(NULL)
  }

  list(x = x_vals, y = y_vals, z = z)
}

xgeo_raster_payload_from_grid <- function(grid, geom, alpha = 0.85) {
  if (is.null(grid) || !all(c("x", "y", "z") %in% names(grid))) {
    return(NULL)
  }

  x_values <- as.numeric(grid$x)
  y_values <- as.numeric(grid$y)
  z_values <- as.numeric(as.vector(grid$z))

  width <- length(x_values)
  height <- length(y_values)
  if (width <= 0L || height <= 0L) {
    return(NULL)
  }

  rgba <- xgeo_values_to_rgba(z_values, alpha = alpha)
  rgba_bytes <- rgba_to_bytes(rgba)

  step_x <- if (width > 1L) stats::median(diff(x_values)) else 1
  step_y <- if (height > 1L) stats::median(diff(y_values)) else 1

  compact_list(list(
    panel_id = 1L,
    type = "raster",
    geom = geom,
    rows = as.integer(width * height),
    width = as.integer(width),
    height = as.integer(height),
    xmin = min(x_values) - step_x / 2,
    xmax = max(x_values) + step_x / 2,
    ymin = min(y_values) - step_y / 2,
    ymax = max(y_values) + step_y / 2,
    interpolate = TRUE,
    rgba = as.integer(rgba_bytes)
  ))
}

xgeo_viewport_from_payload <- function(payload) {
  if (is.null(payload)) {
    return(list(x = c(0, 1), y = c(0, 1)))
  }

  if (identical(payload$type, "points")) {
    return(list(
      x = normalise_range(range(payload$x)),
      y = normalise_range(range(payload$y))
    ))
  }

  if (identical(payload$type, "raster")) {
    return(list(
      x = normalise_range(c(payload$xmin, payload$xmax)),
      y = normalise_range(c(payload$ymin, payload$ymax))
    ))
  }

  list(x = c(0, 1), y = c(0, 1))
}

xgeo_resolve_labels <- function(labels, metadata = list()) {
  if (is.null(labels) || !is.list(labels)) {
    labels <- list()
  }

  compact_list(list(
    title = labels$title %||% metadata$title %||% NULL,
    subtitle = labels$subtitle %||% metadata$subtitle %||% NULL,
    x = labels$x %||% metadata$x %||% NULL,
    y = labels$y %||% metadata$y %||% NULL
  ))
}
