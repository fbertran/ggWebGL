`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

compact_list <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

ggwebgl_require_optional <- function(pkg, purpose = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    msg <- paste0(
      "Package '", pkg, "' is required",
      if (!is.null(purpose)) paste0(" for ", purpose) else "",
      ". Install it separately to use this optional bridge."
    )
    stop(msg, call. = FALSE)
  }

  invisible(TRUE)
}

ggwebgl_normalise_publication_preset <- function(preset) {
  legacy_publication_preset <- paste0("sig", "graph", "_", "po", "ster")
  value <- match.arg(as.character(preset)[[1L]], choices = c("clean", "publication", legacy_publication_preset))
  if (identical(value, legacy_publication_preset)) {
    "publication"
  } else {
    value
  }
}

default_theme_webgl <- function() {
  list(
    shader = "default",
    antialias = TRUE,
    transparent = TRUE,
    buffer_size = 65536L,
    interactions = c("pan", "zoom"),
    rendering = "visualization",
    panel_overlay = "auto",
    view = list(
      dimension = "2d",
      projection = "orthographic",
      controller = "panzoom",
      state = list(
        target = c(0, 0, 0),
        distance = 2.8,
        rotation = c(0, 0, 0, 1),
        up = c(0, 1, 0),
        fov = 45,
        near = 0.01,
        far = 1000
      )
    ),
    selection = list(mode = "none", highlight = TRUE, emit = TRUE),
    dimension = "2d",
    camera = "orbit",
    projection = "orthographic",
    camera_state = list(),
    depth_test = NULL,
    blend_mode = "auto",
    timeline = NULL,
    time_scale = NULL,
    line_mode = "auto",
    line_join = "bevel",
    line_cap = "round",
    extra = list()
  )
}

normalise_shader_name <- function(shader) {
  shader <- tolower(as.character(shader)[1] %||% "default")

  switch(
    shader,
    density = "density_splat",
    splat = "density_splat",
    density_splat = "density_splat",
    trajectory = "trajectory_age",
    age = "trajectory_age",
    trajectory_age = "trajectory_age",
    trajectory_age_glow = "trajectory_age_glow",
    `trajectory-glow` = "trajectory_age_glow",
    glow = "trajectory_age_glow",
    default = "default",
    shader
  )
}

normalise_interactions <- function(interactions, default = default_theme_webgl()[["interactions"]]) {
  interactions <- unique(stats::na.omit(as.character(interactions)))

  if (!length(interactions)) {
    return(default)
  }

  interactions
}

normalise_buffer_size <- function(buffer_size) {
  value <- suppressWarnings(as.integer(buffer_size)[1])

  if (!is.finite(value) || is.na(value) || value <= 0L) {
    return(default_theme_webgl()[["buffer_size"]])
  }

  value
}

normalise_line_mode <- function(line_mode) {
  value <- tolower(as.character(line_mode)[1] %||% default_theme_webgl()[["line_mode"]])

  if (!value %in% c("auto", "native", "quad")) {
    return(default_theme_webgl()[["line_mode"]])
  }

  value
}

normalise_line_join <- function(line_join) {
  value <- tolower(as.character(line_join)[1] %||% default_theme_webgl()[["line_join"]])

  if (!value %in% c("bevel", "round")) {
    return(default_theme_webgl()[["line_join"]])
  }

  value
}

normalise_line_cap <- function(line_cap) {
  value <- tolower(as.character(line_cap)[1] %||% default_theme_webgl()[["line_cap"]])

  if (!value %in% c("round", "butt")) {
    return(default_theme_webgl()[["line_cap"]])
  }

  value
}

normalise_rendering_mode <- function(rendering) {
  value <- tolower(as.character(rendering)[1] %||% default_theme_webgl()[["rendering"]])

  if (!value %in% c("visualization", "publication")) {
    return(default_theme_webgl()[["rendering"]])
  }

  value
}

normalise_panel_overlay <- function(panel_overlay) {
  value <- tolower(as.character(panel_overlay)[1] %||% default_theme_webgl()[["panel_overlay"]])

  if (!value %in% c("auto", "show", "hide")) {
    return(default_theme_webgl()[["panel_overlay"]])
  }

  value
}

normalise_dimension <- function(dimension) {
  value <- tolower(as.character(dimension)[1] %||% default_theme_webgl()[["dimension"]])

  if (!value %in% c("2d", "3d")) {
    return(default_theme_webgl()[["dimension"]])
  }

  value
}

normalise_camera <- function(camera) {
  value <- tolower(as.character(camera)[1] %||% default_theme_webgl()[["camera"]])

  if (!value %in% c("orbit", "trackball")) {
    return(default_theme_webgl()[["camera"]])
  }

  value
}

normalise_projection <- function(projection) {
  value <- tolower(as.character(projection)[1] %||% default_theme_webgl()[["projection"]])

  if (!value %in% c("orthographic", "perspective")) {
    return(default_theme_webgl()[["projection"]])
  }

  value
}

normalise_depth_test <- function(depth_test = NULL, dimension = "2d") {
  if (is.null(depth_test)) {
    return(identical(normalise_dimension(dimension), "3d"))
  }

  isTRUE(depth_test)
}

normalise_blend_mode <- function(blend_mode) {
  value <- tolower(as.character(blend_mode)[1] %||% default_theme_webgl()[["blend_mode"]])

  if (!value %in% c("auto", "alpha", "additive", "premultiplied")) {
    return(default_theme_webgl()[["blend_mode"]])
  }

  value
}

normalise_view_controller <- function(controller, dimension = "2d") {
  default <- if (identical(dimension, "3d")) "orbit" else "panzoom"
  value <- tolower(as.character(controller)[1] %||% default)

  if (!value %in% c("panzoom", "orbit", "trackball")) {
    return(default)
  }

  if (identical(dimension, "2d") && !identical(value, "panzoom")) {
    return("panzoom")
  }

  value
}

normalise_vector3 <- function(x, default, name = "vector") {
  values <- suppressWarnings(as.numeric(x %||% default))
  values <- values[is.finite(values)]
  if (!length(values)) {
    values <- default
  }
  rep_len(values, 3L)
}

normalise_quaternion <- function(rotation) {
  values <- suppressWarnings(as.numeric(rotation %||% c(0, 0, 0, 1)))
  values <- values[is.finite(values)]
  if (length(values) < 4L) {
    values <- c(0, 0, 0, 1)
  }
  values <- values[seq_len(4L)]
  norm <- sqrt(sum(values^2))
  if (!is.finite(norm) || norm <= 0) {
    return(c(0, 0, 0, 1))
  }
  unname(values / norm)
}

quaternion_from_yaw_pitch <- function(yaw, pitch) {
  yaw <- suppressWarnings(as.numeric(yaw %||% 0)[[1L]])
  pitch <- suppressWarnings(as.numeric(pitch %||% 0)[[1L]])
  if (!is.finite(yaw)) yaw <- 0
  if (!is.finite(pitch)) pitch <- 0
  cy <- cos(yaw * 0.5)
  sy <- sin(yaw * 0.5)
  cp <- cos(pitch * 0.5)
  sp <- sin(pitch * 0.5)
  normalise_quaternion(c(sp * cy, cp * sy, -sp * sy, cp * cy))
}

normalise_camera_state <- function(camera_state) {
  if (is.null(camera_state) || !is.list(camera_state)) {
    camera_state <- list()
  }
  rotation <- camera_state[["rotation"]] %||% NULL
  if (is.null(rotation) && (!is.null(camera_state[["yaw"]]) || !is.null(camera_state[["pitch"]]))) {
    rotation <- quaternion_from_yaw_pitch(camera_state[["yaw"]], camera_state[["pitch"]])
  }

  compact_list(list(
    yaw = as.numeric(camera_state[["yaw"]] %||% 0)[[1]],
    pitch = as.numeric(camera_state[["pitch"]] %||% 0)[[1]],
    distance = as.numeric(camera_state[["distance"]] %||% 2.8)[[1]],
    target = normalise_vector3(camera_state[["target"]], c(0, 0, 0), "target"),
    rotation = normalise_quaternion(rotation),
    up = normalise_vector3(camera_state[["up"]], c(0, 1, 0), "up"),
    fov = as.numeric(camera_state[["fov"]] %||% 45)[[1]],
    near = as.numeric(camera_state[["near"]] %||% 0.01)[[1]],
    far = as.numeric(camera_state[["far"]] %||% 1000)[[1]]
  ))
}

#' Define a ggWebGL View Contract
#'
#' Build a structured renderer view specification. This replaces the previous
#' loose `dimension`, `camera`, `projection`, and `camera_state`
#' fields while keeping them mirrored internally for older renderer paths.
#'
#' @param dimension Renderer dimensionality, `"2d"` or `"3d"`.
#' @param projection Projection mode, `"orthographic"` or `"perspective"`.
#' @param controller Interaction controller. Use `"panzoom"` for 2D scenes and
#'   `"orbit"` or `"trackball"` for 3D scenes.
#' @param state Camera/view state list. Recognized fields include `target`,
#'   `distance`, `rotation`, `up`, `fov`, `near`, and `far`. Legacy `yaw` and
#'   `pitch` are converted to `rotation`.
#'
#' @return A `ggwebgl_view` list.
#'
#' @examples
#' ggwebgl_view(dimension = "3d", controller = "trackball")
#' @export
ggwebgl_view <- function(dimension = c("2d", "3d"),
                         projection = c("orthographic", "perspective"),
                         controller = NULL,
                         state = list()) {
  dimension <- normalise_dimension(match.arg(dimension))
  projection <- normalise_projection(match.arg(projection))
  controller <- normalise_view_controller(controller, dimension = dimension)
  out <- list(
    dimension = dimension,
    projection = projection,
    controller = controller,
    state = normalise_camera_state(state)
  )
  class(out) <- c("ggwebgl_view", "list")
  out
}

normalise_view <- function(view = NULL,
                           dimension = NULL,
                           projection = NULL,
                           controller = NULL,
                           camera_state = NULL) {
  if (inherits(view, "ggwebgl_view")) {
    view <- unclass(view)
  }
  if (!is.list(view)) {
    view <- list()
  }

  dimension <- normalise_dimension(view[["dimension"]] %||% dimension %||% default_theme_webgl()[["dimension"]])
  projection <- normalise_projection(view[["projection"]] %||% projection %||% default_theme_webgl()[["projection"]])
  controller <- normalise_view_controller(view[["controller"]] %||% view[["camera"]] %||% controller, dimension)
  state <- view[["state"]] %||% view[["camera_state"]] %||% camera_state %||% list()

  list(
    dimension = dimension,
    projection = projection,
    controller = controller,
    state = normalise_camera_state(state)
  )
}

#' Define ggWebGL Selection Behavior
#'
#' Build a structured renderer-owned selection specification.
#'
#' @param mode Selection mode: `"none"`, `"brush"`, `"lasso"`, or
#'   `"brush_lasso"`.
#' @param highlight Whether selected primitives should be visibly highlighted.
#' @param emit Whether selection payloads should be emitted to Shiny/callbacks.
#'
#' @return A `ggwebgl_selection` list.
#'
#' @examples
#' ggwebgl_selection("brush_lasso")
#' @export
ggwebgl_selection <- function(mode = c("none", "brush", "lasso", "brush_lasso"),
                              highlight = TRUE,
                              emit = TRUE) {
  mode <- match.arg(mode)
  out <- list(
    mode = mode,
    highlight = isTRUE(highlight),
    emit = isTRUE(emit)
  )
  class(out) <- c("ggwebgl_selection", "list")
  out
}

selection_mode_from_interactions <- function(interactions) {
  interactions <- unique(as.character(interactions %||% character()))
  has_brush <- "brush" %in% interactions
  has_lasso <- "lasso" %in% interactions
  if (has_brush && has_lasso) {
    return("brush_lasso")
  }
  if (has_brush) {
    return("brush")
  }
  if (has_lasso) {
    return("lasso")
  }
  "none"
}

selection_interactions <- function(selection) {
  mode <- selection$mode %||% "none"
  switch(
    mode,
    brush = "brush",
    lasso = "lasso",
    brush_lasso = c("brush", "lasso"),
    character()
  )
}

normalise_selection <- function(selection = NULL, interactions = NULL) {
  if (inherits(selection, "ggwebgl_selection")) {
    selection <- unclass(selection)
  }
  if (!is.list(selection)) {
    selection <- list()
  }
  mode <- tolower(as.character(selection[["mode"]] %||% selection_mode_from_interactions(interactions))[[1L]])
  mode <- gsub("-", "_", mode, fixed = TRUE)
  if (identical(mode, "both")) {
    mode <- "brush_lasso"
  }
  if (!mode %in% c("none", "brush", "lasso", "brush_lasso")) {
    mode <- "none"
  }

  list(
    mode = mode,
    highlight = isTRUE(selection[["highlight"]] %||% TRUE),
    emit = isTRUE(selection[["emit"]] %||% TRUE)
  )
}

#' Define ggWebGL Mesh Material
#'
#' Build a renderer material specification for mesh and surface layers.
#'
#' @param shading Shading model. `"flat"` and `"lambert"` are the stable
#'   material aliases; mesh shader aliases such as `"mesh_lambert"` and
#'   `"mesh_scalar_colormap"` are also accepted by mesh layers.
#' @param ambient,diffuse,specular Lighting coefficients.
#' @param light_dir Directional light vector.
#' @param wireframe Whether to request a wireframe overlay.
#' @param cull Face-culling mode, `"back"` or `"none"`.
#'
#' @return A `ggwebgl_material` list.
#'
#' @examples
#' ggwebgl_material(shading = "lambert", wireframe = TRUE)
#' @export
ggwebgl_material <- function(shading = c(
                               "flat",
                               "lambert",
                               "mesh_flat",
                               "mesh_lambert",
                               "mesh_phong_simple",
                               "mesh_scalar_colormap",
                               "mesh_selection_highlight"
                             ),
                             ambient = 0.35,
                             diffuse = 0.75,
                             specular = 0,
                             light_dir = c(0.35, 0.45, 0.82),
                             wireframe = FALSE,
                             cull = c("back", "none")) {
  shading <- match.arg(shading)
  cull <- match.arg(cull)
  out <- list(
    shading = shading,
    ambient = as.numeric(ambient)[[1L]],
    diffuse = as.numeric(diffuse)[[1L]],
    specular = as.numeric(specular)[[1L]],
    light_dir = normalise_vector3(light_dir, c(0.35, 0.45, 0.82), "light_dir"),
    wireframe = isTRUE(wireframe),
    cull = cull
  )
  class(out) <- c("ggwebgl_material", "list")
  out
}

normalise_material <- function(material = NULL, wireframe = NULL) {
  if (inherits(material, "ggwebgl_material")) {
    material <- unclass(material)
  }
  if (!is.list(material)) {
    material <- list()
  }
  shading <- tolower(as.character(material[["shading"]] %||% "flat")[[1L]])
  if (!shading %in% c("flat", "lambert")) {
    shading <- "flat"
  }
  cull <- tolower(as.character(material[["cull"]] %||% "back")[[1L]])
  if (!cull %in% c("back", "none")) {
    cull <- "back"
  }
  list(
    shading = shading,
    ambient = as.numeric(material[["ambient"]] %||% 0.35)[[1L]],
    diffuse = as.numeric(material[["diffuse"]] %||% 0.75)[[1L]],
    specular = as.numeric(material[["specular"]] %||% 0)[[1L]],
    light_dir = normalise_vector3(material[["light_dir"]], c(0.35, 0.45, 0.82), "light_dir"),
    wireframe = isTRUE(wireframe %||% material[["wireframe"]] %||% FALSE),
    cull = cull
  )
}

#' ggWebGL Timeline Controls
#'
#' Build a lightweight runtime timeline specification for animated
#' ggWebGL scenes. Layers can opt into timeline filtering with `frame` or
#' `time` fields.
#'
#' @param frames Optional integer frame values.
#' @param time Optional numeric time values.
#' @param duration Optional playback duration in seconds.
#' @param loop Whether playback should loop.
#' @param autoplay Whether playback should start automatically.
#' @param speed Playback speed multiplier.
#' @param controls Whether the widget should show timeline controls.
#' @param filter Timeline visibility mode. `"exact"` shows only samples matching
#'   the current frame or time. `"cumulative"` keeps samples up to the current
#'   frame or time.
#' @param values Optional frame or time values. Use `source` to choose whether
#'   they populate the frame or time axis.
#' @param source Timeline value source for `values`. `"auto"` uses frame values
#'   unless `time` is supplied.
#' @param mode Optional alias for `filter`.
#' @param fps Optional frames-per-second metadata for downstream controls.
#'
#' @return A `ggwebgl_timeline` list.
#'
#' @examples
#' ggwebgl_timeline(frames = 1:4, autoplay = FALSE)
#' @export
ggwebgl_timeline <- function(frames = NULL,
                             time = NULL,
                             duration = NULL,
                             loop = TRUE,
                             autoplay = FALSE,
                             speed = 1,
                             controls = TRUE,
                             filter = c("exact", "cumulative"),
                             values = NULL,
                             source = c("auto", "frame", "time"),
                             mode = NULL,
                             fps = NULL) {
  source <- match.arg(source)
  filter <- normalise_timeline_filter(mode %||% filter)
  speed <- normalise_timeline_speed(speed)
  if (!is.null(values)) {
    value_source <- normalise_timeline_value_source(source, values = values, frames = frames, time = time)
    if (identical(value_source, "time") && is.null(time)) {
      time <- values
    } else if (is.null(frames)) {
      frames <- values
    }
  }
  frames <- normalise_timeline_values(frames, "frame")
  time <- normalise_timeline_values(time, "time")
  values <- if (length(time)) time else frames
  source <- if (length(time)) "time" else if (length(frames)) "frame" else NULL
  out <- compact_list(list(
    frames = if (!length(frames)) NULL else unname(frames),
    time = if (!length(time)) NULL else unname(time),
    values = if (!length(values)) NULL else unname(values),
    source = source,
    duration = if (is.null(duration)) NULL else as.numeric(duration)[[1]],
    loop = isTRUE(loop),
    autoplay = isTRUE(autoplay),
    speed = speed,
    controls = isTRUE(controls),
    filter = filter,
    mode = filter,
    fps = if (is.null(fps)) NULL else normalise_timeline_fps(fps)
  ))
  class(out) <- c("ggwebgl_timeline", "list")
  out
}

normalise_timeline <- function(timeline) {
  if (is.null(timeline)) {
    return(NULL)
  }

  if (inherits(timeline, "ggwebgl_timeline")) {
    timeline <- unclass(timeline)
  }

  if (!is.list(timeline)) {
    return(NULL)
  }

  frames <- timeline[["frames"]] %||% NULL
  time <- timeline[["time"]] %||% NULL
  values <- timeline[["values"]] %||% NULL
  source <- normalise_timeline_value_source(timeline[["source"]] %||% "auto", values = values, frames = frames, time = time)
  filter <- normalise_timeline_filter(timeline[["mode"]] %||% timeline[["filter"]] %||% "exact")
  if (is.null(frames) && is.null(time) && !is.null(values)) {
    if (identical(source, "time")) {
      time <- values
    } else {
      frames <- values
    }
  }
  frames <- normalise_timeline_values(frames, "frame")
  time <- normalise_timeline_values(time, "time")
  values <- if (length(time)) time else frames
  source <- if (length(time)) "time" else if (length(frames)) "frame" else NULL

  compact_list(list(
    frames = if (!length(frames)) NULL else frames,
    time = if (!length(time)) NULL else time,
    values = if (!length(values)) NULL else values,
    source = source,
    duration = as.numeric(timeline[["duration"]] %||% max(1, length(frames %||% time %||% 1)))[[1]],
    loop = isTRUE(timeline[["loop"]] %||% TRUE),
    autoplay = isTRUE(timeline[["autoplay"]] %||% FALSE),
    speed = normalise_timeline_speed(timeline[["speed"]] %||% 1),
    controls = isTRUE(timeline[["controls"]] %||% TRUE),
    filter = filter,
    mode = filter,
    fps = if (is.null(timeline[["fps"]])) NULL else normalise_timeline_fps(timeline[["fps"]]),
    label = timeline[["label"]] %||% NULL,
    format = timeline[["format"]] %||% NULL
  ))
}

webgl_explicit_fields <- function(options = NULL, explicit_fields = NULL) {
  attr_fields <- attr(options, "explicit_fields", exact = TRUE) %||% NULL

  if (is.null(explicit_fields)) {
    explicit_fields <- attr_fields
  }

  if (is.null(explicit_fields) && is.list(options)) {
    explicit_fields <- setdiff(names(options), "extra")
  }

  unique(stats::na.omit(as.character(explicit_fields %||% character())))
}

webgl_explicit_options <- function(options = NULL) {
  if (is.null(options)) {
    return(list())
  }

  fields <- webgl_explicit_fields(options)
  values <- if (length(fields)) {
    options[intersect(fields, names(options))]
  } else {
    list()
  }

  if (!is.null(options[["extra"]]) && length(options[["extra"]])) {
    values[["extra"]] <- options[["extra"]]
  }

  attr(values, "explicit_fields") <- fields
  values
}

normalise_webgl_options <- function(options = NULL, explicit_fields = NULL) {
  defaults <- default_theme_webgl()

  if (inherits(options, "ggwebgl_theme")) {
    options <- unclass(options)
  }

  if (is.null(options)) {
    options <- list()
  }

  if (!is.list(options)) {
    options <- list()
  }

  explicit_fields <- webgl_explicit_fields(options, explicit_fields)
  extra <- options[["extra"]] %||% list()

  if (!is.list(extra)) {
    extra <- list()
  }

  recognised_extra_fields <- c(
    "line_mode", "line_join", "line_cap",
    "view", "selection", "dimension", "camera", "projection", "camera_state",
    "depth_test", "blend_mode", "timeline", "time_scale"
  )

  for (field in recognised_extra_fields) {
    if (is.null(options[[field]]) && !is.null(extra[[field]])) {
      options[[field]] <- extra[[field]]
      extra[[field]] <- NULL
    }
  }

  rendering <- normalise_rendering_mode(options[["rendering"]] %||% defaults[["rendering"]])
  interaction_default <- if (!"interactions" %in% explicit_fields && identical(rendering, "publication")) {
    character()
  } else {
    defaults[["interactions"]]
  }
  transparent_default <- if (!"transparent" %in% explicit_fields && identical(rendering, "publication")) {
    FALSE
  } else {
    defaults[["transparent"]]
  }

  interactions <- normalise_interactions(options[["interactions"]] %||% interaction_default, default = interaction_default)
  view <- normalise_view(
    options[["view"]] %||% NULL,
    dimension = options[["dimension"]] %||% defaults[["dimension"]],
    projection = options[["projection"]] %||% defaults[["projection"]],
    controller = options[["camera"]] %||% defaults[["camera"]],
    camera_state = options[["camera_state"]] %||% defaults[["camera_state"]]
  )
  selection <- normalise_selection(options[["selection"]] %||% NULL, interactions = interactions)
  interactions <- unique(c(interactions, selection_interactions(selection)))

  normalised <- compact_list(list(
    shader = normalise_shader_name(options[["shader"]] %||% defaults[["shader"]]),
    antialias = isTRUE(options[["antialias"]] %||% defaults[["antialias"]]),
    transparent = isTRUE(options[["transparent"]] %||% transparent_default),
    buffer_size = normalise_buffer_size(options[["buffer_size"]] %||% defaults[["buffer_size"]]),
    interactions = interactions,
    rendering = rendering,
    panel_overlay = normalise_panel_overlay(options[["panel_overlay"]] %||% defaults[["panel_overlay"]]),
    view = view,
    selection = selection,
    dimension = view$dimension,
    camera = if (identical(view$controller, "panzoom")) "orbit" else view$controller,
    projection = view$projection,
    camera_state = view$state,
    depth_test = normalise_depth_test(options[["depth_test"]] %||% defaults[["depth_test"]], view$dimension),
    blend_mode = normalise_blend_mode(options[["blend_mode"]] %||% defaults[["blend_mode"]]),
    timeline = normalise_timeline(options[["timeline"]] %||% defaults[["timeline"]]),
    time_scale = normalise_time_scale(options[["time_scale"]] %||% defaults[["time_scale"]]),
    line_mode = normalise_line_mode(options[["line_mode"]] %||% defaults[["line_mode"]]),
    line_join = normalise_line_join(options[["line_join"]] %||% defaults[["line_join"]]),
    line_cap = normalise_line_cap(options[["line_cap"]] %||% defaults[["line_cap"]]),
    extra = extra
  ))
  attr(normalised, "explicit_fields") <- explicit_fields
  normalised
}

preview_layer_data <- function(data, n = 100L) {
  if (is.null(data) || !is.data.frame(data) || !nrow(data)) {
    return(data.frame())
  }

  preferred_columns <- intersect(
    c("x", "y", "z", "xend", "yend", "zend", "xmin", "xmax", "ymin", "ymax",
      "colour", "fill", "size", "linewidth", "alpha", "group", "PANEL"),
    names(data)
  )

  if (!length(preferred_columns)) {
    preferred_columns <- names(data)
  }

  utils::head(as.data.frame(data[preferred_columns]), n)
}

standard_layout_columns <- function() {
  c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y", "COORD", "AXIS_X", "AXIS_Y")
}

mm_to_pixels <- function(x) {
  as.numeric(x) * (96 / 25.4)
}

normalise_range <- function(x) {
  x <- as.numeric(x)

  if (length(x) != 2L || any(!is.finite(x))) {
    return(c(0, 1))
  }

  if (identical(x[1], x[2])) {
    pad <- if (x[1] == 0) 0.5 else abs(x[1]) * 0.05
    x <- c(x[1] - pad, x[2] + pad)
  }

  x
}

coalesce_colour <- function(data) {
  colour <- data$colour %||% NULL

  if (is.null(colour) || all(is.na(colour))) {
    colour <- data$fill %||% NULL
  }

  if (is.null(colour)) {
    colour <- rep("#2C3E50", nrow(data))
  }

  colour
}

colour_to_rgba <- function(colour, alpha = NULL) {
  colour <- as.character(colour)
  colour[is.na(colour)] <- "#2C3E50"

  rgb <- grDevices::col2rgb(colour, alpha = FALSE) / 255

  if (is.null(alpha)) {
    alpha <- rep(1, length(colour))
  } else {
    alpha <- as.numeric(alpha)
    alpha[is.na(alpha)] <- 1
  }
  alpha <- pmax(0, pmin(1, alpha))

  cbind(
    red = rgb[1, ],
    green = rgb[2, ],
    blue = rgb[3, ],
    alpha = alpha
  )
}

rgba_to_bytes <- function(rgba) {
  rgba <- as.matrix(rgba)

  if (!nrow(rgba)) {
    return(integer())
  }

  storage.mode(rgba) <- "double"
  as.integer(pmax(0, pmin(255, round(rgba * 255))))
}

is_point_geom <- function(layer) {
  !is_mesh_geom(layer) &&
    (inherits(layer$geom, "GeomPoint") || identical(class(layer$geom)[1], "GeomPointWebGL"))
}

is_line_geom <- function(layer) {
  inherits(layer$geom, "GeomLine") ||
    inherits(layer$geom, "GeomPath") ||
    identical(class(layer$geom)[1], "GeomLineWebGL") ||
    is_path3d_geom(layer)
}

is_path3d_geom <- function(layer) {
  identical(class(layer$geom)[1], "GeomPath3DWebGL")
}

is_raster_geom <- function(layer) {
  !is_surface_geom(layer) &&
    (inherits(layer$geom, "GeomRaster") || identical(class(layer$geom)[1], "GeomRasterWebGL"))
}

is_vector_geom <- function(layer) {
  identical(class(layer$geom)[1], "GeomVectorWebGL")
}

is_mesh_geom <- function(layer) {
  identical(class(layer$geom)[1], "GeomMeshWebGL")
}

is_surface_geom <- function(layer) {
  identical(class(layer$geom)[1], "GeomSurfaceWebGL")
}

is_supported_geom <- function(layer) {
  is_vector_geom(layer) || is_mesh_geom(layer) || is_surface_geom(layer) ||
    is_point_geom(layer) || is_line_geom(layer) || is_raster_geom(layer)
}

split_path_runs <- function(data) {
  if (!nrow(data)) {
    return(list())
  }

  group_chr <- as.character(data$group %||% seq_len(nrow(data)))
  x_ok <- is.finite(as.numeric(data$x))
  y_ok <- is.finite(as.numeric(data$y))
  valid <- x_ok & y_ok

  run_break <- rep(TRUE, nrow(data))

  if (nrow(data) > 1L) {
    same_prev <- group_chr[-1] == group_chr[-nrow(data)]
    same_prev[is.na(same_prev)] <- FALSE
    run_break[-1] <- !(same_prev & valid[-1] & valid[-nrow(data)])
  }

  split_idx <- split(seq_len(nrow(data)), cumsum(run_break))
  Filter(
    f = function(idx) {
      length(idx) >= 2L && all(valid[idx])
    },
    x = split_idx
  )
}

split_ordered_group_path_runs <- function(data) {
  if (!nrow(data)) {
    return(list())
  }

  group_chr <- as.character(data$group %||% seq_len(nrow(data)))
  x_ok <- is.finite(as.numeric(data$x))
  y_ok <- is.finite(as.numeric(data$y))
  valid <- x_ok & y_ok
  group_levels <- unique(group_chr)
  out <- list()

  for (group_name in group_levels) {
    group_idx <- which(group_chr == group_name)
    if (!length(group_idx)) {
      next
    }

    run_break <- rep(TRUE, length(group_idx))
    if (length(group_idx) > 1L) {
      run_break[-1] <- !(valid[group_idx][-1] & valid[group_idx][-length(group_idx)])
    }

    group_runs <- split(group_idx, cumsum(run_break))
    group_runs <- Filter(
      f = function(idx) {
        length(idx) >= 2L && all(valid[idx])
      },
      x = group_runs
    )
    out <- c(out, group_runs)
  }

  out
}
