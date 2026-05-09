temporal_spiral_data <- function(n = 80L) {
  n <- as.integer(n)[[1L]]
  if (!is.finite(n) || n < 3L) {
    stop("`n` must be an integer count of at least 3.", call. = FALSE)
  }

  time <- seq(0, 2 * pi, length.out = n)
  radius <- seq(0.2, 1, length.out = n)
  data.frame(
    x = cos(time) * radius,
    y = sin(time) * radius,
    z = rep(0, n),
    frame = seq_len(n),
    time = time,
    group = "spiral",
    stringsAsFactors = FALSE
  )
}

temporal_helix_data <- function(n = 120L) {
  n <- as.integer(n)[[1L]]
  if (!is.finite(n) || n < 3L) {
    stop("`n` must be an integer count of at least 3.", call. = FALSE)
  }

  time <- seq(0, 4 * pi, length.out = n)
  data.frame(
    x = cos(time),
    y = sin(time),
    z = time / max(time),
    frame = seq_len(n),
    time = time,
    group = "helix",
    stringsAsFactors = FALSE
  )
}

temporal_particle_tracks <- function(frames = 60L, particles = 4L) {
  frames <- as.integer(frames)[[1L]]
  particles <- as.integer(particles)[[1L]]
  if (!is.finite(frames) || frames < 3L) {
    stop("`frames` must be an integer count of at least 3.", call. = FALSE)
  }
  if (!is.finite(particles) || particles < 1L) {
    stop("`particles` must be a positive integer count.", call. = FALSE)
  }

  ids <- paste0("p", seq_len(particles))
  frame_values <- seq_len(frames)
  time_values <- seq(0, 1, length.out = frames)
  out <- expand.grid(
    frame = frame_values,
    id = ids,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  particle_index <- match(out$id, ids)
  tt <- time_values[out$frame]
  phase <- particle_index * 0.7

  out$time <- tt
  out$x <- cos(2 * pi * tt + phase) * (0.45 + 0.06 * particle_index) + 0.35 * tt
  out$y <- sin(2 * pi * tt + phase) * (0.35 + 0.04 * particle_index) + 0.12 * particle_index
  out$z <- 0.15 * particle_index / particles + 0.85 * tt
  out$group <- out$id
  out
}

temporal_trajectory_palette <- function(n) {
  palette <- c("#2563eb", "#f97316", "#0f766e", "#9333ea", "#be123c", "#475569")
  rep(palette, length.out = n)
}

temporal_spiral_widget <- function(height = 340) {
  data <- temporal_spiral_data()
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(x, y, z = z, frame = frame, time = time, group = group)
  ) +
    ggWebGL::geom_path3d_webgl(linewidth = 1.15, alpha = 0.9, colour = "#2563eb") +
    ggplot2::coord_equal() +
    ggWebGL::theme_webgl(
      shader = "trajectory_age",
      timeline = ggWebGL::animation_spec(
        frames = data$frame[-1L],
        filter = "cumulative",
        autoplay = TRUE,
        loop = TRUE,
        speed = 1,
        controls = TRUE
      ),
      view = ggWebGL::ggwebgl_view(dimension = "2d", controller = "panzoom"),
      interactions = c("pan", "zoom", "hover")
    )

  ggWebGL::ggplot_webgl(plot, height = height)
}

temporal_helix_widget <- function(height = 360) {
  data <- temporal_helix_data()
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(x, y, z = z, frame = frame, time = time, group = group)
  ) +
    ggWebGL::geom_path3d_webgl(linewidth = 1.25, alpha = 0.92, colour = "#0f766e") +
    ggWebGL::theme_webgl(
      shader = "trajectory_age",
      timeline = ggWebGL::animation_spec(
        time = data$time[-1L],
        source = "time",
        filter = "cumulative",
        autoplay = TRUE,
        loop = TRUE,
        speed = 1,
        controls = TRUE
      ),
      view = ggWebGL::ggwebgl_view(
        dimension = "3d",
        projection = "perspective",
        controller = "orbit"
      ),
      interactions = c("pan", "zoom", "hover")
    )

  ggWebGL::ggplot_webgl(plot, height = height)
}

temporal_velocity_widget <- function(height = 340) {
  data <- temporal_particle_tracks(frames = 50L, particles = 4L)
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(x, y, z = z, frame = frame, time = time, group = group, colour = id)
  ) +
    ggWebGL::geom_path3d_webgl(linewidth = 1.05, alpha = 0.88) +
    ggplot2::scale_colour_manual(
      values = temporal_trajectory_palette(length(unique(data$id))),
      guide = "none"
    ) +
    ggWebGL::theme_webgl(
      shader = "trajectory_velocity",
      timeline = ggWebGL::animation_spec(
        frames = sort(unique(data$frame))[-1L],
        filter = "cumulative",
        autoplay = TRUE,
        loop = TRUE,
        speed = 1.2,
        controls = TRUE
      ),
      view = ggWebGL::ggwebgl_view(
        dimension = "3d",
        projection = "perspective",
        controller = "orbit"
      ),
      interactions = c("pan", "zoom", "hover")
    )

  ggWebGL::ggplot_webgl(plot, height = height)
}

temporal_direction_widget <- function(height = 340) {
  data <- temporal_particle_tracks(frames = 50L, particles = 3L)
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(x, y, z = z, frame = frame, time = time, group = group, colour = id)
  ) +
    ggWebGL::geom_path3d_webgl(linewidth = 1.1, alpha = 0.9) +
    ggplot2::scale_colour_manual(
      values = temporal_trajectory_palette(length(unique(data$id))),
      guide = "none"
    ) +
    ggWebGL::theme_webgl(
      shader = "trajectory_direction",
      timeline = ggWebGL::animation_spec(
        time = sort(unique(data$time))[-1L],
        source = "time",
        filter = "cumulative",
        autoplay = TRUE,
        loop = TRUE,
        controls = TRUE
      ),
      view = ggWebGL::ggwebgl_view(
        dimension = "3d",
        projection = "perspective",
        controller = "trackball"
      ),
      interactions = c("pan", "zoom", "hover")
    )

  ggWebGL::ggplot_webgl(plot, height = height)
}

temporal_exact_particles_widget <- function(height = 320) {
  data <- temporal_particle_tracks(frames = 36L, particles = 5L)
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(x, y, frame = frame, time = time, colour = id)
  ) +
    ggWebGL::geom_point_webgl(size = 2.2, alpha = 0.78) +
    ggplot2::scale_colour_manual(
      values = temporal_trajectory_palette(length(unique(data$id))),
      guide = "none"
    ) +
    ggplot2::coord_equal() +
    ggWebGL::theme_webgl(
      shader = "default",
      timeline = ggWebGL::animation_spec(
        frames = sort(unique(data$frame)),
        filter = "exact",
        autoplay = TRUE,
        loop = TRUE,
        speed = 1,
        controls = TRUE
      ),
      view = ggWebGL::ggwebgl_view(dimension = "2d", controller = "panzoom"),
      interactions = c("pan", "zoom", "hover")
    )

  ggWebGL::ggplot_webgl(plot, height = height)
}

temporal_trajectory_widgets <- function() {
  list(
    spiral = temporal_spiral_widget(),
    helix = temporal_helix_widget(),
    velocity = temporal_velocity_widget(),
    direction = temporal_direction_widget(),
    exact_particles = temporal_exact_particles_widget()
  )
}
