library(htmlwidgets)

compact_list <- function(x) {
  Filter(Negate(is.null), x)
}

load_renderer_and_xgeortr_packages <- function() {
  if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
  } else if (requireNamespace("ggWebGL", quietly = TRUE)) {
    library(ggWebGL)
  } else {
    stop("ggWebGL is not available. Install the package or run from the repo with pkgload.")
  }

  if (requireNamespace("XGeoRTR", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  FALSE
}

xgeortr_bridge_available <- function() {
  identical(load_renderer_and_xgeortr_packages(), TRUE)
}

require_xgeortr_bridge <- function() {
  if (!xgeortr_bridge_available()) {
    stop(
      "XGeoRTR is unavailable. Install it to run the XGeoRTR bridge examples.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

bridge_class_palette <- c(
  "Low response" = "#255C99",
  "Transition" = "#2E9F6E",
  "High response" = "#D17A22"
)

bridge_group_palette <- c(
  "Position" = "#255C99",
  "Wave response" = "#2E9F6E",
  "Stability" = "#D17A22",
  "Interaction" = "#A23E48"
)

bridge_path_palette <- c(
  lower = "#1F4E79",
  middle = "#263238",
  upper = "#8A4B12"
)

build_xgeortr_bridge_state <- function(seed, n = 840L, balanced_groups = FALSE) {
  require_xgeortr_bridge()

  set.seed(seed)
  class_seed <- sample.int(3L, n, replace = TRUE, prob = c(0.33, 0.34, 0.33))
  centers <- matrix(
    c(-2.35, -0.80,
       2.15, -0.55,
       0.00,  2.15),
    ncol = 2,
    byrow = TRUE
  )
  latent <- centers[class_seed, , drop = FALSE] +
    matrix(stats::rnorm(n * 2L, sd = 0.72), ncol = 2)

  features <- cbind(
    f_position_x = latent[, 1],
    f_position_y = latent[, 2],
    f_wave = sin(1.35 * latent[, 1]) + 0.16 * stats::rnorm(n),
    f_stability = cos(0.85 * latent[, 2]) + 0.18 * stats::rnorm(n),
    f_interaction = 0.42 * latent[, 1] * latent[, 2] + 0.20 * stats::rnorm(n)
  )

  weights <- matrix(
    c(
      0.95, -0.50, 0.70, -0.24, 0.24,
     -0.28,  1.02, -0.24, 0.72, -0.16,
     -0.62, -0.50, 0.34, -0.40, 0.92
    ),
    nrow = 3L,
    byrow = TRUE
  )
  colnames(weights) <- colnames(features)

  logits <- features %*% t(weights) + matrix(stats::rnorm(n * 3L, sd = 0.17), ncol = 3L)
  prob <- exp(logits - apply(logits, 1L, max))
  prob <- prob / rowSums(prob)
  pred_id <- max.col(prob)
  prediction <- factor(names(bridge_class_palette)[pred_id], levels = names(bridge_class_palette))
  confidence <- apply(prob, 1L, max)

  shap_values <- features * weights[pred_id, , drop = FALSE]
  colnames(shap_values) <- colnames(features)
  feature_group <- c(
    f_position_x = "Position",
    f_position_y = "Position",
    f_wave = "Wave response",
    f_stability = "Stability",
    f_interaction = "Interaction"
  )

  if (balanced_groups) {
    assigned_group <- ifelse(
      latent[, 1] < -1.15,
      "Position",
      ifelse(
        latent[, 2] > 1.0,
        "Stability",
        ifelse(abs(latent[, 1] * latent[, 2]) > 1.05, "Interaction", "Wave response")
      )
    )
    for (i in seq_len(n)) {
      dominant_features <- names(feature_group)[feature_group == assigned_group[i]]
      other_features <- setdiff(colnames(shap_values), dominant_features)
      shap_values[i, dominant_features] <- shap_values[i, dominant_features] * 6.0
      shap_values[i, other_features] <- shap_values[i, other_features] * 0.06
    }
    shap_values <- shap_values + matrix(stats::rnorm(length(shap_values), sd = 0.01), nrow = n)
  }

  point_id <- sprintf("pt_%04d", seq_len(n))
  explanation_long <- data.frame(
    point_id = rep(point_id, each = ncol(shap_values)),
    feature = rep(colnames(shap_values), times = n),
    value = as.vector(t(shap_values)),
    x = rep(features[, "f_position_x"], each = ncol(shap_values)),
    y = rep(features[, "f_position_y"], each = ncol(shap_values)),
    z = rep(0, n * ncol(shap_values)),
    prediction = rep(as.character(prediction), each = ncol(shap_values)),
    confidence = rep(confidence, each = ncol(shap_values)),
    stringsAsFactors = FALSE
  )

  state <- XGeoRTR::as_xgeo_state(
    explanation_long,
    x_col = "x",
    y_col = "y",
    z_col = "z",
    value_col = "value",
    feature_col = "feature",
    point_id_col = "point_id",
    method = "ggwebgl-xgeortr-bridge",
    meta = list(
      title = "XGeoRTR bridge state",
      source = "ggWebGL downstream bridge example"
    )
  )

  if (requireNamespace("uwot", quietly = TRUE)) {
    set.seed(seed)
    state <- XGeoRTR::compute_xgeo_embedding(
      state,
      method = "umap",
      source = "explanations",
      dims = 2,
      n_neighbors = 20,
      n_epochs = 190,
      init = "random",
      n_threads = 1,
      verbose = FALSE
    )
    embedding_name <- "umap_explanations"
  } else {
    state <- XGeoRTR::compute_xgeo_embedding(
      state,
      method = "pca",
      source = "explanations",
      dims = 2
    )
    embedding_name <- "pca_explanations"
  }

  attrs <- XGeoRTR::xgeo_attributes(state)
  coords <- as.data.frame(attrs$embeddings$items[[embedding_name]]$coords, stringsAsFactors = FALSE)
  coord_names <- setdiff(names(coords), "point_id")

  point_meta <- unique(explanation_long[c("point_id", "prediction", "confidence")])
  plot_data <- merge(
    data.frame(
      point_id = as.character(coords$point_id),
      dim1 = as.numeric(coords[[coord_names[[1L]]]]),
      dim2 = as.numeric(coords[[coord_names[[2L]]]]),
      stringsAsFactors = FALSE
    ),
    point_meta,
    by = "point_id",
    sort = FALSE
  )
  plot_data$prediction <- factor(plot_data$prediction, levels = names(bridge_class_palette))

  shap_df <- as.data.frame(shap_values, stringsAsFactors = FALSE)
  shap_df$point_id <- point_id
  plot_data <- merge(plot_data, shap_df, by = "point_id", sort = FALSE)

  plot_data$vx_raw <- 0.72 * plot_data$f_position_x - 0.30 * plot_data$f_position_y + 0.55 * plot_data$f_interaction
  plot_data$vy_raw <- 0.62 * plot_data$f_position_y + 0.42 * plot_data$f_wave - 0.25 * plot_data$f_stability
  mag <- sqrt(plot_data$vx_raw^2 + plot_data$vy_raw^2)
  mag[mag == 0] <- 1
  plot_data$vx <- plot_data$vx_raw / mag
  plot_data$vy <- plot_data$vy_raw / mag

  group_names <- names(bridge_group_palette)
  raw_group_scores <- sapply(group_names, function(g) {
    rowMeans(abs(shap_values[, feature_group == g, drop = FALSE]))
  })
  scale_ref <- apply(raw_group_scores, 2, function(x) stats::quantile(x, 0.72) + 1e-8)
  group_scores <- sweep(raw_group_scores, 2, scale_ref, "/")
  plot_data$dominant_group <- factor(group_names[max.col(group_scores)], levels = group_names)
  plot_data$importance <- apply(raw_group_scores, 1L, max)
  importance_scaled <- (plot_data$importance - min(plot_data$importance)) /
    (max(plot_data$importance) - min(plot_data$importance))
  plot_data$importance_scaled <- importance_scaled
  plot_data$point_size <- 2.3 + 4.4 * sqrt(importance_scaled)
  plot_data$point_alpha <- 0.35 + 0.45 * sqrt(importance_scaled)
  plot_data$decision_score <- prob[, 3L] - prob[, 1L]

  list(
    state = state,
    plot_data = plot_data,
    shap_values = shap_values,
    feature_group = feature_group,
    embedding_name = embedding_name
  )
}

bridge_limits <- function(dat) {
  xlim <- range(dat$dim1)
  ylim <- range(dat$dim2)
  list(
    x = xlim + c(-1, 1) * diff(xlim) * 0.08,
    y = ylim + c(-1, 1) * diff(ylim) * 0.08
  )
}

bridge_make_arrows <- function(dat, k, scale = 0.07) {
  dat <- dat[is.finite(dat$dim1) & is.finite(dat$dim2), , drop = FALSE]
  k <- min(k, max(1L, nrow(dat)))
  set.seed(20260422 + k)
  km <- stats::kmeans(dat[c("dim1", "dim2")], centers = k, iter.max = 50)
  split_idx <- split(seq_len(nrow(dat)), km$cluster)
  out <- do.call(rbind, lapply(split_idx, function(idx) {
    data.frame(
      x = mean(dat$dim1[idx]),
      y = mean(dat$dim2[idx]),
      vx = mean(dat$vx[idx]),
      vy = mean(dat$vy[idx]),
      stringsAsFactors = FALSE
    )
  }))
  vmag <- sqrt(out$vx^2 + out$vy^2)
  vmag[vmag == 0] <- 1
  span <- max(diff(range(dat$dim1)), diff(range(dat$dim2)))
  out$xend <- out$x + (out$vx / vmag) * span * scale
  out$yend <- out$y + (out$vy / vmag) * span * scale
  out$id <- sprintf("bridge_vector_%03d", seq_len(nrow(out)))
  out$strength <- vmag / max(vmag)
  out
}

bridge_arrow_layers <- function(arrows, panel_id, line_width = 2.4) {
  list(
    ggwebgl_layer_vectors(
      arrows,
      x = "x",
      y = "y",
      xend = "xend",
      yend = "yend",
      colour = "#202225",
      alpha = 0.86,
      width = line_width,
      head_size = 10,
      id = "id",
      panel_id = panel_id,
      geom = "xgeortr_bridge_vector_arrows"
    ),
    ggwebgl_layer_points(
      arrows,
      x = "x",
      y = "y",
      colour = "#ffffff",
      alpha = 0.96,
      size = 7.5,
      panel_id = panel_id,
      geom = "xgeortr_bridge_vector_anchor_back"
    ),
    ggwebgl_layer_points(
      arrows,
      x = "x",
      y = "y",
      colour = "#202225",
      alpha = 0.96,
      size = 3.2,
      panel_id = panel_id,
      geom = "xgeortr_bridge_vector_anchor_front"
    )
  )
}

bridge_zoom_region <- function(center, radius) {
  list(
    x = c(center$dim1 - radius, center$dim1 + radius),
    y = c(center$dim2 - radius, center$dim2 + radius)
  )
}

bridge_zoom_box_layer <- function(region, panel_id) {
  box <- data.frame(
    x = c(region$x[[1L]], region$x[[2L]], region$x[[2L]], region$x[[1L]], region$x[[1L]]),
    y = c(region$y[[1L]], region$y[[1L]], region$y[[2L]], region$y[[2L]], region$y[[1L]]),
    group = "zoom_box",
    stringsAsFactors = FALSE
  )
  ggwebgl_layer_lines(
    box,
    x = "x",
    y = "y",
    group = "group",
    colour = "#111827",
    alpha = 0.64,
    width = 1.8,
    panel_id = panel_id,
    geom = "xgeortr_bridge_zoom_box"
  )
}

bridge_density_raster_layer <- function(dat, panel_id) {
  if (!requireNamespace("MASS", quietly = TRUE)) {
    return(NULL)
  }

  lims <- bridge_limits(dat)
  dens <- MASS::kde2d(dat$dim1, dat$dim2, n = 72L, lims = c(lims$x, lims$y))
  z <- as.numeric(dens$z)
  if (!length(z) || diff(range(z)) == 0) {
    z[] <- 0.5
  } else {
    z <- (z - min(z)) / (max(z) - min(z))
  }
  alpha <- as.integer(30 + 110 * z)
  rgb <- grDevices::colorRamp(c("#ffffff", "#d9dde1", "#7c858f"))(z)
  rgba <- as.integer(t(cbind(rgb, alpha = alpha)))

  ggwebgl_layer_raster(
    rgba = rgba,
    width = length(dens$x),
    height = length(dens$y),
    xmin = min(dens$x),
    xmax = max(dens$x),
    ymin = min(dens$y),
    ymax = max(dens$y),
    interpolate = TRUE,
    panel_id = panel_id,
    geom = "xgeortr_bridge_density_backdrop"
  )
}

bridge_transition_centers <- function(dat) {
  dat$path_band <- cut(
    dat$dim2,
    breaks = stats::quantile(dat$dim2, probs = c(0.08, 0.38, 0.62, 0.92)),
    include.lowest = TRUE,
    labels = c("lower", "middle", "upper")
  )
  path_levels <- levels(dat$path_band)

  lapply(path_levels, function(level_name) {
    d <- dat[dat$path_band == level_name, , drop = FALSE]
    if (nrow(d) < 60L) {
      return(NULL)
    }
    br <- unique(stats::quantile(d$decision_score, probs = seq(0.08, 0.92, length.out = 7), na.rm = TRUE))
    if (length(br) < 4L) {
      return(NULL)
    }
    d$score_bin <- cut(d$decision_score, breaks = br, include.lowest = TRUE)
    centers <- stats::aggregate(cbind(dim1, dim2, decision_score) ~ score_bin, data = d, FUN = stats::median)
    centers[order(centers$decision_score), , drop = FALSE]
  }) -> centers
  names(centers) <- path_levels
  centers
}

bridge_path_layers <- function(dat, panel_id) {
  centers <- bridge_transition_centers(dat)
  layers <- list()
  path_index <- 1L

  for (nm in names(centers)) {
    center_tbl <- centers[[nm]]
    if (is.null(center_tbl) || nrow(center_tbl) < 3L) {
      next
    }

    spline_tbl <- data.frame(
      x = stats::spline(seq_len(nrow(center_tbl)), center_tbl$dim1, n = 100L)$y,
      y = stats::spline(seq_len(nrow(center_tbl)), center_tbl$dim2, n = 100L)$y,
      stringsAsFactors = FALSE
    )
    spline_tbl$path <- paste0(nm, "_", path_index)
    spline_tbl$age <- seq(0, 1, length.out = nrow(spline_tbl))

    layers[[length(layers) + 1L]] <- ggwebgl_layer_lines(
      spline_tbl,
      x = "x",
      y = "y",
      group = "path",
      colour = bridge_path_palette[[nm]],
      alpha = 0.90,
      width = 3.8,
      age = "age",
      panel_id = panel_id,
      geom = "xgeortr_bridge_transition_paths"
    )
    layers[[length(layers) + 1L]] <- ggwebgl_layer_points(
      center_tbl,
      x = "dim1",
      y = "dim2",
      colour = "#ffffff",
      alpha = 0.96,
      size = 7.0,
      panel_id = panel_id,
      geom = "xgeortr_bridge_transition_anchor_back"
    )
    layers[[length(layers) + 1L]] <- ggwebgl_layer_points(
      center_tbl,
      x = "dim1",
      y = "dim2",
      colour = bridge_path_palette[[nm]],
      alpha = 0.98,
      size = 3.2,
      panel_id = panel_id,
      geom = "xgeortr_bridge_transition_anchor_front"
    )
    path_index <- path_index + 1L
  }

  layers
}

representative_bridge_spec <- function(dat) {
  arrows <- bridge_make_arrows(dat, k = 15L, scale = 0.065)
  layers <- c(
    list(
      ggwebgl_layer_points(
        dat,
        x = "dim1",
        y = "dim2",
        colour = unname(bridge_class_palette[dat$prediction]),
        alpha = 0.72,
        size = 3.5,
        label = "point_id",
        panel_id = 1L,
        geom = "xgeortr_bridge_points"
      )
    ),
    bridge_arrow_layers(arrows, panel_id = 1L)
  )

  ggwebgl_spec(
    layers = layers,
    labels = list(
      title = "XGeoRTR bridge: representative explanation state",
      subtitle = "Prediction-coloured points with sparse contribution directions",
      x = "embedding dim1",
      y = "embedding dim2"
    ),
    webgl = list(shader = "default", interactions = c("pan", "zoom", "hover"), transparent = FALSE)
  )
}

multiscale_bridge_spec <- function(dat) {
  full_limits <- bridge_limits(dat)
  global_arrows <- bridge_make_arrows(dat, k = 15L, scale = 0.065)

  center_candidates <- order(abs(dat$confidence - stats::quantile(dat$confidence, 0.33)))
  center <- dat[center_candidates[1L], c("dim1", "dim2")]
  full_span <- max(diff(range(dat$dim1)), diff(range(dat$dim2)))
  radius <- full_span * 0.17
  repeat {
    zoom_region <- bridge_zoom_region(center, radius)
    local_idx <- dat$dim1 >= zoom_region$x[[1L]] &
      dat$dim1 <= zoom_region$x[[2L]] &
      dat$dim2 >= zoom_region$y[[1L]] &
      dat$dim2 <= zoom_region$y[[2L]]
    if (sum(local_idx) >= 120L || radius > full_span * 0.34) {
      break
    }
    radius <- radius * 1.18
  }

  zoom_region <- bridge_zoom_region(center, radius)
  local_data <- dat[local_idx, , drop = FALSE]
  local_arrows <- bridge_make_arrows(local_data, k = 22L, scale = 0.055)

  panels <- list(
    list(
      panel_id = "global",
      row = 1L,
      col = 1L,
      label = "Global embedding",
      viewport = list(x = full_limits$x, y = full_limits$y)
    ),
    list(
      panel_id = "local",
      row = 1L,
      col = 2L,
      label = "Local explanation region",
      viewport = zoom_region
    )
  )

  layers <- c(
    list(
      ggwebgl_layer_points(
        dat,
        x = "dim1",
        y = "dim2",
        colour = unname(bridge_class_palette[dat$prediction]),
        alpha = 0.60,
        size = 3.0,
        label = "point_id",
        panel_id = "global",
        geom = "xgeortr_bridge_multiscale_global_points"
      ),
      bridge_zoom_box_layer(zoom_region, panel_id = "global"),
      ggwebgl_layer_points(
        local_data,
        x = "dim1",
        y = "dim2",
        colour = unname(bridge_class_palette[local_data$prediction]),
        alpha = 0.82,
        size = 4.0,
        label = "point_id",
        panel_id = "local",
        geom = "xgeortr_bridge_multiscale_local_points"
      )
    ),
    bridge_arrow_layers(global_arrows, panel_id = "global"),
    bridge_arrow_layers(local_arrows, panel_id = "local")
  )

  ggwebgl_spec(
    layers = layers,
    labels = list(
      title = "XGeoRTR bridge: global vs local explanation structure",
      subtitle = "Two-panel ggWebGL composition using one embedding and shared semantics",
      x = "embedding dim1",
      y = "embedding dim2"
    ),
    grid = list(rows = 1L, cols = 2L),
    panels = panels,
    webgl = list(shader = "default", interactions = c("pan", "zoom", "hover"), transparent = FALSE)
  )
}

attribution_bridge_spec <- function(dat) {
  raster_layer <- bridge_density_raster_layer(dat, panel_id = 1L)
  point_rgba <- grDevices::col2rgb(unname(bridge_group_palette[dat$dominant_group]), alpha = TRUE)
  point_rgba[4, ] <- round(255 * dat$point_alpha)

  layers <- compact_list(list(
    raster_layer,
    ggwebgl_layer_points(
      dat,
      x = "dim1",
      y = "dim2",
      rgba = as.numeric(point_rgba),
      size = "point_size",
      label = "point_id",
      panel_id = 1L,
      geom = "xgeortr_bridge_attribution_points"
    )
  ))

  ggwebgl_spec(
    layers = layers,
    labels = list(
      title = "XGeoRTR bridge: feature attribution in explanation space",
      subtitle = "Colour = dominant attribution group, size/alpha = importance magnitude",
      x = "embedding dim1",
      y = "embedding dim2"
    ),
    webgl = list(shader = "default", interactions = c("pan", "zoom", "hover"), transparent = FALSE)
  )
}

structure_bridge_spec <- function(dat) {
  layers <- c(
    list(
      ggwebgl_layer_points(
        dat,
        x = "dim1",
        y = "dim2",
        colour = unname(bridge_class_palette[dat$prediction]),
        alpha = 0.34,
        size = 3.0,
        label = "point_id",
        panel_id = 1L,
        geom = "xgeortr_bridge_structure_points"
      )
    ),
    bridge_path_layers(dat, panel_id = 1L)
  )

  ggwebgl_spec(
    layers = layers,
    labels = list(
      title = "XGeoRTR bridge: geometric structure of explanation transitions",
      subtitle = "Three transition summaries rendered as line bundles over the embedding",
      x = "embedding dim1",
      y = "embedding dim2"
    ),
    webgl = list(shader = "default", interactions = c("pan", "zoom", "hover"), transparent = FALSE)
  )
}

ggwebgl_xgeortr_bridge_specs <- function() {
  if (!xgeortr_bridge_available()) {
    return(NULL)
  }

  representative_demo <- build_xgeortr_bridge_state(seed = 20260421, n = 840L, balanced_groups = FALSE)
  attribution_demo <- build_xgeortr_bridge_state(seed = 20260424, n = 900L, balanced_groups = TRUE)

  list(
    representative = representative_bridge_spec(representative_demo$plot_data),
    multiscale = multiscale_bridge_spec(representative_demo$plot_data),
    attribution = attribution_bridge_spec(attribution_demo$plot_data),
    structure = structure_bridge_spec(representative_demo$plot_data)
  )
}

ggwebgl_xgeortr_bridge_widgets <- function(height = 620) {
  specs <- ggwebgl_xgeortr_bridge_specs()
  if (is.null(specs)) {
    return(NULL)
  }

  lapply(specs, function(spec) {
    ggWebGL(spec, width = "100%", height = height)
  })
}

export_xgeortr_bridge_gallery <- function(output_dir = tempfile("ggwebgl-xgeortr-bridge-"),
                                          selfcontained = FALSE) {
  widgets <- ggwebgl_xgeortr_bridge_widgets()
  if (is.null(widgets)) {
    message("XGeoRTR is unavailable; skipping XGeoRTR bridge renderer gallery.")
    return(NULL)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  files <- character(length(widgets))
  names(files) <- names(widgets)

  for (name in names(widgets)) {
    file <- file.path(output_dir, paste0(name, ".html"))
    htmlwidgets::saveWidget(widgets[[name]], file = file, selfcontained = selfcontained)
    files[[name]] <- file
  }

  index <- file.path(output_dir, "index.html")
  links <- sprintf("<li><a href=\"%s\">%s</a></li>", basename(files), names(files))
  writeLines(
    c(
      "<!doctype html>",
      "<html>",
      "<head><meta charset=\"utf-8\"><title>ggWebGL XGeoRTR bridge demos</title></head>",
      "<body>",
      "<h1>ggWebGL XGeoRTR bridge demos</h1>",
      "<p>Optional downstream examples rendered from XGeoRTR backend state through ggWebGL.</p>",
      "<ul>",
      links,
      "</ul>",
      "</body>",
      "</html>"
    ),
    con = index,
    useBytes = TRUE
  )

  attr(files, "index") <- index
  invisible(files)
}

if (sys.nframe() == 0L) {
  widgets <- ggwebgl_xgeortr_bridge_widgets()
  if (is.null(widgets)) {
    cat("XGeoRTR is unavailable; skipping XGeoRTR bridge renderer demo.\n")
  } else {
    print(widgets$representative)
    print(widgets$multiscale)
    print(widgets$attribution)
    print(widgets$structure)
  }
}
