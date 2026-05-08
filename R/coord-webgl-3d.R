#' Request a 3D WebGL Coordinate System
#'
#' `coord_webgl_3d()` is a ggplot-addable helper that marks the WebGL payload as
#' `cartesian3d` and installs a structured 3D view contract. It does not replace
#' ggplot2's 2D coordinate system; the standard ggplot object remains valid, and
#' the 3D interpretation is applied by [ggplot_webgl()].
#'
#' @param projection Projection mode, `"perspective"` or `"orthographic"`.
#' @param camera 3D camera controller, `"orbit"` or `"trackball"`.
#' @param depth_test Logical scalar; whether the browser renderer should enable
#'   depth testing for this scene.
#' @param state Optional camera state list passed to [ggwebgl_view()].
#'
#' @return A ggplot-addable `ggwebgl_coord_3d` object.
#'
#' @examples
#' ggplot2::ggplot(
#'   data.frame(x = 1:3, y = 1:3, z = c(0, 1, 0)),
#'   ggplot2::aes(x, y, z = z)
#' ) +
#'   geom_point_webgl() +
#'   coord_webgl_3d()
#' @export
coord_webgl_3d <- function(projection = c("perspective", "orthographic"),
                           camera = c("orbit", "trackball"),
                           depth_test = TRUE,
                           state = list()) {
  projection <- match.arg(projection)
  camera <- match.arg(camera)
  out <- list(
    view = ggwebgl_view(
      dimension = "3d",
      projection = projection,
      controller = camera,
      state = state
    ),
    depth_test = isTRUE(depth_test)
  )
  class(out) <- "ggwebgl_coord_3d"
  out
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.ggwebgl_coord_3d <- function(object, plot, object_name) {
  current <- webgl_explicit_options(plot$ggwebgl %||% NULL)
  next_options <- compact_list(list(
    view = object$view,
    dimension = "3d",
    camera = object$view$controller,
    projection = object$view$projection,
    camera_state = object$view$state,
    depth_test = object$depth_test
  ))
  attr(next_options, "explicit_fields") <- names(next_options)
  merged <- utils::modifyList(current, next_options)
  attr(merged, "explicit_fields") <- unique(c(
    webgl_explicit_fields(current),
    names(next_options)
  ))
  plot$ggwebgl <- normalise_webgl_options(merged)
  plot
}
