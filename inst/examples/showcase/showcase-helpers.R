match_showcase_detail <- function(detail = c("standard", "high_detail")) {
  match.arg(detail)
}

value_or <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

showcase_detail_spec <- function(detail = c("standard", "high_detail")) {
  detail <- match_showcase_detail(detail)

  switch(
    detail,
    standard = list(
      name = detail,
      latent_cloud = list(
        core_n = 2200L,
        bridge_primary_n = 1600L
      ),
      diffusion_paths = list(
        n_paths = 72L,
        steps = 42L
      ),
      phase_portrait = list(
        n_paths = 36L,
        steps = 180L,
        dt = 0.045
      ),
      loss_landscape = list(
        grid_n = 62L,
        steps = 26L,
        methods = data.frame(
          method = c("SGD", "Momentum", "Adam-like"),
          lr = c(0.080, 0.055, 0.060),
          momentum = c(0.00, 0.68, 0.35),
          start_x = c(-2.7, 2.4, -1.4),
          start_y = c(2.6, 2.3, -2.8),
          colour_hex = c("#0f766e", "#b45309", "#2563eb"),
          stringsAsFactors = FALSE
        )
      )
    ),
    high_detail = list(
      name = detail,
      latent_cloud = list(
        core_n = 6000L,
        halo_n = 5000L,
        bridge_primary_n = 7000L,
        bridge_secondary_n = 6000L,
        ambient_n = 8000L
      ),
      diffusion_paths = list(
        n_paths = 240L,
        steps = 96L,
        attractor_cloud_n = 900L
      ),
      phase_portrait = list(
        n_paths = 108L,
        steps = 320L,
        dt = 0.040
      ),
      loss_landscape = list(
        grid_n = 170L,
        steps = 64L,
        methods = data.frame(
          method = c("SGD", "Momentum", "Adam-like", "Nesterov", "RMSProp", "AdaGrad-like"),
          lr = c(0.080, 0.055, 0.060, 0.052, 0.038, 0.048),
          momentum = c(0.00, 0.68, 0.35, 0.82, 0.20, 0.10),
          start_x = c(-2.7, 2.4, -1.4, 1.8, -2.1, 0.6),
          start_y = c(2.6, 2.3, -2.8, -2.4, 0.9, 2.9),
          colour_hex = c("#0f766e", "#b45309", "#2563eb", "#be123c", "#7c3aed", "#0f766e"),
          stringsAsFactors = FALSE
        )
      )
    )
  )
}

showcase_metadata <- function() {
  list(
    latent_cloud = list(
      title = "Latent-Space Population Structure",
      subtitle = "Dense point rendering for transitional structure in an embedding",
      use_case = paste(
        "This example targets the package user question of whether the",
        "package can reveal dense geometric structure without abandoning the",
        "grammar-of-graphics workflow."
      ),
      reading_hint = paste(
        "Warm-coloured bridges connect cooler cluster cores, suggesting",
        "continuous transitions rather than isolated classes."
      )
    ),
    diffusion_paths = list(
      title = "Diffusion-Style Denoising Trajectories",
      subtitle = "Many-path line rendering for generative dynamics",
      use_case = paste(
        "This is the generative-ML case: the package is used to show how",
        "stochastic trajectories collapse toward learned modes over time."
      ),
      reading_hint = paste(
        "Each polyline is one denoising path; endpoint points expose where",
        "trajectories ultimately concentrate."
      )
    ),
    phase_portrait = list(
      title = "Nonlinear Phase Portrait",
      subtitle = "Scientific-visualization framing for dense trajectory bundles",
      use_case = paste(
        "This scenario positions ggWebGL as a scientific-visualization tool",
        "for dynamical systems, not only as an exploratory scatterplot engine."
      ),
      reading_hint = paste(
        "The repeated loops and convergence behaviour show how many initial",
        "conditions evolve under the same nonlinear dynamics."
      )
    ),
    loss_landscape = list(
      title = "Optimization Paths on a Surrogate Loss Landscape",
      subtitle = "Mixed layers combining dense points with optimization traces",
      use_case = paste(
        "This example is meant to show that the package can",
        "layer dense context and analytical trajectories in a single WebGL scene."
      ),
      reading_hint = paste(
        "The background point cloud encodes the surrogate landscape while",
        "coloured traces show optimizer-specific descent behaviour."
      )
    )
  )
}

showcase_theme <- function(shader) {
  theme_webgl(
    shader = shader,
    interactions = c("pan", "zoom", "hover")
  )
}

sample_gaussian_cloud <- function(n, center, covariance) {
  z <- matrix(stats::rnorm(n * 2L), ncol = 2L)
  sweep(z %*% chol(covariance), 2L, center, `+`)
}

sample_arc_bridge <- function(n,
                              x_start,
                              x_end,
                              amplitude,
                              y_offset = 0,
                              phase = 0,
                              harmonic = 1,
                              x_sd = 0.20,
                              y_sd = 0.18) {
  t <- runif(n)
  cbind(
    x_start + (x_end - x_start) * t + stats::rnorm(n, sd = x_sd),
    y_offset + amplitude * sin(pi * t * harmonic + phase) + stats::rnorm(n, sd = y_sd)
  )
}

showcase_latent_cloud_plot <- function(seed = 2026L, detail = c("standard", "high_detail")) {
  detail <- match_showcase_detail(detail)
  spec <- showcase_detail_spec(detail)$latent_cloud
  set.seed(seed)

  if (identical(detail, "standard")) {
    a <- sample_gaussian_cloud(spec$core_n, c(-3.0, -1.1), matrix(c(0.50, 0.10, 0.10, 0.28), 2))
    b <- sample_gaussian_cloud(spec$core_n, c(0.0, 2.3), matrix(c(0.42, -0.08, -0.08, 0.34), 2))
    c <- sample_gaussian_cloud(spec$core_n, c(3.3, -1.4), matrix(c(0.58, 0.12, 0.12, 0.36), 2))
    bridge <- sample_arc_bridge(
      spec$bridge_primary_n,
      x_start = -2.9,
      x_end = 3.2,
      amplitude = 1.45,
      x_sd = 0.20,
      y_sd = 0.18
    )

    data <- rbind(
      data.frame(x = a[, 1], y = a[, 2], regime = "Stable mode A"),
      data.frame(x = b[, 1], y = b[, 2], regime = "Stable mode B"),
      data.frame(x = c[, 1], y = c[, 2], regime = "Stable mode C"),
      data.frame(x = bridge[, 1], y = bridge[, 2], regime = "Transitional bridge")
    )

    data$regime <- factor(
      data$regime,
      levels = c("Stable mode A", "Stable mode B", "Stable mode C", "Transitional bridge")
    )

    palette <- c(
      "Stable mode A" = "#0f766e",
      "Stable mode B" = "#b45309",
      "Stable mode C" = "#7c3aed",
      "Transitional bridge" = "#dc2626"
    )

    return(
      ggplot2::ggplot(data, ggplot2::aes(x, y, colour = regime)) +
        geom_point_webgl(size = 1.15, alpha = 0.62) +
        ggplot2::scale_colour_manual(values = palette) +
        ggplot2::coord_equal() +
        ggplot2::labs(
          title = showcase_metadata()$latent_cloud$title,
          subtitle = showcase_metadata()$latent_cloud$subtitle,
          x = "Latent dimension 1",
          y = "Latent dimension 2"
        ) +
        showcase_theme("density_splat")
    )
  }

  palette <- c(
    "Stable mode A" = "#0f766e",
    "Stable mode B" = "#b45309",
    "Stable mode C" = "#7c3aed",
    "Transitional bridge" = "#dc2626"
  )

  cluster_centers <- list(
    "Stable mode A" = c(-3.0, -1.1),
    "Stable mode B" = c(0.0, 2.3),
    "Stable mode C" = c(3.3, -1.4)
  )
  cluster_covariances <- list(
    "Stable mode A" = matrix(c(0.50, 0.10, 0.10, 0.28), 2),
    "Stable mode B" = matrix(c(0.42, -0.08, -0.08, 0.34), 2),
    "Stable mode C" = matrix(c(0.58, 0.12, 0.12, 0.36), 2)
  )
  halo_covariances <- list(
    "Stable mode A" = matrix(c(1.30, 0.18, 0.18, 0.78), 2),
    "Stable mode B" = matrix(c(1.00, -0.10, -0.10, 0.92), 2),
    "Stable mode C" = matrix(c(1.46, 0.24, 0.24, 0.95), 2)
  )

  core_layers <- do.call(
    rbind,
    lapply(names(cluster_centers), function(label) {
      cloud <- sample_gaussian_cloud(spec$core_n, cluster_centers[[label]], cluster_covariances[[label]])
      data.frame(x = cloud[, 1], y = cloud[, 2], regime = label)
    })
  )
  halo_layers <- do.call(
    rbind,
    lapply(names(cluster_centers), function(label) {
      cloud <- sample_gaussian_cloud(spec$halo_n, cluster_centers[[label]], halo_covariances[[label]])
      data.frame(x = cloud[, 1], y = cloud[, 2], regime = label)
    })
  )
  ambient_a <- sample_gaussian_cloud(spec$ambient_n %/% 4L, c(-2.4, -1.0), matrix(c(2.6, 0.2, 0.2, 1.7), 2))
  ambient_b <- sample_gaussian_cloud(spec$ambient_n %/% 4L, c(0.0, 1.8), matrix(c(2.1, -0.1, -0.1, 1.8), 2))
  ambient_c <- sample_gaussian_cloud(spec$ambient_n %/% 4L, c(2.7, -1.3), matrix(c(2.8, 0.3, 0.3, 1.8), 2))
  ambient_bridge <- sample_arc_bridge(
    spec$ambient_n - 3L * (spec$ambient_n %/% 4L),
    x_start = -3.1,
    x_end = 3.4,
    amplitude = 1.10,
    y_offset = -0.35,
    phase = 0.45,
    harmonic = 1.5,
    x_sd = 0.32,
    y_sd = 0.24
  )
  ambient_layers <- rbind(
    data.frame(x = ambient_a[, 1], y = ambient_a[, 2], regime = "Stable mode A"),
    data.frame(x = ambient_b[, 1], y = ambient_b[, 2], regime = "Stable mode B"),
    data.frame(x = ambient_c[, 1], y = ambient_c[, 2], regime = "Stable mode C"),
    data.frame(x = ambient_bridge[, 1], y = ambient_bridge[, 2], regime = "Transitional bridge")
  )
  bridge_primary <- sample_arc_bridge(
    spec$bridge_primary_n,
    x_start = -2.9,
    x_end = 3.2,
    amplitude = 1.45,
    x_sd = 0.18,
    y_sd = 0.16
  )
  bridge_secondary <- sample_arc_bridge(
    spec$bridge_secondary_n,
    x_start = -3.0,
    x_end = 3.0,
    amplitude = 0.65,
    y_offset = -0.95,
    phase = -0.35,
    harmonic = 1.7,
    x_sd = 0.20,
    y_sd = 0.18
  )
  bridge_layers <- rbind(
    data.frame(x = bridge_primary[, 1], y = bridge_primary[, 2], regime = "Transitional bridge"),
    data.frame(x = bridge_secondary[, 1], y = bridge_secondary[, 2], regime = "Transitional bridge")
  )

  core_layers$regime <- factor(core_layers$regime, levels = names(palette))
  halo_layers$regime <- factor(halo_layers$regime, levels = names(palette))
  ambient_layers$regime <- factor(ambient_layers$regime, levels = names(palette))
  bridge_layers$regime <- factor(bridge_layers$regime, levels = names(palette))

  ggplot2::ggplot() +
    geom_point_webgl(
      data = ambient_layers,
      mapping = ggplot2::aes(x, y, colour = regime),
      size = 0.60,
      alpha = 0.08,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = halo_layers,
      mapping = ggplot2::aes(x, y, colour = regime),
      size = 2.70,
      alpha = 0.08,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = bridge_layers,
      mapping = ggplot2::aes(x, y, colour = regime),
      size = 0.95,
      alpha = 0.18,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = core_layers,
      mapping = ggplot2::aes(x, y, colour = regime),
      size = 1.05,
      alpha = 0.66,
      inherit.aes = FALSE
    ) +
    ggplot2::scale_colour_manual(values = palette, limits = names(palette), drop = FALSE) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = showcase_metadata()$latent_cloud$title,
      subtitle = showcase_metadata()$latent_cloud$subtitle,
      x = "Latent dimension 1",
      y = "Latent dimension 2"
    ) +
    showcase_theme("density_splat")
}

showcase_diffusion_paths_plot <- function(seed = 2027L,
                                          n_paths = NULL,
                                          steps = NULL,
                                          detail = c("standard", "high_detail")) {
  detail <- match_showcase_detail(detail)
  spec <- showcase_detail_spec(detail)$diffusion_paths
  n_paths <- as.integer(value_or(n_paths, spec$n_paths))
  steps <- as.integer(value_or(steps, spec$steps))
  set.seed(seed)

  attractors <- rbind(
    c(-2.2, -1.1),
    c(2.4, -0.8),
    c(0.2, 2.5)
  )
  labels <- c("Mode A", "Mode B", "Mode C")
  palette <- c("Mode A" = "#0f766e", "Mode B" = "#c2410c", "Mode C" = "#7c3aed")

  path_list <- vector("list", n_paths)
  end_list <- vector("list", n_paths)
  start_list <- vector("list", n_paths)

  for (i in seq_len(n_paths)) {
    target_id <- ((i - 1L) %% nrow(attractors)) + 1L
    target <- attractors[target_id, ]
    theta <- runif(1L, 0, 2 * pi)
    radius <- if (identical(detail, "standard")) runif(1L, 3.5, 5.2) else runif(1L, 4.0, 6.4)
    current <- c(radius * cos(theta), radius * sin(theta))
    origin <- current
    trace <- matrix(NA_real_, nrow = steps, ncol = 2L)

    for (step in seq_len(steps)) {
      noise_scale <- if (identical(detail, "standard")) {
        0.35 * exp(-0.06 * step)
      } else {
        0.42 * exp(-0.035 * step)
      }

      current <- 0.78 * current + 0.22 * target + stats::rnorm(2L, sd = noise_scale)
      trace[step, ] <- current
    }

    label <- labels[target_id]
    path_list[[i]] <- data.frame(
      x = trace[, 1],
      y = trace[, 2],
      step = seq_len(steps),
      path_id = paste0("path_", i),
      mode = label
    )
    start_list[[i]] <- data.frame(
      x = origin[1],
      y = origin[2],
      mode = label
    )
    end_list[[i]] <- data.frame(
      x = trace[steps, 1],
      y = trace[steps, 2],
      mode = label
    )
  }

  paths <- do.call(rbind, path_list)
  starts <- do.call(rbind, start_list)
  endpoints <- do.call(rbind, end_list)

  if (identical(detail, "standard")) {
    return(
      ggplot2::ggplot(paths, ggplot2::aes(x, y, group = path_id, colour = mode)) +
        geom_line_webgl(linewidth = 0.9, alpha = 0.42) +
        geom_point_webgl(
          data = endpoints,
          mapping = ggplot2::aes(x, y, colour = mode),
          size = 2.1,
          alpha = 0.95,
          inherit.aes = FALSE
        ) +
        ggplot2::scale_colour_manual(values = palette) +
        ggplot2::coord_equal() +
        ggplot2::labs(
          title = showcase_metadata()$diffusion_paths$title,
          subtitle = showcase_metadata()$diffusion_paths$subtitle,
          x = "State dimension 1",
          y = "State dimension 2"
        ) +
        showcase_theme("trajectory_age")
    )
  }

  attractor_context <- do.call(
    rbind,
    lapply(seq_len(nrow(attractors)), function(i) {
      cloud <- sample_gaussian_cloud(
        spec$attractor_cloud_n,
        attractors[i, ],
        matrix(c(0.22, 0, 0, 0.22), 2)
      )
      data.frame(x = cloud[, 1], y = cloud[, 2], mode = labels[i])
    })
  )
  attractor_core <- do.call(
    rbind,
    lapply(seq_len(nrow(attractors)), function(i) {
      cloud <- sample_gaussian_cloud(
        max(180L, spec$attractor_cloud_n %/% 4L),
        attractors[i, ],
        matrix(c(0.08, 0, 0, 0.08), 2)
      )
      data.frame(x = cloud[, 1], y = cloud[, 2], mode = labels[i])
    })
  )

  ggplot2::ggplot() +
    geom_point_webgl(
      data = attractor_context,
      mapping = ggplot2::aes(x, y, colour = mode),
      size = 1.10,
      alpha = 0.24,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = attractor_core,
      mapping = ggplot2::aes(x, y, colour = mode),
      size = 1.55,
      alpha = 0.42,
      inherit.aes = FALSE
    ) +
    geom_line_webgl(
      data = paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = mode),
      linewidth = 2.50,
      alpha = 0.12,
      inherit.aes = FALSE
    ) +
    geom_line_webgl(
      data = paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = mode),
      linewidth = 0.95,
      alpha = 0.46,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = starts,
      mapping = ggplot2::aes(x, y, colour = mode),
      size = 1.30,
      alpha = 0.26,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = endpoints,
      mapping = ggplot2::aes(x, y, colour = mode),
      size = 2.10,
      alpha = 0.98,
      inherit.aes = FALSE
    ) +
    ggplot2::scale_colour_manual(values = palette) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = showcase_metadata()$diffusion_paths$title,
      subtitle = showcase_metadata()$diffusion_paths$subtitle,
      x = "State dimension 1",
      y = "State dimension 2"
    ) +
    showcase_theme("trajectory_age")
}

showcase_phase_portrait_plot <- function(seed = 2028L,
                                         n_paths = NULL,
                                         steps = NULL,
                                         dt = NULL,
                                         detail = c("standard", "high_detail")) {
  detail <- match_showcase_detail(detail)
  spec <- showcase_detail_spec(detail)$phase_portrait
  n_paths <- as.integer(value_or(n_paths, spec$n_paths))
  steps <- as.integer(value_or(steps, spec$steps))
  dt <- as.numeric(value_or(dt, spec$dt))
  set.seed(seed)

  mu <- 1.35
  theta <- seq(0, 2 * pi, length.out = n_paths + 1L)[-1L]
  radius <- if (identical(detail, "standard")) {
    seq(0.8, 3.0, length.out = n_paths)
  } else {
    seq(0.6, 3.6, length.out = n_paths)
  }
  initial_x <- radius * cos(theta) + stats::rnorm(n_paths, sd = if (identical(detail, "standard")) 0.08 else 0.12)
  initial_y <- radius * sin(theta) + stats::rnorm(n_paths, sd = if (identical(detail, "standard")) 0.08 else 0.12)

  palette <- if (identical(detail, "standard")) {
    grDevices::hcl.colors(n_paths, palette = "Temps")
  } else {
    grDevices::hcl(
      h = seq(15, 375, length.out = n_paths + 1L)[-1L],
      c = 88,
      l = 60
    )
  }
  path_list <- vector("list", n_paths)
  end_list <- vector("list", n_paths)

  for (i in seq_len(n_paths)) {
    x <- initial_x[i]
    y <- initial_y[i]
    trace <- matrix(NA_real_, nrow = steps, ncol = 2L)

    for (step in seq_len(steps)) {
      dx <- y
      dy <- mu * (1 - x^2) * y - x
      x <- x + dt * dx
      y <- y + dt * dy
      trace[step, ] <- c(x, y)
    }

    colour_hex <- palette[i]
    path_list[[i]] <- data.frame(
      x = trace[, 1],
      y = trace[, 2],
      step = seq_len(steps),
      path_id = paste0("orbit_", i),
      colour_hex = colour_hex
    )
    end_list[[i]] <- data.frame(
      x = trace[steps, 1],
      y = trace[steps, 2],
      colour_hex = colour_hex
    )
  }

  paths <- do.call(rbind, path_list)
  endpoints <- do.call(rbind, end_list)

  if (identical(detail, "standard")) {
    return(
      ggplot2::ggplot(paths, ggplot2::aes(x, y, group = path_id, colour = colour_hex)) +
        geom_line_webgl(linewidth = 0.8, alpha = 0.55) +
        geom_point_webgl(
          data = endpoints,
          mapping = ggplot2::aes(x, y, colour = colour_hex),
          size = 1.8,
          alpha = 0.92,
          inherit.aes = FALSE
        ) +
        ggplot2::scale_colour_identity() +
        ggplot2::coord_equal() +
        ggplot2::labs(
          title = showcase_metadata()$phase_portrait$title,
          subtitle = showcase_metadata()$phase_portrait$subtitle,
          x = "Position",
          y = "Velocity"
        ) +
        showcase_theme("trajectory_age")
    )
  }

  seeds <- data.frame(x = initial_x, y = initial_y, colour_hex = palette)
  trail_points <- paths[paths$step %% 5L == 0L, c("x", "y", "colour_hex")]
  attractor_points <- paths[
    paths$step >= max(1L, steps - 120L) & (paths$step %% 2L == 0L),
    c("x", "y", "colour_hex")
  ]

  ggplot2::ggplot() +
    geom_line_webgl(
      data = paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = colour_hex),
      linewidth = 2.15,
      alpha = 0.14,
      inherit.aes = FALSE
    ) +
    geom_line_webgl(
      data = paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = colour_hex),
      linewidth = 1.05,
      alpha = 0.62,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = trail_points,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 0.75,
      alpha = 0.16,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = attractor_points,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 0.95,
      alpha = 0.24,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = seeds,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 1.45,
      alpha = 0.30,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = endpoints,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 1.90,
      alpha = 0.96,
      inherit.aes = FALSE
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = showcase_metadata()$phase_portrait$title,
      subtitle = showcase_metadata()$phase_portrait$subtitle,
      x = "Position",
      y = "Velocity"
    ) +
    showcase_theme("trajectory_age")
}

loss_surface_value <- function(x, y) {
  0.08 * (x^4 + y^4) - 0.60 * (x^2 + y^2) + 0.40 * x * y +
    0.50 * sin(1.7 * x) * cos(1.3 * y)
}

loss_surface_gradient <- function(x, y) {
  c(
    0.32 * x^3 - 1.20 * x + 0.40 * y + 0.85 * cos(1.7 * x) * cos(1.3 * y),
    0.32 * y^3 - 1.20 * y + 0.40 * x - 0.65 * sin(1.7 * x) * sin(1.3 * y)
  )
}

showcase_loss_landscape_plot <- function(seed = 2029L,
                                         steps = NULL,
                                         detail = c("standard", "high_detail")) {
  detail <- match_showcase_detail(detail)
  spec <- showcase_detail_spec(detail)$loss_landscape
  steps <- as.integer(value_or(steps, spec$steps))
  set.seed(seed)

  x_axis <- seq(-3.2, 3.2, length.out = spec$grid_n)
  y_axis <- seq(-3.2, 3.2, length.out = spec$grid_n)
  grid <- expand.grid(
    x = x_axis,
    y = y_axis
  )
  grid$z <- with(grid, loss_surface_value(x, y))
  palette <- if (identical(detail, "standard")) {
    grDevices::hcl.colors(256L, "Inferno")
  } else {
    grDevices::colorRampPalette(
      c("#08111f", "#0f3557", "#0f766e", "#d97706", "#fde68a")
    )(256L)
  }
  scaled <- (grid$z - min(grid$z)) / (max(grid$z) - min(grid$z))
  grid$colour_hex <- palette[pmax(1L, pmin(256L, floor(scaled * 255) + 1L))]
  grid_render <- grid

  if (identical(detail, "high_detail")) {
    jitter_sd <- diff(range(x_axis)) / spec$grid_n * 0.12
    grid_render$x <- grid_render$x + stats::rnorm(nrow(grid_render), sd = jitter_sd)
    grid_render$y <- grid_render$y + stats::rnorm(nrow(grid_render), sd = jitter_sd)
  }

  methods <- spec$methods
  path_list <- vector("list", nrow(methods))
  end_list <- vector("list", nrow(methods))
  start_list <- vector("list", nrow(methods))

  for (i in seq_len(nrow(methods))) {
    current <- c(methods$start_x[i], methods$start_y[i])
    origin <- current
    velocity <- c(0, 0)
    trace <- matrix(NA_real_, nrow = steps, ncol = 2L)

    for (step in seq_len(steps)) {
      grad <- loss_surface_gradient(current[1], current[2])
      velocity <- methods$momentum[i] * velocity - methods$lr[i] * grad
      current <- current + velocity + stats::rnorm(2L, sd = if (identical(detail, "standard")) 0.012 else 0.010)
      trace[step, ] <- current
    }

    path_list[[i]] <- data.frame(
      x = trace[, 1],
      y = trace[, 2],
      step = seq_len(steps),
      method = methods$method[i],
      path_id = methods$method[i],
      colour_hex = methods$colour_hex[i]
    )
    start_list[[i]] <- data.frame(
      x = origin[1],
      y = origin[2],
      colour_hex = methods$colour_hex[i]
    )
    end_list[[i]] <- data.frame(
      x = trace[steps, 1],
      y = trace[steps, 2],
      colour_hex = methods$colour_hex[i]
    )
  }

  paths <- do.call(rbind, path_list)
  starts <- do.call(rbind, start_list)
  endpoints <- do.call(rbind, end_list)

  if (identical(detail, "standard")) {
    return(
      ggplot2::ggplot() +
        geom_point_webgl(
          data = grid_render,
          mapping = ggplot2::aes(x, y, colour = colour_hex),
          size = 0.85,
          alpha = 0.42,
          inherit.aes = FALSE
        ) +
        geom_line_webgl(
          data = paths,
          mapping = ggplot2::aes(x, y, group = path_id, colour = colour_hex),
          linewidth = 1.2,
          alpha = 0.95,
          inherit.aes = FALSE
        ) +
        geom_point_webgl(
          data = endpoints,
          mapping = ggplot2::aes(x, y, colour = colour_hex),
          size = 2.4,
          alpha = 1,
          inherit.aes = FALSE
        ) +
        ggplot2::scale_colour_identity() +
        ggplot2::coord_equal() +
        ggplot2::labs(
          title = showcase_metadata()$loss_landscape$title,
          subtitle = showcase_metadata()$loss_landscape$subtitle,
          x = "Parameter axis 1",
          y = "Parameter axis 2"
        ) +
        showcase_theme("density_splat")
    )
  }

  ridge_idx <- grid$z <= stats::quantile(grid$z, 0.18) | grid$z >= stats::quantile(grid$z, 0.88)
  ridge_points <- grid_render[ridge_idx, , drop = FALSE]
  trail_points <- paths[paths$step %% 2L == 0L, c("x", "y", "colour_hex")]
  focus_points <- paths[paths$step >= max(1L, steps - 20L), c("x", "y", "colour_hex")]
  contour_levels <- unique(as.numeric(stats::quantile(
    grid$z,
    probs = seq(0.14, 0.88, length.out = 9L),
    names = FALSE
  )))
  contour_palette <- grDevices::colorRampPalette(
    c("#0f3557", "#0f766e", "#f59e0b", "#fde68a")
  )(max(2L, length(contour_levels)))
  contour_segments <- grDevices::contourLines(
    x = x_axis,
    y = y_axis,
    z = matrix(grid$z, nrow = length(x_axis), ncol = length(y_axis)),
    levels = contour_levels
  )
  contour_paths <- do.call(
    rbind,
    lapply(seq_along(contour_segments), function(i) {
      segment <- contour_segments[[i]]
      level_id <- which.min(abs(contour_levels - segment$level))
      data.frame(
        x = segment$x,
        y = segment$y,
        path_id = paste0("contour_", i),
        colour_hex = contour_palette[[level_id]]
      )
    })
  )

  ggplot2::ggplot() +
    geom_point_webgl(
      data = grid_render,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 0.80,
      alpha = 0.28,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = ridge_points,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 1.10,
      alpha = 0.60,
      inherit.aes = FALSE
    ) +
    geom_line_webgl(
      data = contour_paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = colour_hex),
      linewidth = 1.00,
      alpha = 0.30,
      inherit.aes = FALSE
    ) +
    geom_line_webgl(
      data = paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = colour_hex),
      linewidth = 2.35,
      alpha = 0.18,
      inherit.aes = FALSE
    ) +
    geom_line_webgl(
      data = paths,
      mapping = ggplot2::aes(x, y, group = path_id, colour = colour_hex),
      linewidth = 1.30,
      alpha = 0.98,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = trail_points,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 1.05,
      alpha = 0.22,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = focus_points,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 1.45,
      alpha = 0.34,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = starts,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 1.80,
      alpha = 0.40,
      inherit.aes = FALSE
    ) +
    geom_point_webgl(
      data = endpoints,
      mapping = ggplot2::aes(x, y, colour = colour_hex),
      size = 2.85,
      alpha = 1,
      inherit.aes = FALSE
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = showcase_metadata()$loss_landscape$title,
      subtitle = showcase_metadata()$loss_landscape$subtitle,
      x = "Parameter axis 1",
      y = "Parameter axis 2"
    ) +
    showcase_theme("density_splat")
}

showcase_plots <- function(seed = 2026L, detail = c("standard", "high_detail")) {
  detail <- match_showcase_detail(detail)

  list(
    latent_cloud = showcase_latent_cloud_plot(seed = seed, detail = detail),
    diffusion_paths = showcase_diffusion_paths_plot(seed = seed + 1L, detail = detail),
    phase_portrait = showcase_phase_portrait_plot(seed = seed + 2L, detail = detail),
    loss_landscape = showcase_loss_landscape_plot(seed = seed + 3L, detail = detail)
  )
}
