ggwebgl_boids_display_spec <- function(sim,
                                       boid_size = 4.2,
                                       prey_size = 4.8,
                                       predator_size = 7.5,
                                       current_alpha = 0.95,
                                       trail_alpha = 0.18,
                                       boid_alpha = NULL,
                                       vector_mode = c("current", "sampled", "all", "none"),
                                       vector_colour_mode = c("species", "role", "fixed"),
                                       vector_colour = "#334155",
                                       vector_alpha = 0.65,
                                       vector_width = 1.2,
                                       vector_every = 1L,
                                       vector_scale = 0.14,
                                       obstacle_mode = c("ring", "disc", "none"),
                                       obstacle_segments = 48L,
                                       obstacle_alpha = 0.9,
                                       trail = c("recent", "none", "all"),
                                       trail_length = 32L,
                                       shader = "default",
                                       role_palette = NULL,
                                       palette = NULL,
                                       autoplay = TRUE,
                                       loop = TRUE,
                                       speed = 1.4,
                                       playback_speed = NULL,
                                       fps = 24L,
                                       selected_frame = NULL,
                                       ...) {
  if (!requireNamespace("boids4R", quietly = TRUE)) {
    rlang::abort("`boids4R` is required to build boids display specifications.")
  }

  vector_mode <- match.arg(vector_mode)
  vector_colour_mode <- match.arg(vector_colour_mode)
  obstacle_mode <- match.arg(obstacle_mode)
  trail <- match.arg(trail)
  role_palette <- role_palette %||% palette
  current_alpha <- boid_alpha %||% current_alpha

  if (ggwebgl_boids_adapter_supports_display_args() && is.null(selected_frame)) {
    out <- boids4R::as_ggwebgl_spec(
      sim,
      boid_size = boid_size,
      prey_size = prey_size,
      predator_size = predator_size,
      current_alpha = current_alpha,
      trail_alpha = trail_alpha,
      trail = trail,
      trail_length = trail_length,
      vector_mode = vector_mode,
      vector_colour_mode = vector_colour_mode,
      vector_colour = vector_colour,
      vector_alpha = vector_alpha,
      vector_width = vector_width,
      vector_every = vector_every,
      vector_scale = vector_scale,
      obstacle_mode = obstacle_mode,
      obstacle_segments = obstacle_segments,
      obstacle_alpha = obstacle_alpha,
      shader = shader,
      role_palette = role_palette,
      ...
    )
    return(ggwebgl_boids_apply_timeline_presentation(
      out,
      autoplay = autoplay,
      loop = loop,
      speed = speed,
      playback_speed = playback_speed,
      fps = fps
    ))
  }

  adapter_vector_every <- if (identical(vector_mode, "sampled")) {
    as.integer(vector_every)
  } else {
    1L
  }

  spec <- boids4R::as_ggwebgl_spec(
    sim,
    vector_every = adapter_vector_every,
    vector_scale = vector_scale,
    shader = shader,
    ...
  )

  out <- ggwebgl_boids_apply_display_spec(
    spec,
    sim = sim,
    boid_size = boid_size,
    prey_size = prey_size,
    predator_size = predator_size,
    current_alpha = boid_alpha %||% current_alpha,
    trail_alpha = trail_alpha,
    vector_mode = vector_mode,
    vector_colour_mode = vector_colour_mode,
    vector_colour = vector_colour,
    vector_alpha = vector_alpha,
    vector_width = vector_width,
    vector_every = vector_every,
    obstacle_mode = obstacle_mode,
    obstacle_segments = obstacle_segments,
    obstacle_alpha = obstacle_alpha,
    trail = trail,
    trail_length = trail_length,
    shader = shader,
    palette = role_palette,
    selected_frame = selected_frame
  )
  ggwebgl_boids_apply_timeline_presentation(
    out,
    autoplay = autoplay,
    loop = loop,
    speed = speed,
    playback_speed = playback_speed,
    fps = fps
  )
}

ggwebgl_boids_adapter_supports_display_args <- function() {
  method <- getS3method(
    "as_ggwebgl_spec",
    "boids_simulation",
    envir = asNamespace("boids4R"),
    optional = TRUE
  )
  if (!is.function(method)) {
    return(FALSE)
  }

  required <- c(
    "role_palette",
    "boid_size",
    "prey_size",
    "predator_size",
    "current_alpha",
    "trail_alpha",
    "trail",
    "trail_length",
    "vector_mode",
    "vector_colour_mode",
    "vector_colour",
    "vector_alpha",
    "vector_width",
    "obstacle_mode",
    "obstacle_segments",
    "obstacle_alpha"
  )
  all(required %in% names(formals(method)))
}

ggwebgl_boids_apply_timeline_presentation <- function(spec,
                                                      autoplay = TRUE,
                                                      loop = TRUE,
                                                      speed = 1.4,
                                                      playback_speed = NULL,
                                                      fps = 24L) {
  timeline <- spec$render$timeline %||% spec$webgl$timeline %||% list()
  timeline$autoplay <- isTRUE(autoplay)
  timeline$loop <- isTRUE(loop)
  timeline$speed <- ggwebgl_boids_positive_scalar(playback_speed %||% speed, "speed")
  timeline$fps <- ggwebgl_boids_positive_integer(fps, "fps")
  spec$webgl <- spec$webgl %||% list()
  spec$render <- spec$render %||% list()
  spec$webgl$timeline <- timeline
  spec$render$timeline <- timeline
  spec
}

ggwebgl_boids_apply_display_spec <- function(spec,
                                             sim = NULL,
                                             obstacles = NULL,
                                             boid_size = 4.2,
                                             prey_size = 4.8,
                                             predator_size = 7.5,
                                             current_alpha = 0.95,
                                             trail_alpha = 0.18,
                                             boid_alpha = NULL,
                                             vector_mode = c("current", "sampled", "all", "none"),
                                             vector_colour_mode = c("species", "role", "fixed"),
                                             vector_colour = "#334155",
                                             vector_alpha = 0.65,
                                             vector_width = 1.2,
                                             vector_every = 1L,
                                             vector_scale = NULL,
                                             obstacle_mode = c("ring", "disc", "none"),
                                             obstacle_segments = 48L,
                                             obstacle_alpha = 0.9,
                                             trail = c("recent", "none", "all"),
                                             trail_length = 32L,
                                             shader = "default",
                                             palette = NULL,
                                             selected_frame = NULL) {
  if (!is.list(spec) || is.null(spec$render) || is.null(spec$render$layers)) {
    rlang::abort("`spec` must be a ggWebGL specification with `render$layers`.")
  }

  vector_mode <- match.arg(vector_mode)
  vector_colour_mode <- match.arg(vector_colour_mode)
  obstacle_mode <- match.arg(obstacle_mode)
  trail <- match.arg(trail)
  palette <- ggwebgl_boids_palette(palette)
  boid_size <- ggwebgl_boids_positive_scalar(boid_size, "boid_size")
  prey_size <- ggwebgl_boids_positive_scalar(prey_size, "prey_size")
  predator_size <- ggwebgl_boids_positive_scalar(predator_size, "predator_size")
  current_alpha <- ggwebgl_boids_alpha_scalar(boid_alpha %||% current_alpha, "current_alpha")
  trail_alpha <- ggwebgl_boids_alpha_scalar(trail_alpha, "trail_alpha")
  vector_alpha <- ggwebgl_boids_alpha_scalar(vector_alpha, "vector_alpha")
  vector_width <- ggwebgl_boids_positive_scalar(vector_width, "vector_width")
  vector_every <- ggwebgl_boids_positive_integer(vector_every, "vector_every")
  obstacle_segments <- ggwebgl_boids_positive_integer(obstacle_segments, "obstacle_segments")
  obstacle_alpha <- ggwebgl_boids_alpha_scalar(obstacle_alpha, "obstacle_alpha")
  trail_length <- ggwebgl_boids_positive_integer(trail_length, "trail_length")

  layers <- spec$render$layers
  frame_values <- ggwebgl_boids_layer_frames(layers)
  visible_frames <- ggwebgl_boids_visible_frames(frame_values, selected_frame, trail, trail_length)
  current_frame <- if (length(visible_frames)) {
    max(visible_frames, na.rm = TRUE)
  } else {
    selected_frame
  }

  if (ggwebgl_boids_has_frame_data(sim)) {
    processed <- ggwebgl_boids_layers_from_sim(
      sim = sim,
      frame_values = frame_values,
      trail_frames = visible_frames,
      current_frame = current_frame,
      trail = trail,
      boid_size = boid_size,
      prey_size = prey_size,
      predator_size = predator_size,
      current_alpha = current_alpha,
      trail_alpha = trail_alpha,
      vector_mode = vector_mode,
      vector_colour_mode = vector_colour_mode,
      vector_colour = vector_colour,
      vector_alpha = vector_alpha,
      vector_width = vector_width,
      vector_every = vector_every,
      vector_scale = vector_scale %||% 0.14,
      palette = palette,
      dimension = spec$render$dimension %||% spec$webgl$dimension %||% sim$dimension %||% "2d"
    )
  } else {
    processed <- list()
    for (layer in layers) {
      if (identical(layer$type, "points")) {
        layer <- ggwebgl_boids_style_points(layer, boid_size, current_alpha)
        keep <- ggwebgl_boids_keep_frame_rows(layer, visible_frames)
        layer <- ggwebgl_boids_filter_point_layer(layer, keep)
        if ((layer$rows %||% 0L) > 0L) {
          processed[[length(processed) + 1L]] <- layer
        }
      } else if (identical(layer$type, "vectors")) {
        if (identical(vector_mode, "none")) {
          next
        }
        keep <- ggwebgl_boids_keep_frame_rows(layer, visible_frames)
        if (identical(vector_mode, "sampled")) {
          sampled <- seq_along(keep) %% vector_every == 1L
          keep <- keep & sampled
        }
        layer <- ggwebgl_boids_filter_vector_layer(layer, keep)
        if (!is.null(vector_scale)) {
          layer <- ggwebgl_boids_scale_vectors(layer, vector_scale)
        }
        if ((layer$rows %||% 0L) > 0L) {
          processed[[length(processed) + 1L]] <- layer
        }
      } else {
        processed[[length(processed) + 1L]] <- layer
      }
    }
  }

  obstacle_layers <- ggwebgl_boids_obstacle_layers(
    sim = sim,
    obstacles = obstacles,
    mode = obstacle_mode,
    segments = obstacle_segments,
    dimension = spec$render$dimension %||% spec$webgl$dimension %||% "2d",
    colour = palette[["obstacle"]],
    alpha = obstacle_alpha
  )
  processed <- c(processed, obstacle_layers)

  webgl <- spec$webgl %||% list()
  webgl$shader <- shader
  webgl$timeline <- ggwebgl_boids_update_timeline(webgl$timeline %||% spec$render$timeline, processed, frame_values)

  out <- ggwebgl_spec(
    layers = processed,
    labels = spec$labels %||% list(),
    webgl = webgl,
    grid = spec$render$grid,
    messages = spec$render$messages %||% character()
  )

  out$render$messages <- unique(c(
    out$render$messages %||% character(),
    sprintf(
      "boids display: frame %s, trail=%s, vector_mode=%s, obstacles=%s",
      if (is.null(current_frame)) "all" else as.character(current_frame),
      trail,
      vector_mode,
      obstacle_mode
    )
  ))
  out
}

ggwebgl_boids_palette <- function(palette = NULL) {
  defaults <- c(
    species_1 = "#2563EB",
    species_2 = "#16A34A",
    species_3 = "#9333EA",
    prey = "#F59E0B",
    predator = "#DC2626",
    obstacle = "#111827",
    vector = "#334155",
    attractor = "#0891B2",
    trail = "#64748B"
  )
  if (is.null(palette)) {
    return(defaults)
  }
  palette <- as.character(palette)
  if (is.null(names(palette)) || any(!nzchar(names(palette)))) {
    rlang::abort("`palette` must be a named character vector.")
  }
  out <- defaults
  out[names(palette)] <- palette
  out
}

ggwebgl_boids_has_frame_data <- function(sim) {
  is.list(sim) &&
    is.data.frame(sim$frames) &&
    all(c("frame", "time", "id", "species", "x", "y", "vx", "vy") %in% names(sim$frames))
}

ggwebgl_boids_layers_from_sim <- function(sim,
                                          frame_values,
                                          trail_frames,
                                          current_frame,
                                          trail,
                                          boid_size,
                                          prey_size,
                                          predator_size,
                                          current_alpha,
                                          trail_alpha,
                                          vector_mode,
                                          vector_colour_mode,
                                          vector_colour,
                                          vector_alpha,
                                          vector_width,
                                          vector_every,
                                          vector_scale,
                                          palette,
                                          dimension) {
  frames <- as.data.frame(sim$frames, stringsAsFactors = FALSE)
  frames$z <- frames$z %||% 0
  frames$vz <- frames$vz %||% 0
  frames$role_colour <- ggwebgl_boids_frame_colours(frames, palette, has_predators = NROW(sim$world$predators %||% data.frame()) > 0L)
  frames$vector_colour <- ggwebgl_boids_vector_colours(frames, vector_colour_mode, vector_colour, palette)
  frames$current_size <- ifelse(
    ggwebgl_boids_is_prey(frames, has_predators = NROW(sim$world$predators %||% data.frame()) > 0L),
    prey_size,
    boid_size
  )
  layers <- list()

  if (!identical(trail, "none") && length(trail_frames)) {
    trail_data <- frames[frames$frame %in% trail_frames & frames$frame != current_frame, , drop = FALSE]
    if (nrow(trail_data)) {
      trail_data$trail_size <- pmax(1.4, boid_size * 0.45)
      layers[[length(layers) + 1L]] <- ggwebgl_layer_points(
        trail_data,
        x = "x",
        y = "y",
        z = if (identical(dimension, "3d")) "z" else NULL,
        colour = "role_colour",
        alpha = trail_alpha,
        size = "trail_size",
        label = "species",
        id = "id",
        geom = "boids_recent_trail"
      )
    }
  }

  current_data <- frames[frames$frame %in% frame_values, , drop = FALSE]
  if (nrow(current_data)) {
    layers[[length(layers) + 1L]] <- ggwebgl_layer_points(
      current_data,
      x = "x",
      y = "y",
      z = if (identical(dimension, "3d")) "z" else NULL,
      colour = "role_colour",
      alpha = current_alpha,
      size = "current_size",
      label = "species",
      id = "id",
      frame = "frame",
      time = "time",
      geom = "boids_current"
    )
  }

  if (!identical(vector_mode, "none") && nrow(current_data)) {
    vector_data <- current_data
    if (identical(vector_mode, "sampled")) {
      vector_data <- vector_data[seq_len(nrow(vector_data)) %% vector_every == 1L, , drop = FALSE]
    }
    if (nrow(vector_data)) {
      vector_data$xend <- vector_data$x + vector_data$vx * vector_scale
      vector_data$yend <- vector_data$y + vector_data$vy * vector_scale
      vector_data$zend <- vector_data$z + vector_data$vz * vector_scale
      layers[[length(layers) + 1L]] <- ggwebgl_layer_vectors(
        vector_data,
        x = "x",
        y = "y",
        z = if (identical(dimension, "3d")) "z" else NULL,
        xend = "xend",
        yend = "yend",
        zend = if (identical(dimension, "3d")) "zend" else NULL,
        colour = "vector_colour",
        alpha = vector_alpha,
        width = vector_width,
        head_size = 7,
        id = "id",
        frame = "frame",
        time = "time",
        geom = if (identical(vector_mode, "sampled")) "boids_velocity_sampled" else "boids_velocity_current"
      )
    }
  }

  role_layers <- ggwebgl_boids_static_role_layers(sim, palette, predator_size, dimension)
  c(layers, role_layers)
}

ggwebgl_boids_frame_colours <- function(frames, palette, has_predators = FALSE) {
  species <- as.character(frames$species %||% "boid")
  if (has_predators && length(unique(species)) == 1L && identical(unique(species), "boid")) {
    return(rep(palette[["prey"]], length(species)))
  }
  species_values <- unique(species)
  species_keys <- paste0("species_", ((seq_along(species_values) - 1L) %% 3L) + 1L)
  lookup <- stats::setNames(unname(palette[species_keys]), species_values)
  unname(lookup[species])
}

ggwebgl_boids_vector_colours <- function(frames,
                                         vector_colour_mode = "species",
                                         vector_colour = "#334155",
                                         palette = ggwebgl_boids_palette()) {
  vector_colour_mode <- match.arg(vector_colour_mode, c("species", "role", "fixed"))
  if (identical(vector_colour_mode, "fixed")) {
    return(rep(as.character(vector_colour)[[1L]], NROW(frames)))
  }
  if (identical(vector_colour_mode, "role") && !is.null(frames$role)) {
    role <- as.character(frames$role)
    out <- rep(palette[["vector"]], NROW(frames))
    out[role %in% "prey"] <- palette[["prey"]]
    out[role %in% "predator"] <- palette[["predator"]]
    out[role %in% "attractor"] <- palette[["attractor"]]
    return(out)
  }
  frames$role_colour %||% ggwebgl_boids_frame_colours(frames, palette)
}

ggwebgl_boids_is_prey <- function(frames, has_predators = FALSE) {
  species <- as.character(frames$species %||% "boid")
  has_predators & identical(unique(species), "boid")
}

ggwebgl_boids_static_role_layers <- function(sim, palette, predator_size, dimension) {
  layers <- list()
  predators <- ggwebgl_boids_static_role_table(sim$world$predators %||% NULL, "predator")
  if (NROW(predators)) {
    layers[[length(layers) + 1L]] <- ggwebgl_layer_points(
      predators,
      x = "x",
      y = "y",
      z = if (identical(dimension, "3d")) "z" else NULL,
      colour = palette[["predator"]],
      alpha = 0.95,
      size = predator_size,
      label = "label",
      id = "id",
      geom = "boids_predator"
    )
  }

  attractors <- ggwebgl_boids_static_role_table(sim$world$attractors %||% NULL, "attractor")
  if (NROW(attractors)) {
    layers[[length(layers) + 1L]] <- ggwebgl_layer_points(
      attractors,
      x = "x",
      y = "y",
      z = if (identical(dimension, "3d")) "z" else NULL,
      colour = palette[["attractor"]],
      alpha = 0.9,
      size = pmax(5, predator_size * 0.75),
      label = "label",
      id = "id",
      geom = "boids_attractor"
    )
  }
  layers
}

ggwebgl_boids_static_role_table <- function(data, role) {
  if (is.null(data)) {
    return(data.frame())
  }
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  if (!NROW(data) || !all(c("x", "y") %in% names(data))) {
    return(data.frame())
  }
  data$z <- data$z %||% 0
  data$id <- data$id %||% paste0(role, "-", seq_len(NROW(data)))
  data$label <- paste(role, seq_len(NROW(data)))
  data
}

ggwebgl_boids_positive_scalar <- function(value, name) {
  value <- as.numeric(value)
  if (length(value) != 1L || !is.finite(value) || value <= 0) {
    rlang::abort(sprintf("`%s` must be a positive finite scalar.", name))
  }
  value
}

ggwebgl_boids_alpha_scalar <- function(value, name) {
  value <- as.numeric(value)
  if (length(value) != 1L || !is.finite(value) || value < 0 || value > 1) {
    rlang::abort(sprintf("`%s` must be a finite scalar in [0, 1].", name))
  }
  value
}

ggwebgl_boids_positive_integer <- function(value, name) {
  value <- as.integer(value)
  if (length(value) != 1L || is.na(value) || value < 1L) {
    rlang::abort(sprintf("`%s` must be a positive integer scalar.", name))
  }
  value
}

ggwebgl_boids_layer_frames <- function(layers) {
  frames <- unlist(lapply(layers, function(layer) {
    if (identical(layer$type, "points") || identical(layer$type, "vectors")) {
      layer$frame %||% integer()
    } else {
      integer()
    }
  }), use.names = FALSE)
  frames <- as.integer(frames[is.finite(frames)])
  sort(unique(frames))
}

ggwebgl_boids_visible_frames <- function(frames, selected_frame, trail, trail_length) {
  if (!length(frames)) {
    return(integer())
  }
  current <- if (is.null(selected_frame)) {
    max(frames, na.rm = TRUE)
  } else {
    as.integer(selected_frame)
  }
  frames <- frames[frames <= current]
  if (!length(frames)) {
    return(current)
  }
  if (identical(trail, "all")) {
    frames
  } else if (identical(trail, "none")) {
    current
  } else {
    utils::tail(frames, trail_length)
  }
}

ggwebgl_boids_keep_frame_rows <- function(layer, visible_frames) {
  n <- as.integer(layer$rows %||% length(layer$x %||% numeric()))
  if (!length(visible_frames) || is.null(layer$frame)) {
    return(rep(TRUE, n))
  }
  layer$frame %in% visible_frames
}

ggwebgl_boids_style_points <- function(layer, boid_size, boid_alpha) {
  n <- as.integer(layer$rows %||% length(layer$x %||% numeric()))
  layer$size <- rep(boid_size, n)
  layer$rgba <- ggwebgl_boids_set_rgba_alpha(layer$rgba, n, boid_alpha)
  layer
}

ggwebgl_boids_set_rgba_alpha <- function(rgba, n, alpha) {
  rgba <- as.numeric(rgba %||% rep(c(0.07, 0.13, 0.21, alpha), n))
  if (length(rgba) < n * 4L) {
    rgba <- rep(rgba, length.out = n * 4L)
  }
  rgba <- matrix(rgba[seq_len(n * 4L)], ncol = 4L, byrow = TRUE)
  if (any(rgba > 1.5, na.rm = TRUE)) {
    rgba <- rgba / 255
  }
  rgba[, 4L] <- alpha
  unname(as.numeric(t(rgba)))
}

ggwebgl_boids_filter_point_layer <- function(layer, keep) {
  ggwebgl_boids_filter_flat_layer(
    layer,
    keep,
    fields = c("x", "y", "z", "size", "age", "label", "id", "frame", "time")
  )
}

ggwebgl_boids_filter_vector_layer <- function(layer, keep) {
  ggwebgl_boids_filter_flat_layer(
    layer,
    keep,
    fields = c("x", "y", "z", "xend", "yend", "zend", "width", "head_size", "id", "frame", "time")
  )
}

ggwebgl_boids_filter_flat_layer <- function(layer, keep, fields) {
  keep <- as.logical(keep)
  n <- as.integer(layer$rows %||% length(keep))
  if (length(keep) != n) {
    rlang::abort("Internal boids layer filter length does not match layer rows.")
  }
  for (field in fields) {
    if (!is.null(layer[[field]]) && length(layer[[field]]) == n) {
      layer[[field]] <- unname(layer[[field]][keep])
    }
  }
  if (!is.null(layer$rgba) && length(layer$rgba) >= n * 4L) {
    rgba <- matrix(as.numeric(layer$rgba[seq_len(n * 4L)]), ncol = 4L, byrow = TRUE)
    layer$rgba <- unname(as.numeric(t(rgba[keep, , drop = FALSE])))
  }
  layer$rows <- as.integer(sum(keep))
  layer
}

ggwebgl_boids_scale_vectors <- function(layer, vector_scale) {
  vector_scale <- ggwebgl_boids_positive_scalar(vector_scale, "vector_scale")
  layer$xend <- layer$x + (layer$xend - layer$x) * vector_scale
  layer$yend <- layer$y + (layer$yend - layer$y) * vector_scale
  if (!is.null(layer$z) && !is.null(layer$zend)) {
    layer$zend <- layer$z + (layer$zend - layer$z) * vector_scale
  }
  layer
}

ggwebgl_boids_obstacle_layers <- function(sim,
                                          obstacles = NULL,
                                          mode = "ring",
                                          segments = 48L,
                                          dimension = "2d",
                                          colour = "#111827",
                                          alpha = 0.9) {
  if (identical(mode, "none")) {
    return(list())
  }
  obstacles <- ggwebgl_boids_obstacle_table(sim, obstacles)
  if (!NROW(obstacles)) {
    return(list())
  }
  if (identical(mode, "disc")) {
    return(list(ggwebgl_boids_obstacle_disc_layer(obstacles, segments, dimension, colour, alpha)))
  }
  list(ggwebgl_boids_obstacle_ring_layer(obstacles, segments, dimension, colour, alpha))
}

ggwebgl_boids_obstacle_table <- function(sim, obstacles = NULL) {
  if (is.null(obstacles) && !is.null(sim$world$obstacles)) {
    obstacles <- sim$world$obstacles
  }
  if (is.null(obstacles)) {
    return(data.frame())
  }
  obstacles <- as.data.frame(obstacles, stringsAsFactors = FALSE)
  if (!NROW(obstacles)) {
    return(data.frame())
  }
  radius <- obstacles$radius %||% obstacles$r %||% obstacles$size
  required <- c("x", "y")
  if (!all(required %in% names(obstacles)) || is.null(radius)) {
    return(data.frame())
  }
  z <- obstacles$z %||% rep(0, NROW(obstacles))
  data.frame(
    x = as.numeric(obstacles$x),
    y = as.numeric(obstacles$y),
    z = as.numeric(z),
    radius = as.numeric(radius),
    id = if (!is.null(obstacles$id)) as.character(obstacles$id) else paste0("obstacle-", seq_len(NROW(obstacles))),
    stringsAsFactors = FALSE
  )
}

ggwebgl_boids_obstacle_ring_layer <- function(obstacles, segments, dimension, colour, alpha) {
  theta <- seq(0, 2 * pi, length.out = segments + 1L)
  ring <- do.call(rbind, lapply(seq_len(NROW(obstacles)), function(i) {
    data.frame(
      x = obstacles$x[[i]] + obstacles$radius[[i]] * cos(theta),
      y = obstacles$y[[i]] + obstacles$radius[[i]] * sin(theta),
      z = obstacles$z[[i]],
      group = obstacles$id[[i]],
      stringsAsFactors = FALSE
    )
  }))
  if (identical(dimension, "3d")) {
    ggwebgl_layer_lines(
      ring,
      x = "x",
      y = "y",
      z = "z",
      group = "group",
      colour = colour,
      alpha = alpha,
      width = 2.4,
      geom = "boids_obstacle_ring"
    )
  } else {
    ggwebgl_layer_lines(
      ring,
      x = "x",
      y = "y",
      group = "group",
      colour = colour,
      alpha = alpha,
      width = 2.4,
      geom = "boids_obstacle_ring"
    )
  }
}

ggwebgl_boids_obstacle_disc_layer <- function(obstacles, segments, dimension, colour, alpha) {
  theta <- seq(0, 2 * pi, length.out = segments + 1L)
  vertices <- list()
  triangles <- list()
  offset <- 0L
  for (i in seq_len(NROW(obstacles))) {
    disc_vertices <- data.frame(
      x = c(obstacles$x[[i]], obstacles$x[[i]] + obstacles$radius[[i]] * cos(theta[-length(theta)])),
      y = c(obstacles$y[[i]], obstacles$y[[i]] + obstacles$radius[[i]] * sin(theta[-length(theta)])),
      z = obstacles$z[[i]],
      id = obstacles$id[[i]],
      stringsAsFactors = FALSE
    )
    disc_triangles <- data.frame(
      i = offset + 1L,
      j = offset + seq.int(2L, segments + 1L),
      k = offset + c(seq.int(3L, segments + 1L), 2L),
      pick_id = obstacles$id[[i]],
      stringsAsFactors = FALSE
    )
    vertices[[i]] <- disc_vertices
    triangles[[i]] <- disc_triangles
    offset <- offset + nrow(disc_vertices)
  }
  vertices <- do.call(rbind, vertices)
  triangles <- do.call(rbind, triangles)
  ggwebgl_layer_mesh(
    vertices,
    x = "x",
    y = "y",
    z = if (identical(dimension, "3d")) "z" else NULL,
    triangles = triangles,
    i = "i",
    j = "j",
    k = "k",
    colour = colour,
    alpha = alpha,
    id = "id",
    pick_id = "pick_id",
    geom = "boids_obstacle_disc",
    shading = "mesh_flat",
    wireframe = TRUE
  )
}

ggwebgl_boids_update_timeline <- function(timeline, layers, visible_frames) {
  timeline <- timeline %||% list()
  if (!length(visible_frames)) {
    return(timeline)
  }

  frame_time <- ggwebgl_boids_frame_time_table(layers)
  visible_frames <- sort(unique(as.integer(visible_frames)))
  timeline$frames <- visible_frames
  if (nrow(frame_time)) {
    matched <- frame_time[match(visible_frames, frame_time$frame), , drop = FALSE]
    time_values <- matched$time
    if (all(is.finite(time_values))) {
      timeline$time <- unname(time_values)
    }
  }
  source <- timeline$source %||% "frame"
  timeline$values <- if (identical(source, "time") && !is.null(timeline$time)) {
    timeline$time
  } else {
    timeline$frames
  }
  timeline$controls <- isTRUE(timeline$controls %||% TRUE)
  timeline$autoplay <- isTRUE(timeline$autoplay %||% TRUE)
  timeline$loop <- isTRUE(timeline$loop %||% TRUE)
  timeline
}

ggwebgl_boids_frame_time_table <- function(layers) {
  rows <- lapply(layers, function(layer) {
    if (!is.null(layer$frame) && !is.null(layer$time) && length(layer$frame) == length(layer$time)) {
      data.frame(frame = as.integer(layer$frame), time = as.numeric(layer$time))
    } else {
      NULL
    }
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (!length(rows)) {
    return(data.frame(frame = integer(), time = numeric()))
  }
  out <- unique(do.call(rbind, rows))
  out <- out[is.finite(out$frame) & is.finite(out$time), , drop = FALSE]
  out[order(out$frame, out$time), , drop = FALSE][!duplicated(out$frame), , drop = FALSE]
}
