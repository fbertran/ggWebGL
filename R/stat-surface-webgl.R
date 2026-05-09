StatSurfaceWebGL <- ggplot2::ggproto(
  "StatSurfaceWebGL",
  ggplot2::Stat,
  required_aes = c("x", "y", "z"),
  compute_panel = function(data, scales, na.rm = FALSE) {
    if (!nrow(data)) {
      return(data)
    }

    required <- c("x", "y", "z")
    if (!all(required %in% names(data))) {
      rlang::abort("Surface layers require `x`, `y`, and `z` aesthetics.")
    }

    keep <- stats::complete.cases(data[, required, drop = FALSE])
    if (!all(keep)) {
      if (!isTRUE(na.rm)) {
        rlang::warn("Removed rows with missing surface coordinates or z values.")
      }
      data <- data[keep, , drop = FALSE]
    }
    if (!nrow(data)) {
      return(data)
    }

    x_values <- sort(unique(as.numeric(data$x)))
    y_values <- sort(unique(as.numeric(data$y)))
    if (length(x_values) < 2L || length(y_values) < 2L) {
      rlang::abort("Surface layers require at least two unique x and y coordinates.")
    }

    keys <- paste(as.numeric(data$x), as.numeric(data$y), sep = "\r")
    if (anyDuplicated(keys)) {
      rlang::abort("Surface layers require a single z value for each x/y grid cell.")
    }
    if (length(keys) != length(x_values) * length(y_values)) {
      rlang::abort("Surface layers require a complete regular x/y grid; missing cells are not interpolated.")
    }

    x_index <- match(as.numeric(data$x), x_values)
    y_index <- match(as.numeric(data$y), y_values)
    data[order(y_index, x_index), , drop = FALSE]
  }
)

#' WebGL Structured Grid Surface Stat
#'
#' Validate and order regular `(x, y, z)` triples for
#' [geom_surface_webgl()]. Missing or duplicate cells are rejected because
#' structured surfaces are triangulated without interpolation.
#'
#' @inheritParams ggplot2::stat_identity
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' surface <- expand.grid(x = 1:3, y = 1:3)
#' surface$z <- with(surface, x * y)
#' ggplot2::ggplot(surface, ggplot2::aes(x, y, z = z)) +
#'   stat_surface_webgl()
#' @export
stat_surface_webgl <- function(mapping = NULL,
                               data = NULL,
                               geom = GeomSurfaceWebGL,
                               position = "identity",
                               ...,
                               na.rm = FALSE,
                               show.legend = NA,
                               inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = StatSurfaceWebGL,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, ...)
  )
}
