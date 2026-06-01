#' Capture a ggWebGL Scene as a Static Image
#'
#' Build a `ggWebGL` widget if needed, hide interactive chrome for export, and
#' capture a clean static image through the browser-backed widget path.
#'
#' @param x A `ggplot`, `ggWebGL` htmlwidget, `ggwebgl_spec`, raw renderer
#'   payload accepted by [ggWebGL()], or a [ggwebgl_publication_figure()].
#' @param file Output file path.
#' @param width,height Output size in pixels.
#' @param format Optional image format. When omitted, it is inferred from
#'   `file`.
#' @param dpi Output density metadata used when writing the image.
#' @param background Background colour used for the final flattened image.
#' @param preset Export preset. `"clean"` removes UI chrome; `"publication"`
#'   also applies subtle panel-strip and panel-frame styling for publication
#'   capture.
#' @param selfcontained Passed through to [htmlwidgets::saveWidget()] for the
#'   temporary export widget.
#' @param wait_seconds Delay before capture to allow the widget to finish
#'   rendering.
#' @param show_panel_overlay Whether facet/panel overlays should remain visible
#'   in the captured output.
#' @param elementId Optional DOM element id passed when `x` must first be turned
#'   into a widget.
#'
#' @return The normalized output file path, invisibly.
#' @export
#'
#' @examplesIf requireNamespace("chromote", quietly = TRUE) && requireNamespace("magick", quietly = TRUE) && !nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_"))
#' old <- options(ggwebgl.reset_processx_supervisor = TRUE)
#' on.exit(options(old), add = TRUE)
#'
#' tiny_spec <- ggwebgl_spec(
#'   layers = list(
#'     ggwebgl_layer_points(
#'       data.frame(x = c(0.15, 0.5, 0.82), y = c(0.25, 0.78, 0.4)),
#'       x = "x",
#'       y = "y",
#'       colour = c("#0f766e", "#f97316", "#2563eb"),
#'       alpha = 0.8,
#'       size = 5
#'     )
#'   ),
#'   webgl = list(shader = "default", interactions = character())
#' )
#'
#' out <- tempfile(fileext = ".jpg")
#' snapshot_ggwebgl(
#'   tiny_spec,
#'   out,
#'   width = 320,
#'   height = 220,
#'   format = "jpeg",
#'   preset = "clean",
#'   wait_seconds = 0.25
#' )
#' file.exists(out)
snapshot_ggwebgl <- function(x,
                             file,
                             width = 1800L,
                             height = 1200L,
                             format = NULL,
                             dpi = 300,
                             background = "white",
                             preset = c("clean", "publication"),
                             selfcontained = FALSE,
                             wait_seconds = 3,
                             show_panel_overlay = FALSE,
                             elementId = NULL) {
  width_missing <- missing(width)
  height_missing <- missing(height)
  background_missing <- missing(background)
  preset_missing <- missing(preset)

  format <- ggwebgl_normalise_image_format(file, format)
  dpi <- ggwebgl_positive_integer(dpi, "dpi")
  wait_seconds <- ggwebgl_nonnegative_number(wait_seconds, "wait_seconds")
  file <- ggwebgl_output_path(file)

  ggwebgl_require_export_dependency("chromote")
  ggwebgl_require_export_dependency("magick")

  if (inherits(x, "ggwebgl_publication_figure")) {
    spec <- ggwebgl_publication_figure_spec(x)

    if (is.null(spec)) {
      rlang::abort("`ggwebgl_publication_figure` is missing its internal figure specification.")
    }

    resolved_width <- ggwebgl_positive_integer(if (width_missing) spec$width %||% 1800L else width, "width")
    resolved_height <- ggwebgl_positive_integer(if (height_missing) spec$height %||% 1200L else height, "height")
    resolved_background <- if (background_missing) spec$background %||% "white" else background
    resolved_preset <- if (preset_missing) spec$preset %||% "clean" else ggwebgl_normalise_publication_preset(preset)
    resolved_preset <- ggwebgl_normalise_publication_preset(resolved_preset)
    spec$width <- resolved_width
    spec$height <- resolved_height
    spec$background <- resolved_background
    spec$preset <- resolved_preset

    image <- ggwebgl_with_chromote_browser(function(browser) {
      ggwebgl_capture_html_image(
        content = ggwebgl_build_publication_figure_html(spec, width = resolved_width, height = resolved_height),
        width = resolved_width,
        height = resolved_height,
        wait_seconds = wait_seconds,
        browser = browser
      )
    })

    return(ggwebgl_write_image(
      image = image,
      file = file,
      format = format,
      width = resolved_width,
      height = resolved_height,
      dpi = dpi,
      background = resolved_background
    ))
  }

  preset <- ggwebgl_normalise_publication_preset(preset)
  width <- ggwebgl_positive_integer(width, "width")
  height <- ggwebgl_positive_integer(height, "height")
  widget <- ggwebgl_as_widget(x, width = width, height = height, elementId = elementId)

  image <- ggwebgl_with_chromote_browser(function(browser) {
    ggwebgl_capture_widget_image(
      widget = widget,
      width = width,
      height = height,
      preset = preset,
      selfcontained = isTRUE(selfcontained),
      wait_seconds = wait_seconds,
      show_panel_overlay = isTRUE(show_panel_overlay),
      browser = browser
    )
  })
  ggwebgl_write_image(
    image = image,
    file = file,
    format = format,
    width = width,
    height = height,
    dpi = dpi,
    background = background
  )
}

#' Compose a Publication Figure from ggWebGL Panels
#'
#' Capture one or more ggWebGL scenes and assemble them into a single clean
#' publication image.
#'
#' @param panels A list of panel sources. Each element may be a `ggplot`,
#'   `ggWebGL` widget, `ggwebgl_spec`, raw renderer payload, image path, or a
#'   list with `source` plus optional `wait_seconds`, `show_panel_overlay`, and
#'   `preset` overrides.
#' @param file Output file path.
#' @param width,height Output size in pixels.
#' @param format Optional image format. When omitted, it is inferred from
#'   `file`.
#' @param dpi Output density metadata used when writing the image.
#' @param background Background colour used for the final flattened image.
#' @param layout One of `"single"`, `"row"`, or `"grid"`.
#' @param labels Optional character vector of panel labels drawn in the top-left
#'   corner of each occupied panel cell.
#' @param inset Optional list with a panel `source`, fractional `left`, `top`,
#'   `width`, `height`, and optional `border`, `border_colour`, and
#'   `border_alpha`.
#' @param annotations Optional list of text annotations. Each entry should
#'   contain `text` plus fractional `x` and `y`, with optional `size`,
#'   `colour`, `font`, `hjust`, and `vjust`.
#' @param preset Export preset. `"publication"` adds subtle panel borders and
#'   muted label styling.
#' @param selfcontained Passed through to [htmlwidgets::saveWidget()] for
#'   temporary widget captures.
#' @param wait_seconds Default render delay before capture.
#' @param nrow,ncol Optional grid dimensions used when `layout = "grid"`.
#' @param elementId Optional DOM element id passed when panel sources must first
#'   be turned into widgets.
#'
#' @return The normalized output file path, invisibly.
#' @export
#'
#' @examplesIf requireNamespace("chromote", quietly = TRUE) && requireNamespace("magick", quietly = TRUE) && !nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_"))
#' old <- options(ggwebgl.reset_processx_supervisor = TRUE)
#' on.exit(options(old), add = TRUE)
#'
#' point_spec <- ggwebgl_spec(
#'   layers = list(
#'     ggwebgl_layer_points(
#'       data.frame(x = c(0.15, 0.48, 0.82), y = c(0.22, 0.76, 0.38)),
#'       x = "x",
#'       y = "y",
#'       colour = c("#0f766e", "#f97316", "#2563eb"),
#'       alpha = 0.8,
#'       size = 5
#'     )
#'   ),
#'   webgl = list(shader = "default", interactions = character())
#' )
#' line_spec <- ggwebgl_spec(
#'   layers = list(
#'     ggwebgl_layer_lines(
#'       data.frame(x = c(0.1, 0.45, 0.8), y = c(0.25, 0.75, 0.35)),
#'       x = "x",
#'       y = "y",
#'       colour = "#334155",
#'       alpha = 0.9,
#'       width = 2
#'     )
#'   ),
#'   webgl = list(shader = "default", interactions = character())
#' )
#'
#' out <- tempfile(fileext = ".jpg")
#' compose_ggwebgl_figure(
#'   panels = list(
#'     point_spec,
#'     line_spec
#'   ),
#'   file = out,
#'   layout = "row",
#'   labels = c("points", "lines"),
#'   width = 480,
#'   height = 240,
#'   format = "jpeg",
#'   preset = "clean",
#'   wait_seconds = 0.25
#' )
#' file.exists(out)
compose_ggwebgl_figure <- function(panels,
                                   file,
                                   width = 1800L,
                                   height = 1200L,
                                   format = NULL,
                                   dpi = 300,
                                   background = "white",
                                   layout = c("single", "row", "grid"),
                                   labels = NULL,
                                   inset = NULL,
                                   annotations = NULL,
                                   preset = c("clean", "publication"),
                                   selfcontained = FALSE,
                                   wait_seconds = 3,
                                   nrow = NULL,
                                   ncol = NULL,
                                   elementId = NULL) {
  preset <- ggwebgl_normalise_publication_preset(preset)
  layout <- match.arg(layout)
  format <- ggwebgl_normalise_image_format(file, format)
  width <- ggwebgl_positive_integer(width, "width")
  height <- ggwebgl_positive_integer(height, "height")
  dpi <- ggwebgl_positive_integer(dpi, "dpi")
  wait_seconds <- ggwebgl_nonnegative_number(wait_seconds, "wait_seconds")
  file <- ggwebgl_output_path(file)

  ggwebgl_require_export_dependency("chromote")
  ggwebgl_require_export_dependency("magick")

  if (ggwebgl_can_use_publication_figure(panels, inset)) {
    figure <- ggwebgl_build_publication_figure_object(
      panels = panels,
      layout = layout,
      labels = labels,
      annotations = annotations,
      inset = inset,
      background = background,
      preset = preset,
      width = width,
      height = height,
      nrow = nrow,
      ncol = ncol
    )

    return(snapshot_ggwebgl(
      x = figure,
      file = file,
      width = width,
      height = height,
      format = format,
      dpi = dpi,
      background = background,
      preset = preset,
      selfcontained = selfcontained,
      wait_seconds = wait_seconds,
      elementId = elementId
    ))
  }

  ggwebgl_compose_legacy_figure(
    panels = panels,
    file = file,
    width = width,
    height = height,
    format = format,
    dpi = dpi,
    background = background,
    layout = layout,
    labels = labels,
    inset = inset,
    annotations = annotations,
    preset = preset,
    selfcontained = selfcontained,
    wait_seconds = wait_seconds,
    nrow = nrow,
    ncol = ncol,
    elementId = elementId
  )
}

ggwebgl_compose_legacy_figure <- function(panels,
                                          file,
                                          width,
                                          height,
                                          format,
                                          dpi,
                                          background,
                                          layout,
                                          labels,
                                          inset,
                                          annotations,
                                          preset,
                                          selfcontained,
                                          wait_seconds,
                                          nrow = NULL,
                                          ncol = NULL,
                                          elementId = NULL) {
  if (!is.list(panels) || !length(panels)) {
    rlang::abort("`panels` must be a non-empty list.")
  }

  layout_spec <- ggwebgl_layout_spec(
    n = length(panels),
    layout = layout,
    width = width,
    height = height,
    nrow = nrow,
    ncol = ncol
  )
  capture_result <- ggwebgl_with_chromote_browser(function(browser) {
    images <- lapply(seq_along(panels), function(i) {
      ggwebgl_capture_panel_image(
        panel = panels[[i]],
        width = layout_spec$cells[[i]]$width,
        height = layout_spec$cells[[i]]$height,
        background = background,
        preset = preset,
        selfcontained = isTRUE(selfcontained),
        wait_seconds = wait_seconds,
        elementId = elementId,
        browser = browser
      )
    })

    inset_overlay <- NULL
    if (!is.null(inset)) {
      inset_spec <- ggwebgl_normalise_inset(inset, width = width, height = height)
      inset_overlay <- compact_list(list(
        image = ggwebgl_capture_panel_image(
          panel = inset_spec$panel,
          width = inset_spec$width,
          height = inset_spec$height,
          background = background,
          preset = inset_spec$preset %||% preset,
          selfcontained = isTRUE(selfcontained),
          wait_seconds = inset_spec$wait_seconds %||% wait_seconds,
          elementId = elementId,
          browser = browser
        ),
        left = inset_spec$left,
        top = inset_spec$top,
        width = inset_spec$width,
        height = inset_spec$height,
        border = inset_spec$border,
        border_colour = inset_spec$border_colour,
        border_alpha = inset_spec$border_alpha
      ))
    }

    list(images = images, inset_overlay = inset_overlay)
  })
  images <- capture_result$images

  canvas <- magick::image_blank(width = width, height = height, color = background)
  for (i in seq_along(images)) {
    cell <- layout_spec$cells[[i]]
    image <- magick::image_resize(images[[i]], sprintf("%dx%d!", cell$width, cell$height))
    canvas <- magick::image_composite(
      canvas,
      image,
      offset = sprintf("+%d+%d", cell$left, cell$top)
    )
  }

  canvas <- ggwebgl_overlay_export_graphics(
    image = canvas,
    cells = layout_spec$cells,
    labels = labels,
    annotations = annotations,
    inset = capture_result$inset_overlay,
    preset = preset
  )

  ggwebgl_write_image(
    image = canvas,
    file = file,
    format = format,
    width = width,
    height = height,
    dpi = dpi,
    background = background
  )
}

ggwebgl_require_export_dependency <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    rlang::abort(
      sprintf(
        "The '%s' package is required for ggWebGL static export. Install it to use this feature.",
        package
      )
    )
  }
}

ggwebgl_output_path <- function(file) {
  file <- path.expand(as.character(file)[[1L]])
  dir <- dirname(file)

  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }

  normalizePath(file, winslash = "/", mustWork = FALSE)
}

ggwebgl_can_use_publication_figure <- function(panels, inset = NULL) {
  if (!is.list(panels) || !length(panels)) {
    return(FALSE)
  }

  panel_ok <- all(vapply(panels, function(panel) {
    source <- ggwebgl_normalise_panel(panel)$source
    ggwebgl_is_publication_source(source)
  }, logical(1)))

  if (!panel_ok) {
    return(FALSE)
  }

  if (is.null(inset)) {
    return(TRUE)
  }

  inset_source <- inset$panel %||% inset$source %||% inset$x %||% inset$item %||% NULL
  !is.null(inset_source) && ggwebgl_is_publication_source(inset_source)
}

ggwebgl_build_publication_figure_object <- function(panels,
                                                    layout,
                                                    labels = NULL,
                                                    annotations = NULL,
                                                    inset = NULL,
                                                    background = "white",
                                                    preset = "clean",
                                                    width = NULL,
                                                    height = NULL,
                                                    nrow = NULL,
                                                    ncol = NULL) {
  spec <- ggwebgl_normalise_publication_figure(
    panels = panels,
    layout = layout,
    labels = labels,
    annotations = annotations,
    inset = inset,
    background = background,
    preset = preset,
    width = width,
    height = height,
    nrow = nrow,
    ncol = ncol
  )
  figure <- ggwebgl_build_publication_figure_html(spec, width = width, height = height)
  attr(figure, "ggwebgl_publication_figure_spec") <- spec
  class(figure) <- unique(c("ggwebgl_publication_figure", class(figure)))
  figure
}

ggwebgl_positive_integer <- function(x, name) {
  value <- suppressWarnings(as.integer(x)[[1L]])

  if (!is.finite(value) || is.na(value) || value <= 0L) {
    rlang::abort(sprintf("`%s` must be a positive integer scalar.", name))
  }

  value
}

ggwebgl_nonnegative_number <- function(x, name) {
  value <- suppressWarnings(as.numeric(x)[[1L]])

  if (!is.finite(value) || is.na(value) || value < 0) {
    rlang::abort(sprintf("`%s` must be a non-negative numeric scalar.", name))
  }

  value
}

ggwebgl_normalise_image_format <- function(file, format) {
  if (is.null(format)) {
    ext <- tolower(tools::file_ext(file))
    format <- switch(
      ext,
      jpg = "jpeg",
      jpeg = "jpeg",
      png = "png",
      ""
    )
  }

  format <- tolower(as.character(format)[[1L]] %||% "")

  switch(
    format,
    jpg = "jpeg",
    jpeg = "jpeg",
    png = "png",
    rlang::abort("`format` must be one of 'png' or 'jpeg', or inferable from `file`.")
  )
}

ggwebgl_as_widget <- function(x, width, height, elementId = NULL) {
  if (inherits(x, "ggwebgl_publication_figure")) {
    rlang::abort("Use `snapshot_ggwebgl()` directly on `ggwebgl_publication_figure()` objects.")
  }

  if (inherits(x, "ggplot")) {
    return(ggplot_webgl(x, width = width, height = height, elementId = elementId))
  }

  if (inherits(x, "htmlwidget")) {
    if (!inherits(x, "ggWebGL")) {
      rlang::abort("`x` must be a ggWebGL htmlwidget when passing an existing widget.")
    }
    x$width <- width
    x$height <- height
    return(x)
  }

  ggWebGL(x = x, width = width, height = height, elementId = elementId)
}

ggwebgl_export_css <- function(width, height, preset, show_panel_overlay) {
  hidden <- c(
    ".ggwebgl__header",
    ".ggwebgl__axes",
    ".ggwebgl__notes",
    ".ggwebgl__tooltip",
    ".ggwebgl__empty"
  )

  if (!isTRUE(show_panel_overlay)) {
    hidden <- c(hidden, ".ggwebgl__panel-overlay")
  }

  css <- c(
    sprintf(
      "html, body { margin:0; padding:0; width:%dpx; height:%dpx; overflow:hidden; background:#ffffff; }",
      width,
      height
    ),
    sprintf(
      ".ggwebgl-host, .ggwebgl { width:%dpx !important; height:%dpx !important; margin:0 !important; padding:0 !important; border:0 !important; background:#ffffff !important; box-shadow:none !important; }",
      width,
      height
    ),
    paste0(paste(hidden, collapse = ", "), " { display:none !important; }"),
    sprintf(
      ".ggwebgl__stage { position:absolute !important; inset:0 !important; width:%dpx !important; height:%dpx !important; border:0 !important; border-radius:0 !important; background:#ffffff !important; box-shadow:none !important; }",
      width,
      height
    ),
    sprintf(
      ".ggwebgl__canvas { width:%dpx !important; height:%dpx !important; background:#ffffff !important; }",
      width,
      height
    )
  )

  if (identical(preset, "publication")) {
    css <- c(
      css,
      ".ggwebgl__panel-frame { border:1px solid rgba(51, 65, 85, 0.30) !important; background:transparent !important; }",
      ".ggwebgl__panel-strip { font: 500 15px Helvetica, Arial, sans-serif !important; letter-spacing:0.03em !important; color:rgba(51, 65, 85, 0.62) !important; background:rgba(255,255,255,0.72) !important; border:0 !important; padding:3px 7px !important; }"
    )
  }

  paste(css, collapse = "\n")
}

ggwebgl_capture_html_image <- function(content,
                                       width,
                                       height,
                                       wait_seconds,
                                       browser = NULL) {
  tmp_dir <- tempfile("ggwebgl-export-html-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  html_file <- file.path(tmp_dir, "figure.html")
  png_file <- file.path(tmp_dir, "figure.png")

  content <- htmltools::tagList(
    content,
    htmltools::tags$script(htmltools::HTML(sprintf(
      "setTimeout(function() { window.__ggwebgl_capture_ready = true; }, %d);",
      as.integer(wait_seconds * 1000)
    )))
  )
  htmltools::save_html(
    html = content,
    file = html_file,
    background = "white",
    libdir = file.path(tmp_dir, "libs")
  )

  if (is.null(browser)) {
    return(ggwebgl_with_chromote_browser(function(browser) {
      ggwebgl_capture_html_image(
        content = content,
        width = width,
        height = height,
        wait_seconds = wait_seconds,
        browser = browser
      )
    }))
  }

  ggwebgl_with_chromote_session(
    browser = browser,
    width = width,
    height = height,
    code = function(session) {
      session$Page$navigate(paste0("file://", normalizePath(html_file, winslash = "/", mustWork = TRUE)))

      for (i in seq_len(140L)) {
        Sys.sleep(0.1)
        ready <- tryCatch(
          session$Runtime$evaluate("window.__ggwebgl_capture_ready === true")$result$value,
          error = function(e) FALSE
        )
        if (isTRUE(ready)) {
          break
        }
      }
      Sys.sleep(0.4)

      session$screenshot(
        filename = png_file,
        selector = "body",
        cliprect = c(0, 0, width, height),
        delay = 0.2
      )
    }
  )

  magick::image_read(png_file)
}

ggwebgl_capture_widget_image <- function(widget,
                                         width,
                                         height,
                                         preset,
                                         selfcontained,
                                         wait_seconds,
                                         show_panel_overlay,
                                         browser = NULL) {
  tmp_dir <- tempfile("ggwebgl-export-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  html_file <- file.path(tmp_dir, "widget.html")
  png_file <- file.path(tmp_dir, "widget.png")

  css <- ggwebgl_export_css(
    width = width,
    height = height,
    preset = preset,
    show_panel_overlay = show_panel_overlay
  )
  widget <- htmlwidgets::prependContent(widget, htmltools::tags$style(htmltools::HTML(css)))
  widget <- htmlwidgets::onRender(
    widget,
    sprintf(
      "function(el, x) { setTimeout(function() { window.__ggwebgl_capture_ready = true; }, %d); }",
      as.integer(wait_seconds * 1000)
    )
  )
  htmlwidgets::saveWidget(widget, file = html_file, selfcontained = selfcontained)

  if (is.null(browser)) {
    return(ggwebgl_with_chromote_browser(function(browser) {
      ggwebgl_capture_widget_image(
        widget = widget,
        width = width,
        height = height,
        preset = preset,
        selfcontained = selfcontained,
        wait_seconds = wait_seconds,
        show_panel_overlay = show_panel_overlay,
        browser = browser
      )
    }))
  }

  ggwebgl_with_chromote_session(
    browser = browser,
    width = width,
    height = height,
    code = function(session) {
      session$Page$navigate(paste0("file://", normalizePath(html_file, winslash = "/", mustWork = TRUE)))

      for (i in seq_len(140L)) {
        Sys.sleep(0.1)
        ready <- tryCatch(
          session$Runtime$evaluate("window.__ggwebgl_capture_ready === true")$result$value,
          error = function(e) FALSE
        )
        if (isTRUE(ready)) {
          break
        }
      }
      Sys.sleep(0.5)

      session$screenshot(
        filename = png_file,
        selector = "body",
        cliprect = c(0, 0, width, height),
        delay = 0.2
      )
    }
  )

  magick::image_read(png_file)
}

ggwebgl_with_chromote_browser <- function(code) {
  browser <- NULL

  on.exit(
    {
      if (!is.null(browser)) {
        ggwebgl_close_chromote_browser(browser)
      }
      if (ggwebgl_should_reset_processx_supervisor()) {
        ggwebgl_reset_processx_supervisor()
      }
    },
    add = TRUE
  )

  browser <- tryCatch(
    chromote::Chromote$new(),
    error = function(e) {
      rlang::abort(paste("Failed to start a browser session for ggWebGL export:", conditionMessage(e)))
    }
  )

  code(browser)
}

ggwebgl_close_chromote_browser <- function(browser) {
  if (is.null(browser)) {
    return(invisible(FALSE))
  }

  ok <- tryCatch(
    {
      browser$close(wait = TRUE)
      TRUE
    },
    error = function(e) FALSE
  )
  if (!ok) {
    try(browser$close(), silent = TRUE)
  }

  invisible(ok)
}

ggwebgl_should_reset_processx_supervisor <- function() {
  isTRUE(getOption("ggwebgl.reset_processx_supervisor"))
}

ggwebgl_reset_processx_supervisor <- function() {
  if (!requireNamespace("processx", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  reset <- get0("supervisor_reset", envir = asNamespace("processx"), inherits = FALSE)
  if (is.function(reset)) {
    try(reset(), silent = TRUE)
  } else {
    try(processx::supervisor_kill(), silent = TRUE)
  }
  ggwebgl_close_supervisor_connections()
  gc(verbose = FALSE)
  Sys.sleep(0.05)
  invisible(TRUE)
}

ggwebgl_close_supervisor_connections <- function() {
  connections <- showConnections(all = TRUE)
  if (is.null(connections) || !nrow(connections)) {
    return(invisible(FALSE))
  }

  ids <- rownames(connections)[grepl("supervisor_(stdin|stdout)", connections[, "description"])]
  if (!length(ids)) {
    return(invisible(FALSE))
  }

  for (id in ids) {
    try(close(getConnection(as.integer(id))), silent = TRUE)
  }

  invisible(TRUE)
}

ggwebgl_with_chromote_session <- function(browser, width, height, code) {
  session <- NULL

  on.exit(
    {
      if (!is.null(session)) {
        ggwebgl_close_chromote_session(session)
      }
    },
    add = TRUE
  )

  session <- tryCatch(
    browser$new_session(width = width, height = height, wait_ = TRUE),
    error = function(e) {
      rlang::abort(paste("Failed to create a browser tab for ggWebGL export:", conditionMessage(e)))
    }
  )

  session$Emulation$setDeviceMetricsOverride(
    width = width,
    height = height,
    deviceScaleFactor = 1,
    mobile = FALSE
  )

  code(session)
}

ggwebgl_close_chromote_session <- function(session) {
  if (is.null(session)) {
    return(invisible(FALSE))
  }

  ok <- tryCatch(
    {
      session$close()
      TRUE
    },
    error = function(e) FALSE
  )

  invisible(ok)
}

ggwebgl_write_image <- function(image,
                                file,
                                format,
                                width,
                                height,
                                dpi,
                                background) {
  image <- magick::image_background(image, background, flatten = TRUE)
  image <- magick::image_resize(image, sprintf("%dx%d!", width, height))
  args <- compact_list(list(
    image = image,
    path = file,
    format = format,
    density = sprintf("%dx%d", dpi, dpi),
    quality = if (identical(format, "jpeg")) 96 else NULL
  ))
  do.call(magick::image_write, args)
  invisible(normalizePath(file, winslash = "/", mustWork = TRUE))
}

ggwebgl_layout_spec <- function(n, layout, width, height, nrow = NULL, ncol = NULL) {
  if (identical(layout, "single")) {
    return(list(
      rows = 1L,
      cols = 1L,
      cells = list(list(left = 0L, top = 0L, width = width, height = height))
    ))
  }

  if (identical(layout, "row")) {
    cols <- as.integer(n)
    cell_width <- floor(width / cols)
    return(list(
      rows = 1L,
      cols = cols,
      cells = lapply(seq_len(cols), function(i) {
        compact_list(list(
          left = as.integer((i - 1L) * cell_width),
          top = 0L,
          width = if (i < cols) cell_width else width - as.integer((i - 1L) * cell_width),
          height = height
        ))
      })
    ))
  }

  if (!is.null(ncol)) {
    cols <- ggwebgl_positive_integer(ncol, "ncol")
    rows <- as.integer(ceiling(n / cols))
  } else if (!is.null(nrow)) {
    rows <- ggwebgl_positive_integer(nrow, "nrow")
    cols <- as.integer(ceiling(n / rows))
  } else if (n <= 4L) {
    cols <- min(2L, n)
    rows <- as.integer(ceiling(n / cols))
  } else {
    cols <- min(3L, n)
    rows <- as.integer(ceiling(n / cols))
  }

  cell_width <- floor(width / cols)
  cell_height <- floor(height / rows)

  cells <- lapply(seq_len(n), function(i) {
    row <- (i - 1L) %/% cols
    col <- (i - 1L) %% cols
    left <- as.integer(col * cell_width)
    top <- as.integer(row * cell_height)
    compact_list(list(
      left = left,
      top = top,
      width = if (col < cols - 1L) cell_width else width - left,
      height = if (row < rows - 1L) cell_height else height - top
    ))
  })

  list(rows = rows, cols = cols, cells = cells)
}

ggwebgl_capture_panel_image <- function(panel,
                                        width,
                                        height,
                                        background,
                                        preset,
                                        selfcontained,
                                        wait_seconds,
                                        elementId,
                                        browser = NULL) {
  panel_spec <- ggwebgl_normalise_panel(panel)
  source <- panel_spec$source

  if (inherits(source, "magick-image")) {
    return(magick::image_resize(source, sprintf("%dx%d!", width, height)))
  }

  if (is.character(source) && length(source) == 1L && file.exists(source)) {
    return(magick::image_resize(magick::image_read(source), sprintf("%dx%d!", width, height)))
  }

    image <- ggwebgl_capture_widget_image(
      widget = ggwebgl_as_widget(source, width = width, height = height, elementId = elementId),
      width = width,
      height = height,
      preset = panel_spec$preset %||% preset,
      selfcontained = selfcontained,
      wait_seconds = panel_spec$wait_seconds %||% wait_seconds,
      show_panel_overlay = panel_spec$show_panel_overlay %||% FALSE,
      browser = browser
    )

  magick::image_background(image, background, flatten = TRUE)
}

ggwebgl_normalise_panel <- function(panel) {
  if (is.list(panel) && !inherits(panel, "data.frame") && any(c("source", "x", "item") %in% names(panel))) {
    return(compact_list(list(
      source = panel$source %||% panel$x %||% panel$item,
      preset = panel$preset %||% NULL,
      wait_seconds = panel$wait_seconds %||% NULL,
      show_panel_overlay = panel$show_panel_overlay %||% NULL
    )))
  }

  list(source = panel)
}

ggwebgl_normalise_inset <- function(inset, width, height) {
  if (!is.list(inset) || !any(c("source", "x", "item", "panel") %in% names(inset))) {
    rlang::abort("`inset` must be a list containing a panel source and placement metadata.")
  }

  left <- as.numeric(inset$left %||% inset$x %||% NA_real_)
  top <- as.numeric(inset$top %||% inset$y %||% NA_real_)
  inset_width <- as.numeric(inset$width %||% NA_real_)
  inset_height <- as.numeric(inset$height %||% NA_real_)

  if (any(!is.finite(c(left, top, inset_width, inset_height)))) {
    rlang::abort("`inset` must define finite fractional `left`, `top`, `width`, and `height` values.")
  }

  compact_list(list(
    panel = inset$panel %||% inset$source %||% inset$x %||% inset$item,
    left = as.integer(round(left * width)),
    top = as.integer(round(top * height)),
    width = as.integer(round(inset_width * width)),
    height = as.integer(round(inset_height * height)),
    border = inset$border %||% TRUE,
    border_colour = as.character(inset$border_colour %||% "#334155")[[1L]],
    border_alpha = as.numeric(inset$border_alpha %||% 0.35)[[1L]],
    preset = inset$preset %||% NULL,
    wait_seconds = inset$wait_seconds %||% NULL
  ))
}

ggwebgl_overlay_export_graphics <- function(image, cells, labels, annotations, inset, preset) {
  dims <- ggwebgl_image_dimensions(image)
  image <- magick::image_draw(image)
  op <- graphics::par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
  on.exit(graphics::par(op), add = TRUE)

  if (identical(preset, "publication") && length(cells) > 1L) {
    for (cell in cells) {
      graphics::rect(
        cell$left + 1,
        cell$top + 1,
        cell$left + cell$width - 1,
        cell$top + cell$height - 1,
        border = grDevices::adjustcolor("#334155", alpha.f = 0.22),
        lwd = 1
      )
    }
  }

  if (!is.null(labels)) {
    label_values <- as.character(labels)
    if (length(label_values) != length(cells)) {
      rlang::abort("`labels` must have the same length as `panels`.")
    }

    for (i in seq_along(cells)) {
      graphics::text(
        x = cells[[i]]$left + 18,
        y = cells[[i]]$top + 30,
        labels = label_values[[i]],
        adj = c(0, 0.5),
        cex = 1.05,
        family = "sans",
        col = grDevices::adjustcolor("#475569", alpha.f = if (identical(preset, "publication")) 0.70 else 0.85)
      )
    }
  }

  if (!is.null(inset)) {
    inset_image <- magick::image_resize(inset$image, sprintf("%dx%d!", inset$width, inset$height))
    graphics::rasterImage(
      grDevices::as.raster(inset_image),
      xleft = inset$left,
      ybottom = inset$top,
      xright = inset$left + inset$width,
      ytop = inset$top + inset$height,
      interpolate = TRUE
    )

    if (isTRUE(inset$border)) {
      graphics::rect(
        inset$left,
        inset$top,
        inset$left + inset$width,
        inset$top + inset$height,
        border = grDevices::adjustcolor(inset$border_colour, alpha.f = inset$border_alpha),
        lwd = 1
      )
    }
  }

  if (!is.null(annotations)) {
    for (annotation in annotations) {
      if (!is.list(annotation) || is.null(annotation$text)) {
        rlang::abort("Each `annotations` entry must be a list containing at least `text`, `x`, and `y`.")
      }

      graphics::text(
        x = as.numeric(annotation$x) * dims$width,
        y = as.numeric(annotation$y) * dims$height,
        labels = as.character(annotation$text)[[1L]],
        adj = c(as.numeric(annotation$hjust %||% 0), as.numeric(annotation$vjust %||% 0.5)),
        cex = as.numeric(annotation$size %||% 24) / 28,
        family = as.character(annotation$font %||% "sans")[[1L]],
        col = as.character(annotation$colour %||% "#64748b")[[1L]]
      )
    }
  }

  grDevices::dev.off()
  image
}

ggwebgl_image_dimensions <- function(image) {
  info <- magick::image_info(image)
  list(
    width = as.integer(info$width[[1L]]),
    height = as.integer(info$height[[1L]])
  )
}
