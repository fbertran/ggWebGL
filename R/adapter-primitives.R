#' Renderer-Ready Point Layer
#'
#' Build a normalized point layer for downstream adapters. Inputs must already
#' represent renderer coordinates and styling; package-specific semantics should
#' be resolved before calling this helper.
#'
#' @param data Optional data frame supplying columns referenced by other
#'   arguments.
#' @param x,y Coordinate vectors or column names in `data`.
#' @param z Optional z coordinate vector or column name for 3D scenes.
#' @param colour Optional colour vector or column name. Ignored when `rgba` is
#'   supplied.
#' @param rgba Optional renderer-ready RGBA matrix/data frame with four columns,
#'   or vector of length `n * 4`, using values in `[0, 1]` or `[0, 255]`.
#' @param alpha Optional alpha vector or column name used with `colour`.
#' @param size Optional point-size vector or column name in renderer pixels.
#' @param age Optional normalized age vector or column name in `[0, 1]`.
#' @param label Optional hover label vector or column name.
#' @param id Optional stable primitive id vector or column name for selection.
#' @param frame,time Optional timeline frame or time vector or column name.
#' @param panel_id Scalar panel identifier for this layer.
#' @param geom Debug geom name recorded in the payload.
#'
#' @return A normalized point layer list.
#'
#' @examples
#' points <- data.frame(
#'   x = c(0, 1, 2),
#'   y = c(2, 1, 0),
#'   colour = c("#0f766e", "#f97316", "#2563eb"),
#'   label = c("a", "b", "c")
#' )
#'
#' ggwebgl_layer_points(
#'   points,
#'   x = "x",
#'   y = "y",
#'   colour = "colour",
#'   alpha = 0.6,
#'   size = 3,
#'   label = "label"
#' )
#' @export
ggwebgl_layer_points <- function(data,
                                 x,
                                 y,
                                 z = NULL,
                                 colour = NULL,
                                 rgba = NULL,
                                 alpha = NULL,
                                 size = NULL,
                                 age = NULL,
                                 label = NULL,
                                 id = NULL,
                                 frame = NULL,
                                 time = NULL,
                                 panel_id = 1L,
                                 geom = "adapter_points") {
  data <- ggwebgl_adapter_data(data)
  env <- parent.frame()
  xs <- ggwebgl_resolve_arg(data, substitute(x), env, "x", required = TRUE)
  ys <- ggwebgl_resolve_arg(data, substitute(y), env, "y", required = TRUE)
  zs <- ggwebgl_resolve_arg(data, substitute(z), env, "z", default = NULL)
  n <- ggwebgl_common_length(x = xs, y = ys)

  xs <- ggwebgl_recycle(xs, n, "x")
  ys <- ggwebgl_recycle(ys, n, "y")
  zs <- if (is.null(zs)) NULL else ggwebgl_recycle(zs, n, "z")
  alpha_values <- ggwebgl_resolve_arg(data, substitute(alpha), env, "alpha", default = NULL)
  colour_values <- ggwebgl_resolve_arg(data, substitute(colour), env, "colour", default = NULL)
  rgba_values <- ggwebgl_resolve_arg(data, substitute(rgba), env, "rgba", default = NULL)
  size_values <- ggwebgl_resolve_arg(data, substitute(size), env, "size", default = NULL)
  age_values <- ggwebgl_resolve_arg(data, substitute(age), env, "age", default = NULL)
  label_values <- ggwebgl_resolve_arg(data, substitute(label), env, "label", default = NULL)
  id_values <- ggwebgl_resolve_arg(data, substitute(id), env, "id", default = NULL)
  frame_values <- ggwebgl_resolve_arg(data, substitute(frame), env, "frame", default = NULL)
  time_values <- ggwebgl_resolve_arg(data, substitute(time), env, "time", default = NULL)

  rgba_matrix <- ggwebgl_resolve_rgba(rgba_values, colour_values, alpha_values, n)
  size_values <- ggwebgl_recycle(size_values %||% 4, n, "size")
  age_values <- ggwebgl_recycle(age_values %||% 1, n, "age")
  label_values <- if (is.null(label_values)) NULL else as.character(ggwebgl_recycle(label_values, n, "label"))
  id_values <- if (is.null(id_values)) NULL else as.character(ggwebgl_recycle(id_values, n, "id"))
  frame_values <- if (is.null(frame_values)) NULL else as.integer(ggwebgl_recycle(frame_values, n, "frame"))
  time_values <- if (is.null(time_values)) NULL else as.numeric(ggwebgl_recycle(time_values, n, "time"))

  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "points",
    geom = as.character(geom)[[1L]],
    rows = as.integer(n),
    x = unname(as.numeric(xs)),
    y = unname(as.numeric(ys)),
    z = if (is.null(zs)) NULL else unname(as.numeric(zs)),
    size = unname(as.numeric(size_values)),
    age = pmax(0, pmin(1, unname(as.numeric(age_values)))),
    label = unname(label_values),
    id = unname(id_values),
    frame = unname(frame_values),
    time = unname(time_values),
    rgba = unname(as.numeric(t(rgba_matrix)))
  ))
}

#' Renderer-Ready Line Layer
#'
#' Build a normalized line layer for downstream adapters.
#'
#' @inheritParams ggwebgl_layer_points
#' @param group Optional path-group vector or column name. When omitted, all rows
#'   form one path.
#' @param width Optional line-width vector or column name in renderer pixels.
#'
#' @return A normalized line layer list.
#'
#' @examples
#' lines <- data.frame(
#'   x = c(0, 1, 2, 0, 1, 2),
#'   y = c(0, 1, 0, 1, 2, 1),
#'   group = c("a", "a", "a", "b", "b", "b")
#' )
#'
#' ggwebgl_layer_lines(
#'   lines,
#'   x = "x",
#'   y = "y",
#'   group = "group",
#'   colour = "#334155",
#'   alpha = 0.75,
#'   width = 2
#' )
#' @export
ggwebgl_layer_lines <- function(data,
                                x,
                                y,
                                z = NULL,
                                group = NULL,
                                colour = NULL,
                                rgba = NULL,
                                alpha = NULL,
                                width = NULL,
                                age = NULL,
                                frame = NULL,
                                time = NULL,
                                panel_id = 1L,
                                geom = "adapter_lines") {
  data <- ggwebgl_adapter_data(data)
  env <- parent.frame()
  xs <- ggwebgl_resolve_arg(data, substitute(x), env, "x", required = TRUE)
  ys <- ggwebgl_resolve_arg(data, substitute(y), env, "y", required = TRUE)
  zs <- ggwebgl_resolve_arg(data, substitute(z), env, "z", default = NULL)
  n <- ggwebgl_common_length(x = xs, y = ys)

  xs <- ggwebgl_recycle(xs, n, "x")
  ys <- ggwebgl_recycle(ys, n, "y")
  zs <- if (is.null(zs)) NULL else ggwebgl_recycle(zs, n, "z")
  group_values <- ggwebgl_resolve_arg(data, substitute(group), env, "group", default = NULL)
  colour_values <- ggwebgl_resolve_arg(data, substitute(colour), env, "colour", default = NULL)
  rgba_values <- ggwebgl_resolve_arg(data, substitute(rgba), env, "rgba", default = NULL)
  alpha_values <- ggwebgl_resolve_arg(data, substitute(alpha), env, "alpha", default = NULL)
  width_values <- ggwebgl_resolve_arg(data, substitute(width), env, "width", default = NULL)
  age_values <- ggwebgl_resolve_arg(data, substitute(age), env, "age", default = NULL)
  frame_values <- ggwebgl_resolve_arg(data, substitute(frame), env, "frame", default = NULL)
  time_values <- ggwebgl_resolve_arg(data, substitute(time), env, "time", default = NULL)

  group_values <- ggwebgl_recycle(group_values %||% "path", n, "group")
  width_values <- ggwebgl_recycle(width_values %||% 1.5, n, "width")
  rgba_matrix <- ggwebgl_resolve_rgba(rgba_values, colour_values, alpha_values, n)
  group_chr <- as.character(group_values)
  group_levels <- unique(group_chr)

  paths <- lapply(group_levels, function(group_name) {
    idx <- which(group_chr == group_name)
    path_age <- if (is.null(age_values)) {
      if (length(idx) <= 1L) {
        rep(1, length(idx))
      } else {
        seq(0, 1, length.out = length(idx))
      }
    } else {
      pmax(0, pmin(1, as.numeric(ggwebgl_recycle(age_values, n, "age")[idx])))
    }
    path_frame <- if (is.null(frame_values)) NULL else as.integer(ggwebgl_recycle(frame_values, n, "frame")[idx])
    path_time <- if (is.null(time_values)) NULL else as.numeric(ggwebgl_recycle(time_values, n, "time")[idx])

    compact_list(list(
      rows = as.integer(length(idx)),
      group = group_name,
      x = unname(as.numeric(xs[idx])),
      y = unname(as.numeric(ys[idx])),
      z = if (is.null(zs)) NULL else unname(as.numeric(zs[idx])),
      width = as.numeric(width_values[idx][[1L]]),
      age = unname(path_age),
      frame = unname(path_frame),
      time = unname(path_time),
      rgba = unname(as.numeric(t(rgba_matrix[idx, , drop = FALSE])))
    ))
  })

  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "lines",
    geom = as.character(geom)[[1L]],
    rows = as.integer(sum(vapply(paths, `[[`, integer(1), "rows"))),
    path_count = as.integer(length(paths)),
    paths = paths
  ))
}

#' Renderer-Ready Vector Arrow Layer
#'
#' Build a vector-arrow layer for downstream adapters.
#'
#' @inheritParams ggwebgl_layer_points
#' @param xend,yend Arrow endpoint coordinates.
#' @param zend Optional arrow endpoint z coordinate for 3D scenes. When `z` or
#'   `zend` is omitted it defaults to zero in 3D projection.
#' @param width Optional shaft width in renderer pixels.
#' @param head_size Optional arrowhead size in renderer pixels.
#'
#' @return A normalized vector layer list.
#'
#' @examples
#' arrows <- data.frame(x = 0:1, y = 0:1, xend = c(0.5, 1.4), yend = c(0.2, 1.2))
#' ggwebgl_layer_vectors(arrows, x = "x", y = "y", xend = "xend", yend = "yend")
#' @export
ggwebgl_layer_vectors <- function(data,
                                  x,
                                  y,
                                  xend,
                                  yend,
                                  z = NULL,
                                  zend = NULL,
                                  colour = NULL,
                                  rgba = NULL,
                                  alpha = NULL,
                                  width = NULL,
                                  head_size = NULL,
                                  id = NULL,
                                  frame = NULL,
                                  time = NULL,
                                  panel_id = 1L,
                                  geom = "adapter_vectors") {
  data <- ggwebgl_adapter_data(data)
  env <- parent.frame()
  xs <- ggwebgl_resolve_arg(data, substitute(x), env, "x", required = TRUE)
  ys <- ggwebgl_resolve_arg(data, substitute(y), env, "y", required = TRUE)
  xends <- ggwebgl_resolve_arg(data, substitute(xend), env, "xend", required = TRUE)
  yends <- ggwebgl_resolve_arg(data, substitute(yend), env, "yend", required = TRUE)
  zs <- ggwebgl_resolve_arg(data, substitute(z), env, "z", default = NULL)
  zends <- ggwebgl_resolve_arg(data, substitute(zend), env, "zend", default = NULL)
  n <- ggwebgl_common_length(x = xs, y = ys, xend = xends, yend = yends)

  xs <- ggwebgl_recycle(xs, n, "x")
  ys <- ggwebgl_recycle(ys, n, "y")
  xends <- ggwebgl_recycle(xends, n, "xend")
  yends <- ggwebgl_recycle(yends, n, "yend")
  zs <- if (is.null(zs)) NULL else ggwebgl_recycle(zs, n, "z")
  zends <- if (is.null(zends)) NULL else ggwebgl_recycle(zends, n, "zend")
  colour_values <- ggwebgl_resolve_arg(data, substitute(colour), env, "colour", default = NULL)
  rgba_values <- ggwebgl_resolve_arg(data, substitute(rgba), env, "rgba", default = NULL)
  alpha_values <- ggwebgl_resolve_arg(data, substitute(alpha), env, "alpha", default = NULL)
  width_values <- ggwebgl_resolve_arg(data, substitute(width), env, "width", default = NULL)
  head_values <- ggwebgl_resolve_arg(data, substitute(head_size), env, "head_size", default = NULL)
  id_values <- ggwebgl_resolve_arg(data, substitute(id), env, "id", default = NULL)
  frame_values <- ggwebgl_resolve_arg(data, substitute(frame), env, "frame", default = NULL)
  time_values <- ggwebgl_resolve_arg(data, substitute(time), env, "time", default = NULL)

  rgba_matrix <- ggwebgl_resolve_rgba(rgba_values, colour_values, alpha_values, n)
  width_values <- ggwebgl_recycle(width_values %||% 1.5, n, "width")
  head_values <- ggwebgl_recycle(head_values %||% 8, n, "head_size")
  id_values <- if (is.null(id_values)) NULL else as.character(ggwebgl_recycle(id_values, n, "id"))
  frame_values <- if (is.null(frame_values)) NULL else as.integer(ggwebgl_recycle(frame_values, n, "frame"))
  time_values <- if (is.null(time_values)) NULL else as.numeric(ggwebgl_recycle(time_values, n, "time"))

  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "vectors",
    geom = as.character(geom)[[1L]],
    rows = as.integer(n),
    x = unname(as.numeric(xs)),
    y = unname(as.numeric(ys)),
    z = if (is.null(zs)) NULL else unname(as.numeric(zs)),
    xend = unname(as.numeric(xends)),
    yend = unname(as.numeric(yends)),
    zend = if (is.null(zends)) NULL else unname(as.numeric(zends)),
    width = unname(as.numeric(width_values)),
    head_size = unname(as.numeric(head_values)),
    id = unname(id_values),
    frame = unname(frame_values),
    time = unname(time_values),
    rgba = unname(as.numeric(t(rgba_matrix)))
  ))
}

ggwebgl_layer_rects <- function(data = NULL,
                                xmin = NULL,
                                xmax = NULL,
                                ymin = NULL,
                                ymax = NULL,
                                fill = NULL,
                                colour = NULL,
                                rgba = NULL,
                                alpha = NULL,
                                linewidth = NULL,
                                count = NULL,
                                density = NULL,
                                frame = NULL,
                                time = NULL,
                                panel_id = 1L,
                                geom = "adapter_rects") {
  data <- ggwebgl_adapter_data(data)
  env <- parent.frame()
  xmins <- ggwebgl_resolve_arg(data, substitute(xmin), env, "xmin", required = TRUE)
  xmaxs <- ggwebgl_resolve_arg(data, substitute(xmax), env, "xmax", required = TRUE)
  ymins <- ggwebgl_resolve_arg(data, substitute(ymin), env, "ymin", required = TRUE)
  ymaxs <- ggwebgl_resolve_arg(data, substitute(ymax), env, "ymax", required = TRUE)
  n <- ggwebgl_rect_common_length(xmin = xmins, xmax = xmaxs, ymin = ymins, ymax = ymaxs)

  xmins <- ggwebgl_recycle(xmins, n, "xmin")
  xmaxs <- ggwebgl_recycle(xmaxs, n, "xmax")
  ymins <- ggwebgl_recycle(ymins, n, "ymin")
  ymaxs <- ggwebgl_recycle(ymaxs, n, "ymax")

  xmins <- unname(as.numeric(xmins))
  xmaxs <- unname(as.numeric(xmaxs))
  ymins <- unname(as.numeric(ymins))
  ymaxs <- unname(as.numeric(ymaxs))

  if (any(!is.finite(c(xmins, xmaxs, ymins, ymaxs)))) {
    rlang::abort("Rectangle bounds must be finite numeric values.")
  }
  if (any(xmins > xmaxs) || any(ymins > ymaxs)) {
    rlang::abort("Rectangle bounds must satisfy `xmin <= xmax` and `ymin <= ymax`.")
  }

  fill_values <- ggwebgl_resolve_arg(data, substitute(fill), env, "fill", default = NULL)
  colour_values <- ggwebgl_resolve_arg(data, substitute(colour), env, "colour", default = NULL)
  rgba_values <- ggwebgl_resolve_arg(data, substitute(rgba), env, "rgba", default = NULL)
  alpha_values <- ggwebgl_resolve_arg(data, substitute(alpha), env, "alpha", default = NULL)
  linewidth_values <- ggwebgl_resolve_arg(data, substitute(linewidth), env, "linewidth", default = NULL)
  count_values <- ggwebgl_resolve_arg(data, substitute(count), env, "count", default = NULL)
  density_values <- ggwebgl_resolve_arg(data, substitute(density), env, "density", default = NULL)
  frame_values <- ggwebgl_resolve_arg(data, substitute(frame), env, "frame", default = NULL)
  time_values <- ggwebgl_resolve_arg(data, substitute(time), env, "time", default = NULL)

  rgba_matrix <- if (n) {
    ggwebgl_resolve_rgba(rgba_values, fill_values, alpha_values, n)
  } else {
    matrix(numeric(), ncol = 4L)
  }
  stroke_matrix <- if (!is.null(colour_values) && n) {
    ggwebgl_resolve_rgba(NULL, colour_values, alpha_values, n)
  } else {
    NULL
  }
  linewidth_values <- ggwebgl_recycle(linewidth_values %||% if (!is.null(stroke_matrix)) 1 else 0, n, "linewidth")
  count_values <- if (is.null(count_values)) NULL else as.numeric(ggwebgl_recycle(count_values, n, "count"))
  density_values <- if (is.null(density_values)) NULL else as.numeric(ggwebgl_recycle(density_values, n, "density"))
  frame_values <- if (is.null(frame_values)) NULL else as.integer(ggwebgl_recycle(frame_values, n, "frame"))
  time_values <- if (is.null(time_values)) NULL else as.numeric(ggwebgl_recycle(time_values, n, "time"))

  # Internal rectangle payloads are first-class `rects` primitives. The current
  # renderer draws filled quads as two triangles; stroke metadata is serialized
  # now so later public rectangle geoms can add outline rendering without a
  # payload contract change.
  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "rects",
    geom = as.character(geom)[[1L]],
    rows = as.integer(n),
    xmin = xmins,
    xmax = xmaxs,
    ymin = ymins,
    ymax = ymaxs,
    linewidth = unname(as.numeric(linewidth_values)),
    count = unname(count_values),
    density = unname(density_values),
    frame = unname(frame_values),
    time = unname(time_values),
    rgba = unname(as.numeric(t(rgba_matrix))),
    stroke_rgba = if (is.null(stroke_matrix)) NULL else unname(as.numeric(t(stroke_matrix)))
  ))
}

#' Renderer-Ready Raster Layer
#'
#' Build a normalized raster layer from RGBA byte payloads.
#'
#' @param rgba Integer or numeric vector of length `width * height * 4`, using
#'   byte values in `[0, 255]`.
#' @param width,height Raster dimensions in cells.
#' @param xmin,xmax,ymin,ymax Raster extent.
#' @param interpolate Whether the WebGL texture should use linear filtering.
#' @inheritParams ggwebgl_layer_points
#'
#' @return A normalized raster layer list.
#'
#' @examples
#' ggwebgl_layer_raster(
#'   rgba = rep(c(15L, 23L, 42L, 255L), 4L),
#'   width = 2L,
#'   height = 2L,
#'   xmin = 0,
#'   xmax = 1,
#'   ymin = 0,
#'   ymax = 1,
#'   interpolate = TRUE
#' )
#' @export
ggwebgl_layer_raster <- function(rgba,
                                 width,
                                 height,
                                 xmin,
                                 xmax,
                                 ymin,
                                 ymax,
                                 interpolate = FALSE,
                                 panel_id = 1L,
                                 geom = "adapter_raster") {
  width <- as.integer(width)[[1L]]
  height <- as.integer(height)[[1L]]

  if (!is.finite(width) || !is.finite(height) || width <= 0L || height <= 0L) {
    rlang::abort("`width` and `height` must be positive integer scalars.")
  }

  rgba <- as.integer(round(as.numeric(rgba)))
  expected <- width * height * 4L

  if (length(rgba) != expected) {
    rlang::abort("`rgba` must have length `width * height * 4`.")
  }

  if (any(!is.finite(rgba)) || any(rgba < 0L | rgba > 255L)) {
    rlang::abort("`rgba` must contain finite byte values in [0, 255].")
  }

  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "raster",
    geom = as.character(geom)[[1L]],
    rows = as.integer(width * height),
    width = width,
    height = height,
    xmin = ggwebgl_scalar_number(xmin, "xmin"),
    xmax = ggwebgl_scalar_number(xmax, "xmax"),
    ymin = ggwebgl_scalar_number(ymin, "ymin"),
    ymax = ggwebgl_scalar_number(ymax, "ymax"),
    interpolate = isTRUE(interpolate),
    rgba = rgba
  ))
}

#' Build a ggWebGL Specification from Renderer-Ready Layers
#'
#' @param layers A list of normalized point, line, raster, vector, ribbon, mesh,
#'   or surface layers.
#' @param labels Optional labels list (`title`, `subtitle`, `x`, `y`).
#' @param webgl Optional renderer options passed to [theme_webgl()].
#' @param grid Optional list with `rows` and `cols`.
#' @param panels Optional panel metadata list or data frame with `panel_id`,
#'   `row`, `col`, optional `label`, and optional `viewport`.
#' @param messages Optional character vector of renderer messages.
#' @param timeline Optional `ggwebgl_timeline()` specification.
#'
#' @return A classed `ggwebgl_spec` object accepted by [ggWebGL()].
#'
#' @examples
#' panel_points <- ggwebgl_layer_points(
#'   data.frame(x = c(0, 1), y = c(1, 0)),
#'   x = "x",
#'   y = "y"
#' )
#' panel_lines <- ggwebgl_layer_lines(
#'   data.frame(x = c(0, 1, 2), y = c(0, 1, 0)),
#'   x = "x",
#'   y = "y",
#'   panel_id = "B"
#' )
#'
#' spec <- ggwebgl_spec(
#'   layers = list(panel_points, panel_lines),
#'   labels = list(title = "adapter spec"),
#'   panels = data.frame(
#'     panel_id = c(1L, "B"),
#'     row = c(1L, 1L),
#'     col = c(1L, 2L),
#'     stringsAsFactors = FALSE
#'   )
#' )
#'
#' spec$render$grid
#' @export
ggwebgl_spec <- function(layers,
                         labels = list(),
                         webgl = list(),
                         grid = NULL,
                         panels = NULL,
                         messages = character(),
                         timeline = NULL) {
  if (!is.list(layers) || inherits(layers, "data.frame")) {
    rlang::abort("`layers` must be a list of renderer-ready layers.")
  }

  layers <- lapply(layers, ggwebgl_validate_layer)
  panel_specs <- ggwebgl_build_panels(layers, panels = panels, grid = grid)
  webgl <- ggwebgl_scene_webgl_options(webgl)
  if (!is.null(timeline)) {
    webgl$timeline <- normalise_timeline(timeline)
  }
  render <- ggwebgl_build_render(panel_specs, messages = messages)
  webgl <- ggwebgl_complete_timeline(webgl, render)
  render <- ggwebgl_apply_transport(render, webgl)
  render <- ggwebgl_enrich_render(render, webgl)
  layer_metadata <- lapply(seq_along(layers), function(i) {
    compact_list(list(
      index = as.integer(i),
      geom = layers[[i]]$geom %||% layers[[i]]$type,
      stat = "identity",
      supported = TRUE,
      primitive = layers[[i]]$type,
      rows = as.integer(layers[[i]]$rows %||% 0L)
    ))
  })

  scene <- validate_ggwebgl_scene(compact_list(list(
    scene_version = ggwebgl_scene_version(),
    package_version = as.character(utils::packageVersion("ggWebGL")),
    labels = ggwebgl_labels(labels),
    webgl = webgl,
    layer_count = as.integer(length(layers)),
    layers = layer_metadata,
    render = render
  )), allow_legacy = FALSE)

  structure(
    scene,
    class = c("ggwebgl_spec", "list")
  )
}

#' @export
as_ggwebgl_spec.ggwebgl_spec <- function(x, ...) {
  unclass(x)
}

ggwebgl_adapter_data <- function(data) {
  if (is.null(data)) {
    return(NULL)
  }

  as.data.frame(data, stringsAsFactors = FALSE)
}

ggwebgl_resolve_arg <- function(data, expr, env, name, required = FALSE, default = NULL) {
  if (identical(expr, quote(NULL))) {
    if (required) {
      rlang::abort(paste0("`", name, "` is required."))
    }
    return(default)
  }

  if (!is.null(data) && is.symbol(expr)) {
    column <- as.character(expr)
    if (column %in% names(data)) {
      return(data[[column]])
    }
  }

  value <- eval(expr, envir = env)

  if (!is.null(data) && is.character(value) && length(value) == 1L && value %in% names(data)) {
    return(data[[value]])
  }

  value
}

ggwebgl_common_length <- function(...) {
  values <- list(...)
  lengths <- vapply(values, length, integer(1))
  lengths <- lengths[lengths > 1L]

  if (!length(lengths)) {
    return(1L)
  }

  if (length(unique(lengths)) != 1L) {
    rlang::abort("Vector inputs must have a common length or length 1.")
  }

  as.integer(lengths[[1L]])
}

ggwebgl_rect_common_length <- function(...) {
  values <- list(...)
  lengths <- vapply(values, length, integer(1))

  if (all(lengths == 0L)) {
    return(0L)
  }
  if (any(lengths == 0L)) {
    rlang::abort("Rectangle bounds must all be empty or all have length 1 or a common length.")
  }

  ggwebgl_common_length(...)
}

ggwebgl_recycle <- function(value, n, name) {
  if (length(value) == n) {
    return(value)
  }

  if (length(value) == 1L) {
    return(rep(value, n))
  }

  rlang::abort(paste0("`", name, "` must have length 1 or ", n, "."))
}

ggwebgl_resolve_rgba <- function(rgba, colour, alpha, n) {
  if (!is.null(rgba)) {
    values <- as.numeric(rgba)
    if (is.matrix(rgba) || is.data.frame(rgba)) {
      matrix_values <- as.matrix(rgba)
      if (ncol(matrix_values) != 4L || nrow(matrix_values) != n) {
        rlang::abort("`rgba` matrices must have `n` rows and four columns.")
      }
      values <- as.numeric(t(matrix_values))
    }
    if (length(values) != n * 4L) {
      rlang::abort("`rgba` must have length `n * 4`.")
    }
    if (any(!is.finite(values))) {
      rlang::abort("`rgba` must contain finite values.")
    }
    if (max(values) > 1.5) {
      values <- values / 255
    }
    return(matrix(pmax(0, pmin(1, values)), ncol = 4L, byrow = TRUE))
  }

  colour <- ggwebgl_recycle(colour %||% "#2C3E50", n, "colour")
  alpha <- ggwebgl_recycle(alpha %||% 1, n, "alpha")
  colour_to_rgba(colour, alpha)
}

ggwebgl_panel_id <- function(panel_id) {
  if (length(panel_id) != 1L || is.na(panel_id)) {
    rlang::abort("`panel_id` must be a non-missing scalar.")
  }

  panel_id
}

ggwebgl_scalar_number <- function(value, name) {
  value <- as.numeric(value)[[1L]]

  if (!is.finite(value)) {
    rlang::abort(paste0("`", name, "` must be a finite numeric scalar."))
  }

  value
}

ggwebgl_validate_layer <- function(layer) {
  if (!is.list(layer) || is.null(layer$type) ||
      !layer$type %in% c("points", "lines", "raster", "vectors", "rects", "ribbons", "mesh", "surface")) {
    rlang::abort("Each layer must be a renderer-ready points, lines, raster, vectors, rects, ribbons, mesh, or surface layer.")
  }

  layer
}

ggwebgl_build_panels <- function(layers, panels = NULL, grid = NULL) {
  panel_ids <- unique(vapply(layers, function(layer) as.character(layer$panel_id), character(1)))

  if (!length(panel_ids)) {
    panel_ids <- "1"
  }

  panel_meta <- ggwebgl_panel_meta(panel_ids, panels = panels, grid = grid)
  panel_specs <- lapply(panel_meta, function(panel) {
    panel_layers <- Filter(function(layer) identical(as.character(layer$panel_id), as.character(panel$panel_id)), layers)
    ggwebgl_panel_from_layers(panel, panel_layers)
  })
  attr(panel_specs, "grid") <- attr(panel_meta, "grid", exact = TRUE)
  panel_specs
}

ggwebgl_panel_meta <- function(panel_ids, panels = NULL, grid = NULL) {
  if (is.null(panels)) {
    grid <- ggwebgl_grid(grid, rows = 1L, cols = length(panel_ids))
    panel_meta <- lapply(seq_along(panel_ids), function(i) {
      compact_list(list(
        panel_id = panel_ids[[i]],
        row = 1L,
        col = as.integer(i),
        bounds = panel_bounds(1L, i, grid)
      ))
    })
    attr(panel_meta, "grid") <- grid
    return(panel_meta)
  }

  if (is.data.frame(panels)) {
    panels <- split(panels, seq_len(nrow(panels)))
  }

  panels <- lapply(panels, function(panel) {
    panel <- as.list(panel)
    compact_list(list(
      panel_id = panel$panel_id %||% panel$id,
      row = as.integer(panel$row %||% 1L),
      col = as.integer(panel$col %||% 1L),
      label = panel$label %||% NULL,
      viewport = panel$viewport %||% NULL,
      bounds = panel$bounds %||% NULL
    ))
  })
  ids <- vapply(panels, function(panel) as.character(panel$panel_id), character(1))

  missing_ids <- setdiff(as.character(panel_ids), ids)
  if (length(missing_ids)) {
    rlang::abort("`panels` must include metadata for every layer `panel_id`.")
  }

  grid <- ggwebgl_grid(
    grid,
    rows = max(vapply(panels, `[[`, integer(1), "row")),
    cols = max(vapply(panels, `[[`, integer(1), "col"))
  )

  panel_meta <- lapply(panels, function(panel) {
    panel$bounds <- panel$bounds %||% panel_bounds(panel$row, panel$col, grid)
    panel
  })
  attr(panel_meta, "grid") <- grid
  panel_meta
}

ggwebgl_grid <- function(grid, rows, cols) {
  if (is.null(grid)) {
    return(list(rows = as.integer(rows), cols = as.integer(cols)))
  }

  list(
    rows = max(1L, as.integer(grid$rows %||% rows)),
    cols = max(1L, as.integer(grid$cols %||% cols))
  )
}

ggwebgl_panel_from_layers <- function(panel, layers) {
  point_layers <- Filter(function(x) identical(x$type, "points"), layers)
  line_layers <- Filter(function(x) identical(x$type, "lines"), layers)
  raster_layers <- Filter(function(x) identical(x$type, "raster"), layers)
  vector_layers <- Filter(function(x) identical(x$type, "vectors"), layers)
  rect_layers <- Filter(function(x) identical(x$type, "rects"), layers)
  ribbon_layers <- Filter(function(x) identical(x$type, "ribbons"), layers)
  mesh_layers <- Filter(function(x) identical(x$type, "mesh"), layers)
  surface_layers <- Filter(function(x) identical(x$type, "surface"), layers)

  compact_list(list(
    panel_id = panel$panel_id,
    row = panel$row,
    col = panel$col,
    label = panel$label,
    bounds = panel$bounds,
    viewport = panel$viewport %||% ggwebgl_viewport_from_layers(layers),
    primitives = unique(vapply(layers, `[[`, character(1), "type")),
    point_count = sum(vapply(point_layers, `[[`, integer(1), "rows")),
    line_vertex_count = sum(vapply(line_layers, `[[`, integer(1), "rows")),
    path_count = sum(vapply(line_layers, `[[`, integer(1), "path_count")),
    raster_cell_count = sum(vapply(raster_layers, function(x) x$width * x$height, integer(1))),
    vector_count = sum(vapply(vector_layers, `[[`, integer(1), "rows")),
    rect_count = sum(vapply(rect_layers, `[[`, integer(1), "rows")),
    ribbon_count = sum(vapply(ribbon_layers, `[[`, integer(1), "strip_count")),
    ribbon_vertex_count = sum(vapply(ribbon_layers, `[[`, integer(1), "rows")),
    ribbon_triangle_count = sum(vapply(ribbon_layers, `[[`, integer(1), "triangle_count")),
    mesh_vertex_count = sum(vapply(mesh_layers, `[[`, integer(1), "vertex_count")),
    mesh_triangle_count = sum(vapply(mesh_layers, `[[`, integer(1), "triangle_count")),
    surface_vertex_count = sum(vapply(surface_layers, `[[`, integer(1), "vertex_count")),
    surface_triangle_count = sum(vapply(surface_layers, `[[`, integer(1), "triangle_count")),
    layers = layers
  ))
}

ggwebgl_viewport_from_layers <- function(layers) {
  xmin <- Inf
  xmax <- -Inf
  ymin <- Inf
  ymax <- -Inf

  extend <- function(x, y) {
    x <- as.numeric(x)
    y <- as.numeric(y)
    ok <- is.finite(x) & is.finite(y)
    if (any(ok)) {
      xmin <<- min(xmin, min(x[ok]))
      xmax <<- max(xmax, max(x[ok]))
      ymin <<- min(ymin, min(y[ok]))
      ymax <<- max(ymax, max(y[ok]))
    }
  }

  for (layer in layers) {
    if (identical(layer$type, "points")) {
      extend(layer$x, layer$y)
    } else if (identical(layer$type, "lines")) {
      for (path in layer$paths) {
        extend(path$x, path$y)
      }
    } else if (identical(layer$type, "raster")) {
      extend(c(layer$xmin, layer$xmax), c(layer$ymin, layer$ymax))
    } else if (identical(layer$type, "vectors")) {
      extend(c(layer$x, layer$xend), c(layer$y, layer$yend))
    } else if (identical(layer$type, "rects")) {
      extend(c(layer$xmin, layer$xmax), c(layer$ymin, layer$ymax))
    } else if (identical(layer$type, "ribbons")) {
      for (strip in layer$strips %||% list()) {
        extend(c(strip$x, strip$x), c(strip$ymin, strip$ymax))
      }
    } else if (identical(layer$type, "mesh")) {
      extend(layer$x, layer$y)
    } else if (identical(layer$type, "surface")) {
      positions <- matrix(as.numeric(layer$positions %||% numeric()), ncol = 3L, byrow = TRUE)
      if (nrow(positions)) {
        extend(positions[, 1L], positions[, 2L])
      }
    }
  }

  if (!is.finite(xmin) || !is.finite(xmax) || !is.finite(ymin) || !is.finite(ymax)) {
    return(list(x = c(0, 1), y = c(0, 1)))
  }

  list(x = normalise_range(c(xmin, xmax)), y = normalise_range(c(ymin, ymax)))
}

ggwebgl_build_render <- function(panels, messages = character()) {
  point_count <- sum(vapply(panels, `[[`, integer(1), "point_count"))
  line_vertex_count <- sum(vapply(panels, `[[`, integer(1), "line_vertex_count"))
  path_count <- sum(vapply(panels, `[[`, integer(1), "path_count"))
  raster_cell_count <- sum(vapply(panels, `[[`, integer(1), "raster_cell_count"))
  vector_count <- sum(vapply(panels, `[[`, integer(1), "vector_count"))
  rect_count <- sum(vapply(panels, `[[`, integer(1), "rect_count"))
  ribbon_count <- sum(vapply(panels, `[[`, integer(1), "ribbon_count"))
  ribbon_vertex_count <- sum(vapply(panels, `[[`, integer(1), "ribbon_vertex_count"))
  ribbon_triangle_count <- sum(vapply(panels, `[[`, integer(1), "ribbon_triangle_count"))
  mesh_vertex_count <- sum(vapply(panels, `[[`, integer(1), "mesh_vertex_count"))
  mesh_triangle_count <- sum(vapply(panels, `[[`, integer(1), "mesh_triangle_count"))
  surface_vertex_count <- sum(vapply(panels, `[[`, integer(1), "surface_vertex_count"))
  surface_triangle_count <- sum(vapply(panels, `[[`, integer(1), "surface_triangle_count"))
  primitives <- unique(unlist(lapply(panels, `[[`, "primitives"), use.names = FALSE))
  has_layers <- any(vapply(panels, function(panel) length(panel$layers), integer(1)) > 0L)
  grid <- attr(panels, "grid", exact = TRUE) %||% list(
    rows = max(vapply(panels, `[[`, integer(1), "row")),
    cols = max(vapply(panels, `[[`, integer(1), "col"))
  )

  derive_single_panel_compatibility(compact_list(list(
    mode = if (has_layers) "webgl" else "metadata",
    grid = grid,
    panels = panels,
    primitives = primitives,
    point_count = point_count,
    line_vertex_count = line_vertex_count,
    path_count = path_count,
    raster_cell_count = raster_cell_count,
    vector_count = vector_count,
    rect_count = rect_count,
    ribbon_count = ribbon_count,
    ribbon_vertex_count = ribbon_vertex_count,
    ribbon_triangle_count = ribbon_triangle_count,
    mesh_vertex_count = mesh_vertex_count,
    mesh_triangle_count = mesh_triangle_count,
    surface_vertex_count = surface_vertex_count,
    surface_triangle_count = surface_triangle_count,
    unsupported_layers = list(),
    messages = unname(as.character(messages))
  )))
}

ggwebgl_enrich_render <- function(render, webgl) {
  ggwebgl_enrich_scene_render(render, webgl)
}

ggwebgl_labels <- function(labels) {
  if (is.null(labels) || !is.list(labels)) {
    labels <- list()
  }

  compact_list(list(
    title = labels$title %||% NULL,
    subtitle = labels$subtitle %||% NULL,
    x = labels$x %||% NULL,
    y = labels$y %||% NULL
  ))
}
