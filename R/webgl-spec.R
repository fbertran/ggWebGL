ggwebgl_scene_webgl_options <- function(webgl, explicit_fields = NULL) {
  normalise_webgl_options(webgl, explicit_fields = explicit_fields)
}

#' Build ggWebGL Renderer Options
#'
#' `webgl_spec()` creates a normalized renderer option list for
#' [ggplot_webgl()], [ggwebgl_spec()], and downstream adapter code. It is a
#' compact user-facing wrapper around the same internal normalization used by
#' [theme_webgl()].
#'
#' @param camera Camera/controller mode. `"panzoom"` targets 2D scenes;
#'   `"orbit"` and `"trackball"` target 3D scenes.
#' @param projection Projection mode, `"orthographic"` or `"perspective"`.
#' @param dimension Optional renderer dimensionality. When omitted, `"orbit"`
#'   and `"trackball"` imply `"3d"` while `"panzoom"` implies `"2d"`.
#' @param depth_test Logical scalar. `NULL` enables depth testing for 3D scenes
#'   and disables it for 2D scenes.
#' @param blend_mode Primitive blending mode: `"auto"`, `"alpha"`,
#'   `"additive"`, or `"premultiplied"`.
#' @param shader Optional shader preset.
#' @param interactions Optional interaction mode vector.
#' @param view Optional [ggwebgl_view()] object. If supplied, it takes
#'   precedence over `camera`, `projection`, and `dimension`.
#' @param selection Optional [ggwebgl_selection()] object.
#' @param timeline Optional [ggwebgl_timeline()] object.
#' @param ... Additional renderer options stored under `webgl$extra`.
#'
#' @return A normalized renderer option list.
#'
#' @examples
#' webgl_spec(camera = "orbit", projection = "perspective")
#' @export
webgl_spec <- function(camera = c("panzoom", "orbit", "trackball"),
                       projection = c("orthographic", "perspective"),
                       dimension = NULL,
                       depth_test = NULL,
                       blend_mode = c("auto", "alpha", "additive", "premultiplied"),
                       shader = NULL,
                       interactions = NULL,
                       view = NULL,
                       selection = NULL,
                       timeline = NULL,
                       ...) {
  camera <- match.arg(camera)
  projection <- match.arg(projection)
  blend_mode <- match.arg(blend_mode)
  if (is.null(dimension)) {
    dimension <- if (identical(camera, "panzoom")) "2d" else "3d"
  }
  controller <- if (identical(camera, "panzoom")) "panzoom" else camera
  view <- view %||% ggwebgl_view(
    dimension = dimension,
    projection = projection,
    controller = controller
  )

  normalise_webgl_options(compact_list(list(
    shader = shader,
    interactions = interactions,
    view = view,
    selection = selection,
    depth_test = depth_test,
    blend_mode = blend_mode,
    timeline = timeline,
    extra = list(...)
  )), explicit_fields = c(
    if (!is.null(shader)) "shader",
    if (!is.null(interactions)) "interactions",
    "view",
    if (!is.null(selection)) "selection",
    "depth_test",
    "blend_mode",
    if (!is.null(timeline)) "timeline",
    names(list(...))
  ))
}
