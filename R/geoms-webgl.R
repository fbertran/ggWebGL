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
GeomPathWebGL <- ggplot2::ggproto(
  "GeomPathWebGL",
  ggplot2::GeomPath,
  optional_aes = c(ggplot2::GeomPath$optional_aes, "frame", "time")
)
GeomPath3DWebGL <- ggplot2::ggproto(
  "GeomPath3DWebGL",
  ggplot2::GeomPath,
  optional_aes = c(ggplot2::GeomPath$optional_aes, "z", "frame", "time")
)
GeomFreqpolyWebGL <- ggplot2::ggproto(
  "GeomFreqpolyWebGL",
  ggplot2::GeomPath,
  optional_aes = c(ggplot2::GeomPath$optional_aes, "fill", "frame", "time")
)
GeomDensityWebGL <- ggplot2::ggproto(
  "GeomDensityWebGL",
  ggplot2::GeomPath,
  optional_aes = c(ggplot2::GeomPath$optional_aes, "fill", "frame", "time")
)
GeomRasterWebGL <- ggplot2::ggproto("GeomRasterWebGL", ggplot2::GeomRaster)
GeomRectWebGL <- ggplot2::ggproto(
  "GeomRectWebGL",
  ggplot2::GeomRect,
  optional_aes = c(ggplot2::GeomRect$optional_aes, "frame", "time"),
  extra_params = c(ggplot2::GeomRect$extra_params, "lineend", "linejoin")
)
GeomTileWebGL <- ggplot2::ggproto(
  "GeomTileWebGL",
  ggplot2::GeomTile,
  optional_aes = c(ggplot2::GeomTile$optional_aes, "frame", "time"),
  extra_params = c(ggplot2::GeomTile$extra_params, "lineend", "linejoin")
)
GeomBarWebGL <- ggplot2::ggproto(
  "GeomBarWebGL",
  ggplot2::GeomBar,
  optional_aes = c(ggplot2::GeomBar$optional_aes, "frame", "time"),
  extra_params = c(ggplot2::GeomBar$extra_params, "lineend", "linejoin")
)
GeomBin2dWebGL <- ggplot2::ggproto(
  "GeomBin2dWebGL",
  ggplot2::GeomBin2d,
  optional_aes = c(ggplot2::GeomBin2d$optional_aes, "frame", "time"),
  extra_params = c(ggplot2::GeomBin2d$extra_params, "lineend", "linejoin")
)
GeomSegmentWebGL <- ggplot2::ggproto(
  "GeomSegmentWebGL",
  ggplot2::GeomSegment,
  optional_aes = c(ggplot2::GeomSegment$optional_aes, "z", "zend", "id", "frame", "time"),
  extra_params = c(ggplot2::GeomSegment$extra_params, "head_size")
)
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

#' WebGL Ordered Path Layer
#'
#' Add an ordered two-dimensional path layer tagged for the `ggWebGL` rendering
#' pipeline. Unlike [geom_line_webgl()], this geom is based on
#' `ggplot2::GeomPath` and preserves row order within each group.
#'
#' @inheritParams ggplot2::geom_path
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' path_data <- data.frame(
#'   x = c(3, 1, 2, 4),
#'   y = c(0.2, 0.8, 0.4, 0.6),
#'   frame = 1:4
#' )
#'
#' path_plot <- ggplot2::ggplot(
#'   path_data,
#'   ggplot2::aes(x, y, frame = frame)
#' ) +
#'   geom_path_webgl(linewidth = 1.2) +
#'   theme_webgl(shader = "trajectory_age")
#'
#' path_plot
#' @export
geom_path_webgl <- function(mapping = NULL,
                            data = NULL,
                            stat = "identity",
                            position = "identity",
                            ...,
                            lineend = "butt",
                            linejoin = "round",
                            linemitre = 10,
                            arrow = NULL,
                            na.rm = FALSE,
                            show.legend = NA,
                            inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomPathWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      lineend = lineend,
      linejoin = linejoin,
      linemitre = linemitre,
      arrow = arrow,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Ordered 3D Path Layer
#'
#' Add an ordered three-dimensional path layer that is tagged for the `ggWebGL`
#' rendering pipeline. Unlike [geom_line_webgl()], this geom is based on
#' `ggplot2::GeomPath` and preserves row order within each group.
#'
#' @inheritParams ggplot2::geom_path
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' path_data <- data.frame(
#'   x = c(0, 0.4, 0.2, 0.8),
#'   y = c(0, 0.3, 0.7, 1),
#'   z = c(0, 0.2, 0.5, 0.9),
#'   frame = 1:4
#' )
#'
#' path_plot <- ggplot2::ggplot(
#'   path_data,
#'   ggplot2::aes(x, y, z = z, frame = frame)
#' ) +
#'   geom_path3d_webgl(linewidth = 1.2) +
#'   theme_webgl(shader = "trajectory_age")
#'
#' path_plot
#' @export
geom_path3d_webgl <- function(mapping = NULL,
                              data = NULL,
                              stat = "identity",
                              position = "identity",
                              ...,
                              lineend = "butt",
                              linejoin = "round",
                              linemitre = 10,
                              arrow = NULL,
                              na.rm = FALSE,
                              show.legend = NA,
                              inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomPath3DWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      lineend = lineend,
      linejoin = linejoin,
      linemitre = linemitre,
      arrow = arrow,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Frequency Polygon Layer
#'
#' Add a frequency polygon layer tagged for the `ggWebGL` renderer. Binning is
#' delegated to `ggplot2::StatBin`; the WebGL layer consumes the built path
#' coordinates.
#'
#' @inheritParams ggplot2::geom_freqpoly
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' values <- data.frame(x = c(0.1, 0.2, 0.7, 1.2, 1.6, 2.1))
#'
#' ggplot2::ggplot(values, ggplot2::aes(x)) +
#'   geom_freqpoly_webgl(binwidth = 0.5, colour = "#2563eb")
#' @export
geom_freqpoly_webgl <- function(mapping = NULL,
                                data = NULL,
                                stat = "bin",
                                position = "identity",
                                ...,
                                na.rm = FALSE,
                                show.legend = NA,
                                inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomFreqpolyWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, ...)
  )
}

#' WebGL Density Curve Layer
#'
#' Add a density curve layer tagged for the `ggWebGL` renderer. Density
#' estimation is delegated to `ggplot2::StatDensity`; this geom serializes the
#' resulting curve as a line path. Filled densities are not rendered by this
#' layer.
#'
#' @inheritParams ggplot2::geom_density
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' values <- data.frame(x = seq(-2, 2, length.out = 40))
#'
#' ggplot2::ggplot(values, ggplot2::aes(x)) +
#'   geom_density_webgl(colour = "#0f766e")
#' @export
geom_density_webgl <- function(mapping = NULL,
                               data = NULL,
                               stat = "density",
                               position = "identity",
                               ...,
                               outline.type = "upper",
                               lineend = "butt",
                               linejoin = "round",
                               linemitre = 10,
                               na.rm = FALSE,
                               show.legend = NA,
                               inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomDensityWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      lineend = lineend,
      linejoin = linejoin,
      linemitre = linemitre,
      na.rm = na.rm,
      ...
    )
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

#' WebGL Rectangle Layer
#'
#' Add a rectangle layer tagged for the `ggWebGL` renderer. Boundaries are taken
#' from the data built by `ggplot2`, so `xmin`, `xmax`, `ymin`, and `ymax`
#' follow the same setup rules as [ggplot2::geom_rect()].
#'
#' @inheritParams ggplot2::geom_rect
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' rects <- data.frame(
#'   xmin = c(0, 1.2),
#'   xmax = c(0.8, 2),
#'   ymin = c(0, 0.4),
#'   ymax = c(1, 1.4),
#'   group = c("a", "b")
#' )
#'
#' ggplot2::ggplot(
#'   rects,
#'   ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = group)
#' ) +
#'   geom_rect_webgl(alpha = 0.7)
#' @export
geom_rect_webgl <- function(mapping = NULL,
                            data = NULL,
                            stat = "identity",
                            position = "identity",
                            ...,
                            lineend = "butt",
                            linejoin = "mitre",
                            na.rm = FALSE,
                            show.legend = NA,
                            inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRectWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Tile Layer
#'
#' Add a tile layer tagged for the `ggWebGL` renderer. Tile boundaries are read
#' from `ggplot2`'s built layer data, which preserves `geom_tile()` width,
#' height, and irregular-spacing behavior.
#'
#' @inheritParams ggplot2::geom_tile
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' tiles <- expand.grid(x = 1:3, y = 1:2)
#' tiles$value <- with(tiles, x + y)
#'
#' ggplot2::ggplot(tiles, ggplot2::aes(x, y, fill = value)) +
#'   geom_tile_webgl(alpha = 0.85)
#' @export
geom_tile_webgl <- function(mapping = NULL,
                            data = NULL,
                            stat = "identity",
                            position = "identity",
                            ...,
                            lineend = "butt",
                            linejoin = "mitre",
                            na.rm = FALSE,
                            show.legend = NA,
                            inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTileWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Bar Layer
#'
#' Add a bar layer tagged for the `ggWebGL` renderer. Counts and rectangle
#' boundaries are produced by `ggplot2` through the selected stat and position.
#'
#' @inheritParams ggplot2::geom_bar
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' bar_data <- data.frame(group = c("a", "a", "b", "c", "c", "c"))
#'
#' ggplot2::ggplot(bar_data, ggplot2::aes(group)) +
#'   geom_bar_webgl(fill = "#2563eb")
#' @export
geom_bar_webgl <- function(mapping = NULL,
                           data = NULL,
                           stat = "count",
                           position = "stack",
                           ...,
                           just = 0.5,
                           lineend = "butt",
                           linejoin = "mitre",
                           na.rm = FALSE,
                           show.legend = NA,
                           inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomBarWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      just = just,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Histogram Layer
#'
#' Add a histogram layer tagged for the `ggWebGL` renderer. Binning is delegated
#' to `ggplot2::StatBin`; the WebGL layer consumes the built bar rectangles.
#'
#' @inheritParams ggplot2::geom_histogram
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' hist_data <- data.frame(x = c(0.1, 0.2, 0.7, 1.2, 1.6, 2.1))
#'
#' ggplot2::ggplot(hist_data, ggplot2::aes(x)) +
#'   geom_histogram_webgl(binwidth = 0.5, fill = "#0f766e")
#' @export
geom_histogram_webgl <- function(mapping = NULL,
                                 data = NULL,
                                 stat = "bin",
                                 position = "stack",
                                 ...,
                                 binwidth = NULL,
                                 bins = NULL,
                                 orientation = NA,
                                 lineend = "butt",
                                 linejoin = "mitre",
                                 na.rm = FALSE,
                                 show.legend = NA,
                                 inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomBarWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      binwidth = binwidth,
      bins = bins,
      orientation = orientation,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL 2D Binned Rectangles
#'
#' Add a 2D binned layer tagged for the `ggWebGL` renderer. Binning is delegated
#' to `ggplot2::StatBin2d`; the WebGL layer consumes the built rectangle
#' boundaries and count/density metadata.
#'
#' @inheritParams ggplot2::geom_bin_2d
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' bin_data <- data.frame(
#'   x = c(0.1, 0.2, 0.7, 1.2, 1.8, 2.1),
#'   y = c(0.1, 0.5, 0.6, 1.1, 1.3, 1.8)
#' )
#'
#' ggplot2::ggplot(bin_data, ggplot2::aes(x, y)) +
#'   geom_bin2d_webgl(binwidth = c(1, 1))
#' @export
geom_bin2d_webgl <- function(mapping = NULL,
                             data = NULL,
                             stat = "bin2d",
                             position = "identity",
                             ...,
                             lineend = "butt",
                             linejoin = "mitre",
                             na.rm = FALSE,
                             show.legend = NA,
                             inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomBin2dWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Segment Layer
#'
#' Add a pure line-segment layer tagged for the `ggWebGL` renderer. Segments use
#' the vector primitive with arrowheads disabled; use [geom_vector_webgl()] when
#' arrowheads are wanted.
#'
#' @inheritParams ggplot2::geom_segment
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' segments <- data.frame(
#'   x = c(0, 1),
#'   y = c(0, 0.2),
#'   xend = c(0.8, 1.6),
#'   yend = c(0.7, 1)
#' )
#' ggplot2::ggplot(segments, ggplot2::aes(x, y, xend = xend, yend = yend)) +
#'   geom_segment_webgl(linewidth = 1.2)
#' @export
geom_segment_webgl <- function(mapping = NULL,
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
    geom = GeomSegmentWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(head_size = 0, na.rm = na.rm, ...)
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
