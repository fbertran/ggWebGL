ggwebgl_boids_display_spec <- function(sim,
                                       boid_size = 3.5,
                                       boid_alpha = 0.85,
                                       vector_mode = c("current", "sampled", "all", "none"),
                                       vector_every = 1L,
                                       vector_scale = 0.14,
                                       obstacle_mode = c("ring", "disc", "none"),
                                       obstacle_segments = 48L,
                                       trail = c("recent", "none", "all"),
                                       trail_length = 20L,
                                       shader = "default",
                                       autoplay = TRUE,
                                       loop = TRUE,
                                       speed = 1.4,
                                       selected_frame = NULL,
                                       ...) {
  if (!requireNamespace("boids4R", quietly = TRUE)) {
    rlang::abort("`boids4R` is required to build boids display specifications.")
  }

  vector_mode <- match.arg(vector_mode)
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
    boid_alpha = boid_alpha,
    vector_mode = vector_mode,
    vector_every = vector_every,
    obstacle_mode = obstacle_mode,
    obstacle_segments = obstacle_segments,
    trail = trail,
    trail_length = trail_length,
    shader = shader,
    selected_frame = selected_frame
  )
  out$webgl$timeline$autoplay <- isTRUE(autoplay)
  out$webgl$timeline$loop <- isTRUE(loop)
  out$webgl$timeline$speed <- ggwebgl_boids_positive_scalar(speed, "speed")
  out$render$timeline$autoplay <- out$webgl$timeline$autoplay
  out$render$timeline$loop <- out$webgl$timeline$loop
  out$render$timeline$speed <- out$webgl$timeline$speed
  out
}

ggwebgl_boids_apply_display_spec <- function(spec,
                                             sim = NULL,
                                             obstacles = NULL,
                                             boid_size = 3.5,
                                             boid_alpha = 0.85,
                                             vector_mode = c("current", "sampled", "all", "none"),
                                             vector_every = 1L,
                                             vector_scale = NULL,
                                             obstacle_mode = c("ring", "disc", "none"),
                                             obstacle_segments = 48L,
                                             trail = c("recent", "none", "all"),
                                             trail_length = 20L,
                                             shader = "default",
                                             selected_frame = NULL) {
  if (!is.list(spec) || is.null(spec$render) || is.null(spec$render$layers)) {
    rlang::abort("`spec` must be a ggWebGL specification with `render$layers`.")
  }

  vector_mode <- match.arg(vector_mode)
  obstacle_mode <- match.arg(obstacle_mode)
  trail <- match.arg(trail)
  boid_size <- ggwebgl_boids_positive_scalar(boid_size, "boid_size")
  boid_alpha <- ggwebgl_boids_alpha_scalar(boid_alpha, "boid_alpha")
  vector_every <- ggwebgl_boids_positive_integer(vector_every, "vector_every")
  obstacle_segments <- ggwebgl_boids_positive_integer(obstacle_segments, "obstacle_segments")
  trail_length <- ggwebgl_boids_positive_integer(trail_length, "trail_length")

  layers <- spec$render$layers
  frame_values <- ggwebgl_boids_layer_frames(layers)
  visible_frames <- ggwebgl_boids_visible_frames(frame_values, selected_frame, trail, trail_length)
  current_frame <- if (length(visible_frames)) {
    max(visible_frames, na.rm = TRUE)
  } else {
    selected_frame
  }

  processed <- list()
  for (layer in layers) {
    if (identical(layer$type, "points")) {
      layer <- ggwebgl_boids_style_points(layer, boid_size, boid_alpha)
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

  obstacle_layers <- ggwebgl_boids_obstacle_layers(
    sim = sim,
    obstacles = obstacles,
    mode = obstacle_mode,
    segments = obstacle_segments,
    dimension = spec$render$dimension %||% spec$webgl$dimension %||% "2d"
  )
  processed <- c(processed, obstacle_layers)

  webgl <- spec$webgl %||% list()
  webgl$shader <- shader
  webgl$timeline <- ggwebgl_boids_update_timeline(webgl$timeline %||% spec$render$timeline, processed, visible_frames)

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

ggwebgl_boids_obstacle_layers <- function(sim, obstacles = NULL, mode = "ring", segments = 48L, dimension = "2d") {
  if (identical(mode, "none")) {
    return(list())
  }
  obstacles <- ggwebgl_boids_obstacle_table(sim, obstacles)
  if (!NROW(obstacles)) {
    return(list())
  }
  if (identical(mode, "disc")) {
    return(list(ggwebgl_boids_obstacle_disc_layer(obstacles, segments, dimension)))
  }
  list(ggwebgl_boids_obstacle_ring_layer(obstacles, segments, dimension))
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

ggwebgl_boids_obstacle_ring_layer <- function(obstacles, segments, dimension) {
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
      colour = "#ef4444",
      alpha = 0.9,
      width = 2.4,
      geom = "boids_obstacle_ring"
    )
  } else {
    ggwebgl_layer_lines(
      ring,
      x = "x",
      y = "y",
      group = "group",
      colour = "#ef4444",
      alpha = 0.9,
      width = 2.4,
      geom = "boids_obstacle_ring"
    )
  }
}

ggwebgl_boids_obstacle_disc_layer <- function(obstacles, segments, dimension) {
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
    colour = "#ef4444",
    alpha = 0.28,
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
