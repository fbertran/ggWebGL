GeomMeshWebGL <- ggplot2::ggproto(
  "GeomMeshWebGL",
  ggplot2::GeomPoint,
  optional_aes = c(
    ggplot2::GeomPoint$optional_aes,
    "z",
    "i",
    "j",
    "k",
    "id",
    "scalar",
    "frame",
    "time"
  ),
  extra_params = c(
    ggplot2::GeomPoint$extra_params,
    "shading",
    "wireframe",
    "material",
    "normals",
    "pick_id"
  )
)

#' WebGL Unstructured Mesh Layer
#'
#' Add an unstructured triangle mesh layer tagged for the `ggWebGL` 3D renderer.
#' Mesh triangles are supplied with `i`, `j`, and `k` aesthetics using one-based
#' vertex indices.
#'
#' @inheritParams ggplot2::geom_point
#' @param shading Mesh shader mode. One of `"mesh_lambert"`, `"mesh_flat"`,
#'   `"mesh_phong_simple"`, `"mesh_scalar_colormap"`, or
#'   `"mesh_selection_highlight"`.
#' @param wireframe Whether to request a wireframe overlay.
#' @param material Mesh material created by [ggwebgl_material()].
#' @param normals Optional vertex normals or `"auto"`.
#' @param pick_id Optional face picking ids.
#'
#' @return A `Layer` ready for `ggplot2`.
#'
#' @examples
#' vertices <- data.frame(
#'   x = c(0, 1, 0),
#'   y = c(0, 0, 1),
#'   z = c(0, 0, 0),
#'   i = c(1, NA, NA),
#'   j = c(2, NA, NA),
#'   k = c(3, NA, NA)
#' )
#' ggplot2::ggplot(vertices, ggplot2::aes(x, y, z = z, i = i, j = j, k = k)) +
#'   geom_mesh_webgl()
#' @export
geom_mesh_webgl <- function(mapping = NULL,
                            data = NULL,
                            stat = "identity",
                            position = "identity",
                            ...,
                            shading = c(
                              "mesh_lambert",
                              "mesh_flat",
                              "mesh_phong_simple",
                              "mesh_scalar_colormap",
                              "mesh_selection_highlight"
                            ),
                            wireframe = FALSE,
                            material = NULL,
                            normals = NULL,
                            pick_id = NULL,
                            na.rm = FALSE,
                            show.legend = NA,
                            inherit.aes = TRUE) {
  shading <- normalise_mesh_shading(shading)
  material <- normalise_mesh_material(
    material %||% ggwebgl_material(
      shading = if (identical(shading, "mesh_lambert")) "lambert" else "flat",
      wireframe = wireframe
    ),
    wireframe = wireframe,
    shading = shading
  )

  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMeshWebGL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      shading = shading,
      wireframe = wireframe,
      material = material,
      normals = normals,
      pick_id = pick_id,
      na.rm = na.rm,
      ...
    )
  )
}
