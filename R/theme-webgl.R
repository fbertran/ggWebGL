#' Add WebGL Rendering Options to a ggplot
#'
#' Attach WebGL-specific rendering metadata to a `ggplot` object. The returned
#' object is consumed by [`ggplot_webgl()`] and stored on the plot as
#' `plot$ggwebgl`.
#'
#' @param shader Shader preset name or path identifier. Built-in modes are
#'   `"default"`, `"density_splat"`, `"trajectory_age"`, and
#'   `"trajectory_age_glow"`, `"trajectory_velocity"`, and
#'   `"trajectory_direction"`.
#' @param antialias Logical scalar; whether antialiasing should be requested.
#' @param transparent Logical scalar; whether the drawing surface should allow
#'   transparency.
#' @param buffer_size Integer scalar giving the initial buffer allocation used
#'   by the eventual renderer.
#' @param interactions Legacy character vector of interaction modes to enable.
#'   New code should use `selection = ggwebgl_selection(...)` for brush/lasso
#'   behavior.
#' @param interactions_spec Optional [ggwebgl_interactions()] object. This is
#'   the preferred structured interaction contract for hover, click, brush,
#'   lasso, camera, and Shiny event behavior.
#' @param rendering Rendering contract mode. `"visualization"` keeps the
#'   current interactive widget chrome. `"publication"` suppresses presentation
#'   chrome by default and is intended for clean figure capture.
#' @param panel_overlay Panel overlay display mode. `"auto"` shows panel strips
#'   and frames for faceted plots, `"show"` forces them on, and `"hide"`
#'   removes them.
#' @param view Optional [ggwebgl_view()] object. This is the preferred structured
#'   view/camera contract.
#' @param selection Optional [ggwebgl_selection()] object. This is the preferred
#'   selection contract.
#' @param dimension,camera,projection,camera_state Legacy view fields retained as
#'   an internal migration shim.
#' @param depth_test Logical scalar. `NULL` uses the renderer default: disabled
#'   for 2D scenes and enabled for 3D scenes. Set explicitly to override.
#' @param blend_mode Primitive blending mode: `"auto"`, `"alpha"`,
#'   `"additive"`, or `"premultiplied"`.
#' @param timeline Optional `ggwebgl_timeline()` specification for runtime
#'   playback controls.
#' @param ... Reserved for future backend-specific options.
#'
#' @return An object that can be added to a `ggplot`.
#'
#' @examples
#' plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt, colour = factor(cyl))) +
#'   ggplot2::geom_point() +
#'   theme_webgl(
#'     shader = "density_splat",
#'     selection = ggwebgl_selection("none")
#'   )
#'
#' plot$ggwebgl
#' @export
theme_webgl <- function(shader = "default",
                        antialias = TRUE,
                        transparent = TRUE,
                        buffer_size = 65536L,
                        interactions = c("pan", "zoom"),
                        interactions_spec = NULL,
                        rendering = "visualization",
                        panel_overlay = "auto",
                        view = NULL,
                        selection = NULL,
                        dimension = "2d",
                        camera = "orbit",
                        projection = "orthographic",
                        camera_state = list(),
                        depth_test = NULL,
                        blend_mode = "auto",
                        timeline = NULL,
                        ...) {
  inferred_3d_dimension <- missing(dimension) &&
    (!missing(camera) || (!missing(projection) && identical(normalise_projection(projection), "perspective")))
  explicit_fields <- c(
    if (!missing(shader)) "shader",
    if (!missing(antialias)) "antialias",
    if (!missing(transparent)) "transparent",
    if (!missing(buffer_size)) "buffer_size",
    if (!missing(interactions)) "interactions",
    if (!missing(interactions_spec)) "interactions_spec",
    if (!missing(rendering)) "rendering",
    if (!missing(panel_overlay)) "panel_overlay",
    if (!missing(view)) "view",
    if (!missing(selection)) "selection",
    if (!missing(dimension) || inferred_3d_dimension) "dimension",
    if (!missing(camera)) "camera",
    if (!missing(projection)) "projection",
    if (!missing(camera_state)) "camera_state",
    if (!missing(depth_test)) "depth_test",
    if (!missing(blend_mode)) "blend_mode",
    if (!missing(timeline)) "timeline",
    names(list(...))
  )
  options <- normalise_webgl_options(compact_list(list(
    shader = if (!missing(shader)) shader else NULL,
    antialias = if (!missing(antialias)) antialias else NULL,
    transparent = if (!missing(transparent)) transparent else NULL,
    buffer_size = if (!missing(buffer_size)) buffer_size else NULL,
    interactions = if (!missing(interactions)) interactions else NULL,
    interactions_spec = if (!missing(interactions_spec)) interactions_spec else NULL,
    rendering = if (!missing(rendering)) rendering else NULL,
    panel_overlay = if (!missing(panel_overlay)) panel_overlay else NULL,
    view = if (!missing(view)) view else NULL,
    selection = if (!missing(selection)) selection else NULL,
    dimension = if (!missing(dimension)) dimension else if (inferred_3d_dimension) "3d" else NULL,
    camera = if (!missing(camera)) camera else NULL,
    projection = if (!missing(projection)) projection else NULL,
    camera_state = if (!missing(camera_state)) camera_state else NULL,
    depth_test = if (!missing(depth_test)) depth_test else NULL,
    blend_mode = if (!missing(blend_mode)) blend_mode else NULL,
    timeline = if (!missing(timeline)) timeline else NULL,
    extra = list(...)
  )), explicit_fields = explicit_fields)
  class(options) <- "ggwebgl_theme"
  options
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.ggwebgl_theme <- function(object, plot, object_name) {
  current <- webgl_explicit_options(plot$ggwebgl %||% NULL)
  merged <- utils::modifyList(current, webgl_explicit_options(object))
  attr(merged, "explicit_fields") <- unique(c(
    webgl_explicit_fields(current),
    webgl_explicit_fields(object)
  ))
  plot$ggwebgl <- normalise_webgl_options(merged)
  plot
}
