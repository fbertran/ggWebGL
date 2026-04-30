#' Build a Linked Magnifying-Glass Zoom Scene
#'
#' Create a deterministic zoom view from a rectangular data region. The helper
#' is renderer-generic: callers provide renderer-ready ggWebGL sources and the
#' selected region, and ggWebGL derives either a two-panel zoom spec or a
#' publication figure with a linked inset.
#'
#' @param source A `ggplot`, `ggWebGL` widget, `ggwebgl_spec`, or raw renderer
#'   payload accepted by [ggWebGL()].
#' @param region Rectangle to magnify. Use either `list(x = c(xmin, xmax),
#'   y = c(ymin, ymax))` or `list(xmin = ..., xmax = ..., ymin = ..., ymax = ...)`.
#' @param display One of `"panel"` or `"inset"`.
#' @param source_panel Optional panel id to magnify when `source` has multiple
#'   panels. Defaults to the first panel.
#' @param zoom_layers Optional renderer-ready layers to use in the zoom view.
#'   When omitted, the source panel layers are reused.
#' @param global_panel_id,zoom_panel_id Panel ids used in `display = "panel"`.
#' @param global_label,zoom_label Optional panel labels.
#' @param box Whether to add a rectangle overlay to the global panel.
#' @param box_colour,box_alpha,box_width Rectangle styling.
#' @param inset Inset placement list for `display = "inset"` with fractional
#'   `left`, `top`, `width`, and `height`.
#' @param interactive Whether a two-panel magnifier should let browser-side
#'   brush rectangles on the global panel update the zoom panel viewport live.
#' @param width,height Optional publication figure dimensions for inset output.
#' @param background,preset Publication figure styling for inset output.
#' @param labels Optional labels for the derived renderer specs.
#' @param webgl Optional renderer options for the derived specs. Defaults to
#'   the source webgl options.
#'
#' @return A `ggwebgl_spec` for `display = "panel"` or a
#'   `ggwebgl_publication_figure` for `display = "inset"`.
#' @export
#'
#' @examples
#' source <- ggwebgl_spec(
#'   layers = list(
#'     ggwebgl_layer_points(
#'       data.frame(x = c(0, 1, 2, 3), y = c(0, 2, 1, 3)),
#'       x = "x",
#'       y = "y",
#'       colour = "#2563eb",
#'       alpha = 0.75,
#'       size = 4
#'     )
#'   )
#' )
#'
#' ggwebgl_magnify_region(
#'   source,
#'   region = list(x = c(0.75, 2.25), y = c(0.75, 2.25)),
#'   display = "panel"
#' )
ggwebgl_magnify_region <- function(source,
                                   region,
                                   display = c("panel", "inset"),
                                   source_panel = NULL,
                                   zoom_layers = NULL,
                                   global_panel_id = "global",
                                   zoom_panel_id = "local",
                                   global_label = "Global",
                                   zoom_label = "Zoomed region",
                                   box = TRUE,
                                   box_colour = "#334155",
                                   box_alpha = 0.65,
                                   box_width = 1.5,
                                   inset = list(left = 0.68, top = 0.06, width = 0.24, height = 0.24),
                                   interactive = FALSE,
                                   width = NULL,
                                   height = NULL,
                                   background = "white",
                                   preset = c("clean", "publication"),
                                   labels = NULL,
                                   webgl = NULL) {
  display <- match.arg(display)
  preset <- ggwebgl_normalise_publication_preset(preset)
  region <- ggwebgl_normalise_magnify_region(region)
  payload <- ggwebgl_magnify_payload(source)
  panel <- ggwebgl_magnify_source_panel(payload, source_panel = source_panel)
  labels <- labels %||% payload$labels %||% list()
  webgl <- webgl %||% payload$webgl %||% list()
  if (isTRUE(interactive) && !identical(display, "panel")) {
    rlang::abort("`interactive = TRUE` is currently supported only with `display = \"panel\"`.")
  }
  if (isTRUE(interactive)) {
    webgl <- ggwebgl_magnify_interactive_webgl(webgl)
  }

  global_layers <- ggwebgl_magnify_repanel_layers(panel$layers, global_panel_id)
  if (isTRUE(box)) {
    global_layers[[length(global_layers) + 1L]] <- ggwebgl_magnify_box_layer(
      region = region,
      panel_id = global_panel_id,
      colour = box_colour,
      alpha = box_alpha,
      width = box_width
    )
  }

  zoom_layers <- zoom_layers %||% panel$layers
  zoom_layers <- lapply(zoom_layers, ggwebgl_validate_layer)
  zoom_layers <- ggwebgl_magnify_repanel_layers(zoom_layers, zoom_panel_id)

  if (identical(display, "panel")) {
    spec <- ggwebgl_spec(
      layers = c(global_layers, zoom_layers),
      labels = labels,
      webgl = webgl,
      grid = list(rows = 1L, cols = 2L),
      panels = list(
        list(
          panel_id = global_panel_id,
          row = 1L,
          col = 1L,
          label = global_label,
          viewport = panel$viewport
        ),
        list(
          panel_id = zoom_panel_id,
          row = 1L,
          col = 2L,
          label = zoom_label,
          viewport = region
        )
      )
    )

    if (isTRUE(interactive)) {
      spec$render$links <- compact_list(list(
        magnifiers = list(compact_list(list(
          source_panel = global_panel_id,
          target_panel = zoom_panel_id,
          region = region
        )))
      ))
    }

    return(spec)
  }

  global_spec <- ggwebgl_spec(
    layers = global_layers,
    labels = labels,
    webgl = webgl,
    panels = list(
      list(
        panel_id = global_panel_id,
        row = 1L,
        col = 1L,
        viewport = panel$viewport
      )
    )
  )
  zoom_spec <- ggwebgl_spec(
    layers = zoom_layers,
    labels = labels,
    webgl = webgl,
    panels = list(
      list(
        panel_id = zoom_panel_id,
        row = 1L,
        col = 1L,
        viewport = region
      )
    )
  )

  inset <- as.list(inset)
  inset$source <- zoom_spec

  ggwebgl_publication_figure(
    panels = list(global_spec),
    layout = "single",
    inset = inset,
    background = background,
    preset = preset,
    width = width,
    height = height
  )
}

ggwebgl_normalise_magnify_region <- function(region) {
  if (!is.list(region)) {
    rlang::abort("`region` must be a list.")
  }

  x <- region$x %||% NULL
  y <- region$y %||% NULL

  if (is.null(x) && all(c("xmin", "xmax") %in% names(region))) {
    x <- c(region$xmin, region$xmax)
  }
  if (is.null(y) && all(c("ymin", "ymax") %in% names(region))) {
    y <- c(region$ymin, region$ymax)
  }

  x <- as.numeric(x)
  y <- as.numeric(y)
  if (length(x) != 2L || length(y) != 2L || any(!is.finite(c(x, y)))) {
    rlang::abort("`region` must define finite x and y ranges.")
  }

  x <- range(x)
  y <- range(y)
  if (diff(x) <= 0 || diff(y) <= 0) {
    rlang::abort("`region` x and y ranges must have positive width and height.")
  }

  list(x = unname(x), y = unname(y))
}

ggwebgl_magnify_payload <- function(source) {
  if (inherits(source, "ggplot")) {
    source <- build_ggwebgl_spec(source)
  } else if (inherits(source, "htmlwidget")) {
    if (!inherits(source, "ggWebGL")) {
      rlang::abort("`source` htmlwidgets must be ggWebGL widgets.")
    }
    source <- source$x
  } else if (inherits(source, "ggwebgl_spec") ||
             (!is.null(attr(source, "class")) && !identical(class(source), "list"))) {
    source <- as_ggwebgl_spec(source)
  }

  if (!is.list(source) || inherits(source, "data.frame") ||
      is.null(source$render) || is.null(source$render$panels)) {
    rlang::abort("`source` must provide a ggWebGL renderer payload with `render$panels`.")
  }

  source
}

ggwebgl_magnify_source_panel <- function(payload, source_panel = NULL) {
  panels <- payload$render$panels
  if (!length(panels)) {
    rlang::abort("`source` must contain at least one render panel.")
  }

  if (is.null(source_panel)) {
    return(panels[[1L]])
  }

  ids <- vapply(panels, function(panel) as.character(panel$panel_id), character(1))
  idx <- match(as.character(source_panel), ids)
  if (is.na(idx)) {
    rlang::abort("`source_panel` must match one of the source render panel ids.")
  }

  panels[[idx]]
}

ggwebgl_magnify_repanel_layers <- function(layers, panel_id) {
  lapply(layers, function(layer) {
    layer$panel_id <- ggwebgl_panel_id(panel_id)
    layer
  })
}

ggwebgl_magnify_box_layer <- function(region,
                                      panel_id,
                                      colour = "#334155",
                                      alpha = 0.65,
                                      width = 1.5) {
  box <- data.frame(
    x = c(region$x[[1L]], region$x[[2L]], region$x[[2L]], region$x[[1L]], region$x[[1L]]),
    y = c(region$y[[1L]], region$y[[1L]], region$y[[2L]], region$y[[2L]], region$y[[1L]]),
    group = "magnify_region",
    stringsAsFactors = FALSE
  )

  ggwebgl_layer_lines(
    box,
    x = "x",
    y = "y",
    group = "group",
    colour = colour,
    alpha = alpha,
    width = width,
    panel_id = panel_id,
    geom = "ggwebgl_magnify_region_box"
  )
}

ggwebgl_magnify_interactive_webgl <- function(webgl) {
  webgl <- as.list(webgl %||% list())
  interactions <- unique(c(as.character(webgl$interactions %||% character()), "brush"))
  webgl$interactions <- interactions
  selection <- normalise_selection(webgl$selection %||% NULL, interactions = interactions)
  if (identical(selection$mode, "none")) {
    selection <- ggwebgl_selection("brush")
  }
  webgl$selection <- selection
  webgl
}
