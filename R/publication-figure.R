#' Build a Publication-Mode Figure Container from ggWebGL Panels
#'
#' Create a package-owned HTML container for publication capture. Each child
#' panel is rendered through ggWebGL in publication mode unless it already
#' declares a different rendering contract explicitly.
#'
#' @param panels A non-empty list of panel sources. Supported sources are
#'   `ggplot` objects, `ggWebGL` htmlwidgets, `ggwebgl_spec` objects, or raw
#'   renderer payloads accepted by [ggWebGL()]. Each element may also be a list
#'   with `source` plus optional `show_panel_overlay`.
#' @param layout One of `"single"`, `"row"`, or `"grid"`.
#' @param labels Optional character vector of panel labels.
#' @param annotations Optional list of figure-level text annotations. Each entry
#'   should contain `text`, `x`, and `y`, with optional `size`, `colour`,
#'   `font`, `hjust`, and `vjust`.
#' @param inset Optional inset specification containing a panel `source` plus
#'   fractional `left`, `top`, `width`, and `height`.
#' @param background Figure background colour.
#' @param preset Publication styling preset. `"publication"` adds subtle panel
#'   borders and muted overlay text.
#' @param width,height Optional figure dimensions in pixels.
#'
#' @return A browsable HTML container with class `ggwebgl_publication_figure`.
#' @export
#'
#' @examples
#' demo_spec <- ggwebgl_spec(
#'   layers = list(
#'     ggwebgl_layer_points(
#'       data.frame(x = c(0.15, 0.52, 0.84), y = c(0.20, 0.78, 0.42)),
#'       x = "x",
#'       y = "y",
#'       colour = c("#0f766e", "#f97316", "#2563eb"),
#'       alpha = 0.8,
#'       size = 5
#'     )
#'   )
#' )
#'
#' figure <- ggwebgl_publication_figure(
#'   panels = list(demo_spec),
#'   width = 420,
#'   height = 280
#' )
#'
#' inherits(figure, "ggwebgl_publication_figure")
ggwebgl_publication_figure <- function(panels,
                                       layout = c("single", "row", "grid"),
                                       labels = NULL,
                                       annotations = NULL,
                                       inset = NULL,
                                       background = "white",
                                       preset = c("clean", "publication"),
                                       width = NULL,
                                       height = NULL) {
  spec <- ggwebgl_normalise_publication_figure(
    panels = panels,
    layout = layout,
    labels = labels,
    annotations = annotations,
    inset = inset,
    background = background,
    preset = preset,
    width = width,
    height = height
  )
  figure <- ggwebgl_build_publication_figure_html(spec)
  attr(figure, "ggwebgl_publication_figure_spec") <- spec
  class(figure) <- unique(c("ggwebgl_publication_figure", class(figure)))
  figure
}

ggwebgl_normalise_publication_figure <- function(panels,
                                                 layout = c("single", "row", "grid"),
                                                 labels = NULL,
                                                 annotations = NULL,
                                                 inset = NULL,
                                                 background = "white",
                                                 preset = c("clean", "publication"),
                                                 width = NULL,
                                                 height = NULL,
                                                 nrow = NULL,
                                                 ncol = NULL) {
  if (!is.list(panels) || !length(panels)) {
    rlang::abort("`panels` must be a non-empty list.")
  }

  layout <- match.arg(layout)
  preset <- ggwebgl_normalise_publication_preset(preset)

  if (!is.null(labels)) {
    labels <- as.character(labels)
    if (length(labels) != length(panels)) {
      rlang::abort("`labels` must have the same length as `panels`.")
    }
  }

  if (!is.null(width)) {
    width <- ggwebgl_positive_integer(width, "width")
  }

  if (!is.null(height)) {
    height <- ggwebgl_positive_integer(height, "height")
  }

  compact_list(list(
    panels = panels,
    layout = layout,
    labels = labels,
    annotations = annotations,
    inset = inset,
    background = as.character(background)[[1L]],
    preset = preset,
    width = width,
    height = height,
    nrow = nrow,
    ncol = ncol
  ))
}

ggwebgl_publication_figure_spec <- function(x) {
  attr(x, "ggwebgl_publication_figure_spec", exact = TRUE)
}

ggwebgl_publication_layout_spec <- function(n,
                                            layout,
                                            width,
                                            height,
                                            preset,
                                            nrow = NULL,
                                            ncol = NULL) {
  base <- ggwebgl_layout_spec(
    n = n,
    layout = layout,
    width = width,
    height = height,
    nrow = nrow,
    ncol = ncol
  )

  gap <- if (identical(layout, "single")) {
    0L
  } else if (identical(preset, "publication")) {
    18L
  } else {
    12L
  }

  usable_width <- width - gap * (base$cols - 1L)
  usable_height <- height - gap * (base$rows - 1L)
  cell_width <- floor(usable_width / base$cols)
  cell_height <- floor(usable_height / base$rows)

  cells <- lapply(seq_len(n), function(i) {
    row <- (i - 1L) %/% base$cols
    col <- (i - 1L) %% base$cols
    left <- as.integer(col * (cell_width + gap))
    top <- as.integer(row * (cell_height + gap))

    compact_list(list(
      left = left,
      top = top,
      width = if (col < base$cols - 1L) cell_width else width - left,
      height = if (row < base$rows - 1L) cell_height else height - top
    ))
  })

  list(rows = base$rows, cols = base$cols, gap = gap, cells = cells)
}

ggwebgl_is_publication_source <- function(source) {
  inherits(source, "ggplot") ||
    (inherits(source, "htmlwidget") && inherits(source, "ggWebGL")) ||
    inherits(source, "ggwebgl_spec") ||
    (is.list(source) && !inherits(source, "data.frame") && !inherits(source, "magick-image"))
}

ggwebgl_panel_overlay_override <- function(show_panel_overlay) {
  if (is.null(show_panel_overlay)) {
    return(NULL)
  }

  if (isTRUE(show_panel_overlay)) {
    "show"
  } else {
    "hide"
  }
}

ggwebgl_merge_publication_webgl <- function(webgl = NULL, panel_overlay = NULL) {
  explicit_fields <- webgl_explicit_fields(webgl)
  merged <- if (is.null(webgl)) list() else as.list(webgl)

  if (!"rendering" %in% explicit_fields) {
    merged[["rendering"]] <- "publication"
    explicit_fields <- c(explicit_fields, "rendering")
  }

  if (!is.null(panel_overlay) && !"panel_overlay" %in% explicit_fields) {
    merged[["panel_overlay"]] <- panel_overlay
    explicit_fields <- c(explicit_fields, "panel_overlay")
  }

  normalise_webgl_options(merged, explicit_fields = explicit_fields)
}

ggwebgl_publication_widget <- function(source,
                                       width,
                                       height,
                                       panel_overlay = NULL,
                                       elementId = NULL) {
  if (inherits(source, "ggplot")) {
    plot <- source
    plot$ggwebgl <- ggwebgl_merge_publication_webgl(plot$ggwebgl %||% NULL, panel_overlay = panel_overlay)
    return(ggplot_webgl(plot, width = width, height = height, elementId = elementId))
  }

  if (inherits(source, "htmlwidget")) {
    if (!inherits(source, "ggWebGL")) {
      rlang::abort("Publication figures only support ggWebGL htmlwidgets as widget panel sources.")
    }

    widget <- source
    widget$x$webgl <- ggwebgl_merge_publication_webgl(widget$x$webgl %||% NULL, panel_overlay = panel_overlay)
    widget$width <- width
    widget$height <- height
    if (!is.null(elementId)) {
      widget$elementId <- elementId
    }
    return(widget)
  }

  payload <- source
  if (inherits(source, "ggwebgl_spec") ||
      (!is.null(attr(source, "class")) && !identical(class(source), "list"))) {
    payload <- as_ggwebgl_spec(source)
  }

  if (!is.list(payload) || inherits(payload, "data.frame")) {
    rlang::abort("Publication figures only support ggplot, ggWebGL, ggwebgl_spec, or raw renderer payload sources.")
  }

  payload$webgl <- ggwebgl_merge_publication_webgl(payload$webgl %||% NULL, panel_overlay = panel_overlay)
  ggWebGL(payload, width = width, height = height, elementId = elementId)
}

ggwebgl_publication_css <- function(spec, width, height) {
  border_colour <- if (identical(spec$preset, "publication")) {
    "rgba(51, 65, 85, 0.24)"
  } else {
    "rgba(51, 65, 85, 0.16)"
  }
  label_colour <- if (identical(spec$preset, "publication")) "#475569" else "#334155"
  label_alpha <- if (identical(spec$preset, "publication")) 0.74 else 0.88
  border_radius <- if (identical(spec$preset, "publication")) 12L else 8L

  paste(
    c(
      sprintf(
        ".ggwebgl-publication-figure { position: relative; width: %dpx; height: %dpx; overflow: hidden; box-sizing: border-box; background: %s; font-family: \"Source Sans 3\", \"Helvetica Neue\", sans-serif; }",
        width,
        height,
        spec$background
      ),
      ".ggwebgl-publication-figure__cell { position: absolute; overflow: hidden; box-sizing: border-box; background: transparent; }",
      sprintf(
        ".ggwebgl-publication-figure__cell-frame { position: absolute; inset: 0; border: 1px solid %s; border-radius: %dpx; pointer-events: none; box-sizing: border-box; }",
        border_colour,
        border_radius
      ),
      ".ggwebgl-publication-figure__widget { position: absolute; inset: 0; }",
      sprintf(
        ".ggwebgl-publication-figure__label { position: absolute; z-index: 5; font: 500 15px/1.2 \"Source Sans 3\", \"Helvetica Neue\", sans-serif; letter-spacing: 0.02em; color: rgba(%s, %.3f); }",
        paste(grDevices::col2rgb(label_colour)[, 1], collapse = ", "),
        label_alpha
      ),
      ".ggwebgl-publication-figure__annotation { position: absolute; z-index: 6; white-space: nowrap; }",
      sprintf(
        ".ggwebgl-publication-figure__inset { position: absolute; overflow: hidden; box-sizing: border-box; z-index: 7; background: %s; }",
        spec$background
      ),
      sprintf(
        ".ggwebgl-publication-figure__inset-border { position: absolute; inset: 0; border: 1px solid %s; border-radius: %dpx; pointer-events: none; box-sizing: border-box; }",
        border_colour,
        border_radius
      ),
      ".ggwebgl-publication-figure .html-widget { width: 100% !important; height: 100% !important; }"
    ),
    collapse = "\n"
  )
}

ggwebgl_publication_cell_tag <- function(panel,
                                         cell,
                                         index,
                                         spec) {
  panel_spec <- ggwebgl_normalise_panel(panel)
  source <- panel_spec$source

  if (!ggwebgl_is_publication_source(source)) {
    rlang::abort("All publication-figure panels must be ggWebGL-renderable sources.")
  }

  widget <- ggwebgl_publication_widget(
    source = source,
    width = cell$width,
    height = cell$height,
    panel_overlay = ggwebgl_panel_overlay_override(panel_spec$show_panel_overlay)
  )

  children <- list(
    htmltools::div(
      class = "ggwebgl-publication-figure__widget",
      style = "left:0; top:0; width:100%; height:100%;",
      widget
    )
  )

  if (length(spec$panels) > 1L && identical(spec$preset, "publication")) {
    children[[length(children) + 1L]] <- htmltools::div(class = "ggwebgl-publication-figure__cell-frame")
  }

  if (!is.null(spec$labels)) {
    children[[length(children) + 1L]] <- htmltools::div(
      class = "ggwebgl-publication-figure__label",
      style = sprintf("left:%dpx; top:%dpx;", 18L, 16L),
      spec$labels[[index]]
    )
  }

  do.call(
    htmltools::div,
    c(
      list(
        class = "ggwebgl-publication-figure__cell",
        style = sprintf(
          "left:%dpx; top:%dpx; width:%dpx; height:%dpx;",
          cell$left,
          cell$top,
          cell$width,
          cell$height
        )
      ),
      children
    )
  )
}

ggwebgl_publication_annotation_tag <- function(annotation, width, height) {
  if (!is.list(annotation) || is.null(annotation$text)) {
    rlang::abort("Each `annotations` entry must be a list containing at least `text`, `x`, and `y`.")
  }

  x <- as.numeric(annotation$x %||% NA_real_)
  y <- as.numeric(annotation$y %||% NA_real_)

  if (!is.finite(x) || !is.finite(y)) {
    rlang::abort("Each `annotations` entry must define finite fractional `x` and `y` values.")
  }

  hjust <- as.numeric(annotation$hjust %||% 0)
  vjust <- as.numeric(annotation$vjust %||% 0.5)

  style <- sprintf(
    paste(
      "left:%0.3fpx;",
      "top:%0.3fpx;",
      "font:%s %spx/1.1 %s;",
      "color:%s;",
      "transform:translate(%0.1f%%,%0.1f%%);"
    ),
    x * width,
    y * height,
    if (identical(annotation$weight %||% NULL, "bold")) "700" else "500",
    as.numeric(annotation$size %||% 24),
    paste0("\"", as.character(annotation$font %||% "Helvetica")[1], "\""),
    as.character(annotation$colour %||% "#64748b")[1],
    -100 * hjust,
    -100 * vjust
  )

  htmltools::div(
    class = "ggwebgl-publication-figure__annotation",
    style = style,
    as.character(annotation$text)[[1L]]
  )
}

ggwebgl_publication_inset_tag <- function(inset, width, height, spec) {
  inset_spec <- ggwebgl_normalise_inset(inset, width = width, height = height)

  if (!ggwebgl_is_publication_source(inset_spec$panel)) {
    rlang::abort("Publication-figure insets must use ggWebGL-renderable sources.")
  }

  widget <- ggwebgl_publication_widget(
    source = inset_spec$panel,
    width = inset_spec$width,
    height = inset_spec$height
  )

  children <- list(
    htmltools::div(
      class = "ggwebgl-publication-figure__widget",
      style = "left:0; top:0; width:100%; height:100%;",
      widget
    )
  )

  if (isTRUE(inset_spec$border)) {
    children[[length(children) + 1L]] <- htmltools::div(
      class = "ggwebgl-publication-figure__inset-border",
      style = sprintf(
        "border-color:%s; opacity:%0.3f;",
        as.character(inset_spec$border_colour)[[1L]],
        as.numeric(inset_spec$border_alpha %||% 0.35)
      )
    )
  }

  do.call(
    htmltools::div,
    c(
      list(
        class = "ggwebgl-publication-figure__inset",
        style = sprintf(
          "left:%dpx; top:%dpx; width:%dpx; height:%dpx;",
          inset_spec$left,
          inset_spec$top,
          inset_spec$width,
          inset_spec$height
        )
      ),
      children
    )
  )
}

ggwebgl_build_publication_figure_html <- function(spec, width = NULL, height = NULL) {
  width <- as.integer(width %||% spec$width %||% 1800L)
  height <- as.integer(height %||% spec$height %||% 1200L)
  layout_spec <- ggwebgl_publication_layout_spec(
    n = length(spec$panels),
    layout = spec$layout,
    width = width,
    height = height,
    preset = spec$preset,
    nrow = spec$nrow %||% NULL,
    ncol = spec$ncol %||% NULL
  )

  root_children <- c(
    list(
      htmltools::tags$style(htmltools::HTML(ggwebgl_publication_css(spec, width, height)))
    ),
    lapply(seq_along(spec$panels), function(i) {
      ggwebgl_publication_cell_tag(
        panel = spec$panels[[i]],
        cell = layout_spec$cells[[i]],
        index = i,
        spec = spec
      )
    })
  )

  if (!is.null(spec$annotations)) {
    root_children <- c(
      root_children,
      lapply(spec$annotations, ggwebgl_publication_annotation_tag, width = width, height = height)
    )
  }

  if (!is.null(spec$inset)) {
    root_children[[length(root_children) + 1L]] <- ggwebgl_publication_inset_tag(
      inset = spec$inset,
      width = width,
      height = height,
      spec = spec
    )
  }

  htmltools::browsable(
    do.call(
      htmltools::div,
      c(
        list(
          class = sprintf("ggwebgl-publication-figure ggwebgl-publication-figure--%s", spec$preset),
          style = sprintf("width:%dpx; height:%dpx; background:%s;", width, height, spec$background)
        ),
        root_children
      )
    )
  )
}
