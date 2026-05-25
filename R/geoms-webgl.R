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
GeomRibbonWebGL <- ggplot2::ggproto(
  "GeomRibbonWebGL",
  ggplot2::GeomRibbon,
  optional_aes = c(ggplot2::GeomRibbon$optional_aes, "frame", "time"),
  extra_params = c(ggplot2::GeomRibbon$extra_params, "lineend", "linejoin", "linemitre", "outline.type")
)
GeomAreaWebGL <- ggplot2::ggproto(
  "GeomAreaWebGL",
  ggplot2::GeomArea,
  optional_aes = c(ggplot2::GeomArea$optional_aes, "frame", "time"),
  extra_params = c(ggplot2::GeomArea$extra_params, "lineend", "linejoin", "linemitre", "outline.type")
)
GeomSegmentWebGL <- ggplot2::ggproto(
  "GeomSegmentWebGL",
  ggplot2::GeomSegment,
  optional_aes = c(ggplot2::GeomSegment$optional_aes, "z", "zend", "id", "frame", "time"),
  extra_params = c(ggplot2::GeomSegment$extra_params, "head_size")
)
GeomLinerangeWebGL <- ggplot2::ggproto(
  "GeomLinerangeWebGL",
  ggplot2::GeomLinerange,
  optional_aes = c(ggplot2::GeomLinerange$optional_aes, "frame", "time"),
  extra_params = ggplot2::GeomLinerange$extra_params
)
GeomErrorbarWebGL <- ggplot2::ggproto(
  "GeomErrorbarWebGL",
  ggplot2::GeomErrorbar,
  optional_aes = c(ggplot2::GeomErrorbar$optional_aes, "frame", "time"),
  extra_params = ggplot2::GeomErrorbar$extra_params
)
GeomPointrangeWebGL <- ggplot2::ggproto(
  "GeomPointrangeWebGL",
  ggplot2::GeomPointrange,
  optional_aes = c(ggplot2::GeomPointrange$optional_aes, "frame", "time"),
  extra_params = ggplot2::GeomPointrange$extra_params
)
GeomCrossbarWebGL <- ggplot2::ggproto(
  "GeomCrossbarWebGL",
  ggplot2::GeomCrossbar,
  optional_aes = c(ggplot2::GeomCrossbar$optional_aes, "frame", "time"),
  extra_params = ggplot2::GeomCrossbar$extra_params
)
GeomBoxplotWebGL <- ggplot2::ggproto(
  "GeomBoxplotWebGL",
  ggplot2::GeomBoxplot,
  optional_aes = c(ggplot2::GeomBoxplot$optional_aes, "frame", "time"),
  extra_params = ggplot2::GeomBoxplot$extra_params
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

#' WebGL Ribbon Layer
#'
#' Add a filled ribbon layer tagged for the `ggWebGL` renderer. The renderer
#' consumes `ggplot2`-built `x`, `ymin`, and `ymax` values and draws each
#' group/run as a filled triangle strip.
#'
#' @inheritParams ggplot2::geom_ribbon
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' ribbon_data <- data.frame(
#'   x = 1:4,
#'   ymin = c(0.1, 0.2, 0.1, 0.3),
#'   ymax = c(0.4, 0.7, 0.5, 0.8)
#' )
#'
#' ggplot2::ggplot(ribbon_data, ggplot2::aes(x, ymin = ymin, ymax = ymax)) +
#'   geom_ribbon_webgl(fill = "#38bdf8", alpha = 0.6)
#' @export
geom_ribbon_webgl <- function(mapping = NULL,
                              data = NULL,
                              stat = "identity",
                              position = "identity",
                              ...,
                              orientation = NA,
                              lineend = "butt",
                              linejoin = "round",
                              linemitre = 10,
                              outline.type = "both",
                              na.rm = FALSE,
                              show.legend = NA,
                              inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRibbonWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      orientation = orientation,
      lineend = lineend,
      linejoin = linejoin,
      linemitre = linemitre,
      outline.type = outline.type,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Area Layer
#'
#' Add a filled area layer tagged for the `ggWebGL` renderer. Stacking and
#' alignment are delegated to `ggplot2`; the WebGL layer consumes the built
#' ribbon boundaries.
#'
#' @inheritParams ggplot2::geom_area
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' area_data <- data.frame(x = 1:4, y = c(1, 2, 1, 3))
#'
#' ggplot2::ggplot(area_data, ggplot2::aes(x, y)) +
#'   geom_area_webgl(fill = "#0f766e", alpha = 0.7)
#' @export
geom_area_webgl <- function(mapping = NULL,
                            data = NULL,
                            stat = "align",
                            position = "stack",
                            ...,
                            orientation = NA,
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
    geom = GeomAreaWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      orientation = orientation,
      outline.type = outline.type,
      lineend = lineend,
      linejoin = linejoin,
      linemitre = linemitre,
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

#' WebGL Linerange Layer
#'
#' Add a vertical range layer tagged for the `ggWebGL` renderer. The renderer
#' consumes `ggplot2`-built `x`, `ymin`, and `ymax` values and serializes ranges
#' as pure segment primitives.
#'
#' @inheritParams ggplot2::geom_linerange
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' ranges <- data.frame(x = 1:3, y = c(2, 3, 2.5), ymin = c(1, 2, 1.8), ymax = c(3, 4, 3.2))
#' ggplot2::ggplot(ranges, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
#'   geom_linerange_webgl(linewidth = 1)
#' @export
geom_linerange_webgl <- function(mapping = NULL,
                                 data = NULL,
                                 stat = "identity",
                                 position = "identity",
                                 ...,
                                 orientation = NA,
                                 lineend = "butt",
                                 na.rm = FALSE,
                                 show.legend = NA,
                                 inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomLinerangeWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      orientation = orientation,
      lineend = lineend,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Errorbar Layer
#'
#' Add a vertical error-bar layer tagged for the `ggWebGL` renderer. The
#' renderer consumes `ggplot2`-built range and cap columns and serializes them
#' as pure segment primitives.
#'
#' @inheritParams ggplot2::geom_errorbar
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' errors <- data.frame(x = 1:3, y = c(2, 3, 2.5), ymin = c(1, 2, 1.8), ymax = c(3, 4, 3.2))
#' ggplot2::ggplot(errors, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
#'   geom_errorbar_webgl(width = 0.2)
#' @export
geom_errorbar_webgl <- function(mapping = NULL,
                                data = NULL,
                                stat = "identity",
                                position = "identity",
                                ...,
                                orientation = NA,
                                lineend = "butt",
                                na.rm = FALSE,
                                show.legend = NA,
                                inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomErrorbarWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      orientation = orientation,
      lineend = lineend,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Pointrange Layer
#'
#' Add a point plus vertical range layer tagged for the `ggWebGL` renderer.
#' Pointranges serialize to one point payload and one pure segment payload.
#'
#' @inheritParams ggplot2::geom_pointrange
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' ranges <- data.frame(x = 1:3, y = c(2, 3, 2.5), ymin = c(1, 2, 1.8), ymax = c(3, 4, 3.2))
#' ggplot2::ggplot(ranges, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
#'   geom_pointrange_webgl()
#' @export
geom_pointrange_webgl <- function(mapping = NULL,
                                  data = NULL,
                                  stat = "identity",
                                  position = "identity",
                                  ...,
                                  orientation = NA,
                                  lineend = "butt",
                                  na.rm = FALSE,
                                  show.legend = NA,
                                  inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomPointrangeWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      orientation = orientation,
      lineend = lineend,
      na.rm = na.rm,
      ...
    )
  )
}

#' WebGL Crossbar Layer
#'
#' Add a crossbar layer tagged for the `ggWebGL` renderer. Crossbars serialize
#' to one filled rectangle payload for the body and one pure segment payload for
#' the middle line.
#'
#' @inheritParams ggplot2::geom_crossbar
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' crossbars <- data.frame(x = 1:3, y = c(2, 3, 2.5), ymin = c(1, 2, 1.8), ymax = c(3, 4, 3.2))
#' ggplot2::ggplot(crossbars, ggplot2::aes(x, y, ymin = ymin, ymax = ymax)) +
#'   geom_crossbar_webgl(width = 0.35, fill = "#93c5fd")
#' @export
geom_crossbar_webgl <- function(mapping = NULL,
                                data = NULL,
                                stat = "identity",
                                position = "identity",
                                ...,
                                middle.colour = NULL,
                                middle.color = NULL,
                                middle.linetype = NULL,
                                middle.linewidth = NULL,
                                box.colour = NULL,
                                box.color = NULL,
                                box.linetype = NULL,
                                box.linewidth = NULL,
                                na.rm = FALSE,
                                orientation = NA,
                                show.legend = NA,
                                inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomCrossbarWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      orientation = orientation,
      ...
    )
  )
}

#' WebGL Boxplot Layer
#'
#' Add a boxplot layer tagged for the `ggWebGL` renderer. Boxplot statistics are
#' computed by `ggplot2`; the renderer serializes the built box body as
#' rectangles, medians/whiskers as pure segments, and outliers as points.
#'
#' @inheritParams ggplot2::geom_boxplot
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' box_data <- data.frame(group = rep(c("a", "b"), each = 6), value = c(1:6, 2:7))
#' ggplot2::ggplot(box_data, ggplot2::aes(group, value, fill = group)) +
#'   geom_boxplot_webgl()
#' @export
geom_boxplot_webgl <- function(mapping = NULL,
                               data = NULL,
                               stat = "boxplot",
                               position = "dodge2",
                               ...,
                               outliers = TRUE,
                               outlier.colour = NULL,
                               outlier.color = NULL,
                               outlier.fill = NULL,
                               outlier.shape = NULL,
                               outlier.size = NULL,
                               outlier.stroke = 0.5,
                               outlier.alpha = NULL,
                               whisker.colour = NULL,
                               whisker.color = NULL,
                               whisker.linetype = NULL,
                               whisker.linewidth = NULL,
                               staple.colour = NULL,
                               staple.color = NULL,
                               staple.linetype = NULL,
                               staple.linewidth = NULL,
                               median.colour = NULL,
                               median.color = NULL,
                               median.linetype = NULL,
                               median.linewidth = NULL,
                               box.colour = NULL,
                               box.color = NULL,
                               box.linetype = NULL,
                               box.linewidth = NULL,
                               notch = FALSE,
                               notchwidth = 0.5,
                               staplewidth = 0,
                               varwidth = FALSE,
                               na.rm = FALSE,
                               orientation = NA,
                               show.legend = NA,
                               inherit.aes = TRUE) {
  if (is.character(position) && isTRUE(varwidth)) {
    position <- ggplot2::position_dodge2(preserve = "single")
  }
  outlier_gp <- list(
    colour = outlier.color %||% outlier.colour,
    fill = outlier.fill,
    shape = outlier.shape,
    size = outlier.size,
    stroke = outlier.stroke,
    alpha = outlier.alpha
  )
  whisker_gp <- list(
    colour = whisker.color %||% whisker.colour,
    linetype = whisker.linetype,
    linewidth = whisker.linewidth
  )
  staple_gp <- list(
    colour = staple.color %||% staple.colour,
    linetype = staple.linetype,
    linewidth = staple.linewidth
  )
  median_gp <- list(
    colour = median.color %||% median.colour,
    linetype = median.linetype,
    linewidth = median.linewidth
  )
  box_gp <- list(
    colour = box.color %||% box.colour,
    linetype = box.linetype,
    linewidth = box.linewidth
  )

  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomBoxplotWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      outliers = outliers,
      outlier_gp = outlier_gp,
      whisker_gp = whisker_gp,
      staple_gp = staple_gp,
      median_gp = median_gp,
      box_gp = box_gp,
      notch = notch,
      notchwidth = notchwidth,
      staplewidth = staplewidth,
      varwidth = varwidth,
      na.rm = na.rm,
      orientation = orientation,
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
