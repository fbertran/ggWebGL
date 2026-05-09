GeomSurfaceWebGL <- ggplot2::ggproto(
  "GeomSurfaceWebGL",
  ggplot2::GeomRaster,
  required_aes = c("x", "y", "z"),
  optional_aes = c(ggplot2::GeomRaster$optional_aes, "z", "uncertainty", "frame", "time"),
  extra_params = c(
    ggplot2::GeomRaster$extra_params,
    "shading",
    "wireframe",
    "material",
    "normals",
    "contours",
    "contour_levels",
    "contour_colour",
    "contour_width",
    "pick_id"
  )
)

#' WebGL Structured Grid Surface Layer
#'
#' Add a rectilinear grid surface layer tagged for the `ggWebGL` structured
#' surface renderer. Surface layers are sent to WebGL as indexed triangles with
#' per-vertex positions, normals, colours, and surface metadata.
#'
#' @inheritParams ggplot2::geom_raster
#' @param shading Surface shader mode. One of `"surface_lambert"`,
#'   `"surface_flat"`, `"surface_height_colormap"`, or
#'   `"surface_uncertainty_alpha"`.
#' @param wireframe Whether to draw a wireframe overlay.
#' @param material Surface material metadata created by [ggwebgl_material()].
#' @param normals Normal-generation mode. `"auto"` computes vertex normals.
#' @param contours Whether to generate contour-line overlays on the R side.
#' @param contour_levels Optional numeric contour levels. Defaults to `pretty()`
#'   levels across the surface z range when `contours = TRUE`.
#' @param contour_colour Contour line colour.
#' @param contour_width Contour line width in renderer pixels.
#' @param pick_id Optional triangle picking ids.
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' surface <- expand.grid(x = 1:3, y = 1:3)
#' surface$z <- with(surface, sin(x) + cos(y))
#' ggplot2::ggplot(surface, ggplot2::aes(x, y, z = z, fill = z)) +
#'   geom_surface_webgl()
#' @export
geom_surface_webgl <- function(mapping = NULL,
                               data = NULL,
                               stat = StatSurfaceWebGL,
                               position = "identity",
                               ...,
                               shading = c(
                                 "surface_lambert",
                                 "surface_flat",
                                 "surface_height_colormap",
                                 "surface_uncertainty_alpha"
                               ),
                               wireframe = FALSE,
                               material = NULL,
                               normals = "auto",
                               contours = FALSE,
                               contour_levels = NULL,
                               contour_colour = "#1f2937",
                               contour_width = 1,
                               pick_id = NULL,
                               na.rm = FALSE,
                               show.legend = NA,
                               inherit.aes = TRUE) {
  shading <- normalise_surface_shading(shading)
  material <- material %||% ggwebgl_material(
    shading = if (identical(shading, "surface_lambert")) "lambert" else "flat",
    wireframe = wireframe
  )

  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomSurfaceWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      shading = shading,
      wireframe = wireframe,
      material = material,
      normals = normals,
      contours = contours,
      contour_levels = contour_levels,
      contour_colour = contour_colour,
      contour_width = contour_width,
      pick_id = pick_id,
      na.rm = na.rm,
      ...
    )
  )
}
