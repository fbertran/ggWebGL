normalise_timeline_filter <- function(filter) {
  value <- tolower(as.character(filter)[[1L]] %||% "exact")
  if (!value %in% c("exact", "cumulative")) {
    rlang::abort("Timeline `filter`/`mode` must be either \"exact\" or \"cumulative\".")
  }

  value
}

normalise_timeline_speed <- function(speed) {
  value <- suppressWarnings(as.numeric(speed)[[1L]])
  if (!is.finite(value) || value <= 0) {
    rlang::abort("Timeline `speed` must be a finite positive number.")
  }

  value
}

normalise_timeline_fps <- function(fps) {
  value <- suppressWarnings(as.numeric(fps)[[1L]])
  if (!is.finite(value) || value <= 0) {
    rlang::abort("Timeline `fps` must be a finite positive number.")
  }

  value
}

normalise_timeline_source <- function(source, allow_auto = TRUE) {
  choices <- if (isTRUE(allow_auto)) c("auto", "frame", "time") else c("frame", "time")
  value <- tolower(as.character(source)[[1L]] %||% choices[[1L]])
  if (!value %in% choices) {
    rlang::abort(paste0(
      "Timeline `source` must be ",
      if (isTRUE(allow_auto)) "\"auto\", \"frame\", or \"time\"." else "\"frame\" or \"time\"."
    ))
  }

  value
}

normalise_timeline_values <- function(values, source = c("frame", "time")) {
  if (is.null(values)) {
    return(NULL)
  }

  source <- normalise_timeline_source(source, allow_auto = FALSE)
  values <- suppressWarnings(as.numeric(values))
  values <- sort(unique(values[is.finite(values)]))
  if (identical(source, "frame")) {
    values <- as.integer(values)
  }

  unname(values)
}

normalise_timeline_value_source <- function(source = "auto", values = NULL, frames = NULL, time = NULL) {
  source <- normalise_timeline_source(source, allow_auto = TRUE)
  if (!identical(source, "auto")) {
    return(source)
  }

  if (length(time)) {
    return("time")
  }
  if (length(frames)) {
    return("frame")
  }
  if (length(values)) {
    numeric_values <- suppressWarnings(as.numeric(values))
    numeric_values <- numeric_values[is.finite(numeric_values)]
    if (length(numeric_values) && any(abs(numeric_values - round(numeric_values)) > .Machine$double.eps^0.5)) {
      return("time")
    }
  }

  "frame"
}

timeline_has_values <- function(timeline) {
  timeline <- normalise_timeline(timeline)
  if (is.null(timeline)) {
    return(FALSE)
  }

  length(timeline$frames %||% timeline$time %||% timeline$values %||% numeric()) > 0L
}

#' Build Animation Timeline Metadata
#'
#' `animation_spec()` is a user-facing alias for [ggwebgl_timeline()]. It keeps
#' one canonical timeline contract while providing a concise name for animation
#' examples and adapter code.
#'
#' @inheritParams ggwebgl_timeline
#' @return A `ggwebgl_timeline` list.
#'
#' @examples
#' animation_spec(frames = 1:3, autoplay = FALSE)
#' @export
animation_spec <- function(...) {
  ggwebgl_timeline(...)
}

#' Add Timeline Metadata to a ggplot
#'
#' `scale_time_webgl()` is not a visual ggplot2 scale. It records timeline
#' metadata for [ggplot_webgl()] so frame or time values can be normalized into
#' `render$timeline`.
#'
#' @param source Timeline column source. `"auto"` prefers a built `time` column
#'   when present and otherwise uses `frame`.
#' @param values Optional explicit timeline values. When omitted, values are
#'   derived from built layer `time` or `frame` columns.
#' @param mode Timeline filtering intent: `"exact"` or `"cumulative"`.
#' @param fps Optional frames-per-second metadata.
#' @param speed Positive playback-speed multiplier.
#' @param loop Whether future playback controls should loop.
#' @param label Optional timeline label metadata.
#' @param format Optional display-format metadata.
#'
#' @return An object that can be added to a `ggplot`.
#'
#' @examples
#' df <- data.frame(x = c(0, 1, 2), y = c(0, 1, 0), frame = 1:3)
#' plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, frame = frame)) +
#'   geom_point_webgl() +
#'   scale_time_webgl(source = "frame", mode = "exact")
#' plot$ggwebgl$time_scale$source
#' @export
scale_time_webgl <- function(source = c("auto", "frame", "time"),
                             values = NULL,
                             mode = c("exact", "cumulative"),
                             fps = NULL,
                             speed = 1,
                             loop = FALSE,
                             label = NULL,
                             format = NULL) {
  source <- normalise_timeline_source(source, allow_auto = TRUE)
  mode <- normalise_timeline_filter(mode)

  out <- compact_list(list(
    source = source,
    values = if (is.null(values)) NULL else unname(as.numeric(values)),
    mode = mode,
    filter = mode,
    fps = if (is.null(fps)) NULL else normalise_timeline_fps(fps),
    speed = normalise_timeline_speed(speed),
    loop = isTRUE(loop),
    label = label,
    format = format
  ))
  class(out) <- "ggwebgl_time_scale"
  out
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.ggwebgl_time_scale <- function(object, plot, object_name) {
  current <- webgl_explicit_options(plot$ggwebgl %||% NULL)
  current$time_scale <- object
  attr(current, "explicit_fields") <- unique(c(webgl_explicit_fields(current), "time_scale"))
  plot$ggwebgl <- normalise_webgl_options(current)
  plot
}

normalise_time_scale <- function(time_scale) {
  if (is.null(time_scale)) {
    return(NULL)
  }

  if (inherits(time_scale, "ggwebgl_time_scale")) {
    time_scale <- unclass(time_scale)
  }

  if (!is.list(time_scale)) {
    rlang::abort("`time_scale` must be produced by `scale_time_webgl()`.")
  }

  source <- normalise_timeline_source(time_scale[["source"]] %||% "auto", allow_auto = TRUE)
  mode <- normalise_timeline_filter(time_scale[["mode"]] %||% time_scale[["filter"]] %||% "exact")

  out <- compact_list(list(
    source = source,
    values = if (is.null(time_scale[["values"]])) NULL else unname(as.numeric(time_scale[["values"]])),
    mode = mode,
    filter = mode,
    fps = if (is.null(time_scale[["fps"]])) NULL else normalise_timeline_fps(time_scale[["fps"]]),
    speed = normalise_timeline_speed(time_scale[["speed"]] %||% 1),
    loop = isTRUE(time_scale[["loop"]] %||% FALSE),
    label = time_scale[["label"]] %||% NULL,
    format = time_scale[["format"]] %||% NULL
  ))
  class(out) <- "ggwebgl_time_scale"
  out
}

timeline_values_from_render <- function(render, source = "auto") {
  source <- normalise_timeline_source(source, allow_auto = TRUE)
  panels <- render$panels %||% list()
  frame_values <- numeric()
  time_values <- numeric()

  for (panel in panels) {
    layers <- panel$layers %||% list()
    for (layer in layers) {
      collected <- timeline_values_from_layer(layer)
      frame_values <- c(frame_values, collected$frame)
      time_values <- c(time_values, collected$time)
    }
  }

  if (identical(source, "time") || (identical(source, "auto") && length(time_values))) {
    values <- normalise_timeline_values(time_values, "time")
    if (length(values)) {
      return(list(source = "time", values = values))
    }
  }

  if (identical(source, "frame") || identical(source, "auto")) {
    values <- normalise_timeline_values(frame_values, "frame")
    if (length(values)) {
      return(list(source = "frame", values = values))
    }
  }

  list(source = NULL, values = NULL)
}

timeline_values_from_layer <- function(layer) {
  frame_values <- numeric()
  time_values <- numeric()

  if (!is.null(layer$frame)) {
    frame_values <- c(frame_values, layer$frame)
  }
  if (!is.null(layer$time)) {
    time_values <- c(time_values, layer$time)
  }
  if (!is.null(layer$paths) && is.list(layer$paths)) {
    for (path in layer$paths) {
      if (!is.null(path$frame)) {
        frame_values <- c(frame_values, path$frame)
      }
      if (!is.null(path$time)) {
        time_values <- c(time_values, path$time)
      }
    }
  }

  list(frame = frame_values, time = time_values)
}

timeline_from_time_scale <- function(time_scale, render) {
  time_scale <- normalise_time_scale(time_scale)
  if (is.null(time_scale)) {
    return(NULL)
  }

  source <- time_scale$source %||% "auto"
  if (!is.null(time_scale$values)) {
    source <- normalise_timeline_value_source(source, values = time_scale$values)
    derived <- list(source = source, values = normalise_timeline_values(time_scale$values, source))
  } else {
    derived <- timeline_values_from_render(render, source = source)
  }

  if (!length(derived$values %||% numeric())) {
    return(NULL)
  }

  normalise_timeline(compact_list(list(
    frames = if (identical(derived$source, "frame")) derived$values else NULL,
    time = if (identical(derived$source, "time")) derived$values else NULL,
    source = derived$source,
    loop = time_scale$loop,
    speed = time_scale$speed,
    filter = time_scale$mode %||% time_scale$filter,
    fps = time_scale$fps %||% NULL,
    label = time_scale$label %||% NULL,
    format = time_scale$format %||% NULL
  )))
}

ggwebgl_complete_timeline <- function(webgl, render) {
  webgl <- normalise_webgl_options(webgl)
  timeline <- normalise_timeline(webgl$timeline %||% NULL)

  if (timeline_has_values(timeline)) {
    webgl$timeline <- timeline
    return(webgl)
  }

  time_scale_timeline <- timeline_from_time_scale(webgl$time_scale %||% NULL, render)
  if (!is.null(time_scale_timeline)) {
    if (!is.null(timeline)) {
      time_scale_timeline <- utils::modifyList(time_scale_timeline, timeline)
      time_scale_timeline <- normalise_timeline(time_scale_timeline)
    }
    webgl$timeline <- time_scale_timeline
    return(webgl)
  }

  derived <- timeline_values_from_render(render, source = "auto")
  if (length(derived$values %||% numeric())) {
    base <- timeline %||% list()
    base[[if (identical(derived$source, "time")) "time" else "frames"]] <- derived$values
    base$source <- derived$source
    webgl$timeline <- normalise_timeline(base)
  } else if (!is.null(timeline)) {
    webgl$timeline <- timeline
  }

  webgl
}
