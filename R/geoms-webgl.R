GeomPointWebGL <- ggplot2::ggproto(
  "GeomPointWebGL",
  ggplot2::GeomPoint,
  optional_aes = c(
    ggplot2::GeomPoint$optional_aes,
    "label",
    "text",
    "tooltip",
    "key",
    "sample_id",
    "point_id",
    "z",
    "frame",
    "time"
  )
)
GeomLineWebGL <- ggplot2::ggproto(
  "GeomLineWebGL",
  ggplot2::GeomLine,
  optional_aes = c(ggplot2::GeomLine$optional_aes, "z", "frame", "time")
)
GeomRasterWebGL <- ggplot2::ggproto("GeomRasterWebGL", ggplot2::GeomRaster)
GeomVectorWebGL <- ggplot2::ggproto(
  "GeomVectorWebGL",
  ggplot2::GeomSegment,
  optional_aes = c(ggplot2::GeomSegment$optional_aes, "z", "zend", "id", "frame", "time"),
  extra_params = c(ggplot2::GeomSegment$extra_params, "head_size")
)

#' WebGL Point Layer
#'
#' Add a point layer that is tagged for the `ggWebGL` rendering pipeline. The
#' layer is drawn through the browser WebGL renderer when passed to
#' [ggplot_webgl()].
#'
#' @inheritParams ggplot2::geom_point
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' point_plot <- ggplot2::ggplot(
#'   mtcars[1:8, ],
#'   ggplot2::aes(mpg, wt, colour = factor(cyl))
#' ) +
#'   geom_point_webgl(size = 2) +
#'   theme_webgl()
#'
#' point_plot
#' @export
geom_point_webgl <- function(mapping = NULL,
                             data = NULL,
                             stat = "identity",
                             position = "identity",
                             ...,
                             na.rm = FALSE,
                             show.legend = NA,
                             inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomPointWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, ...)
  )
}

#' WebGL Line Layer
#'
#' Add a line layer that is tagged for the `ggWebGL` rendering pipeline. The
#' layer is drawn through the browser WebGL renderer when passed to
#' [ggplot_webgl()].
#'
#' @inheritParams ggplot2::geom_line
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' line_data <- data.frame(
#'   x = c(1, 2, 3, 1, 2, 3),
#'   y = c(1, 2, 1, 2, 3, 2),
#'   group = c("a", "a", "a", "b", "b", "b")
#' )
#'
#' line_plot <- ggplot2::ggplot(
#'   line_data,
#'   ggplot2::aes(x, y, group = group, colour = group)
#' ) +
#'   geom_line_webgl(linewidth = 1) +
#'   theme_webgl(shader = "trajectory_age")
#'
#' line_plot
#' @export
geom_line_webgl <- function(mapping = NULL,
                            data = NULL,
                            stat = "identity",
                            position = "identity",
                            ...,
                            na.rm = FALSE,
                            orientation = NA,
                            show.legend = NA,
                            inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomLineWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, orientation = orientation, ...)
  )
}

#' WebGL Raster Layer
#'
#' Add a raster layer that is tagged for the `ggWebGL` rendering pipeline. The
#' layer is serialized into a texture-backed raster payload when passed to
#' [ggplot_webgl()].
#'
#' @inheritParams ggplot2::geom_raster
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' raster_data <- expand.grid(x = 1:3, y = 1:2)
#' raster_data$z <- with(raster_data, x + y)
#'
#' raster_plot <- ggplot2::ggplot(
#'   raster_data,
#'   ggplot2::aes(x, y, fill = z)
#' ) +
#'   geom_raster_webgl(interpolate = TRUE) +
#'   ggplot2::scale_fill_gradient(low = "#0f172a", high = "#38bdf8") +
#'   theme_webgl()
#'
#' raster_plot
#' @export
geom_raster_webgl <- function(mapping = NULL,
                              data = NULL,
                              stat = "identity",
                              position = "identity",
                              ...,
                              hjust = 0.5,
                              vjust = 0.5,
                              interpolate = FALSE,
                              na.rm = FALSE,
                              show.legend = NA,
                              inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRasterWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      hjust = hjust,
      vjust = vjust,
      interpolate = interpolate,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Vector Arrow Layer
#'
#' Add a 2D or 3D vector-arrow layer tagged for the `ggWebGL` renderer.
#'
#' @inheritParams ggplot2::geom_segment
#' @param head_size Arrowhead size in renderer pixels.
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' arrows <- data.frame(x = 1:3, y = 1:3, z = 0, xend = 1:3 + 0.3, yend = 1:3 + 0.2, zend = 0.2)
#' ggplot2::ggplot(arrows, ggplot2::aes(x, y, z = z, xend = xend, yend = yend, zend = zend)) +
#'   geom_vector_webgl()
#' @export
geom_vector_webgl <- function(mapping = NULL,
                              data = NULL,
                              stat = "identity",
                              position = "identity",
                              ...,
                              head_size = 9,
                              na.rm = FALSE,
                              show.legend = NA,
                              inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomVectorWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(head_size = head_size, na.rm = na.rm, ...)
  )
}
