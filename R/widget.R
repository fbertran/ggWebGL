build_layer_metadata <- function(plot, built_layers) {
  Map(
    f = function(layer, data) {
      compact_list(list(
        geom = class(layer$geom)[1],
        stat = class(layer$stat)[1],
        supported = is_supported_geom(layer),
        mapping = names(layer$mapping),
        rows = if (is.null(data)) 0L else nrow(data),
        data_preview = preview_layer_data(data)
      ))
    },
    layer = plot$layers,
    data = built_layers
  )
}

panel_layout_dataframe <- function(built_plot) {
  layout <- built_plot$layout$layout

  if (is.null(layout) || !nrow(layout)) {
    return(
      data.frame(
        PANEL = 1L,
        ROW = 1L,
        COL = 1L,
        SCALE_X = 1L,
        SCALE_Y = 1L,
        COORD = 1L
      )
    )
  }

  as.data.frame(layout)
}

panel_grid_dimensions <- function(layout) {
  list(
    rows = max(1L, as.integer(max(layout$ROW %||% 1L))),
    cols = max(1L, as.integer(max(layout$COL %||% 1L)))
  )
}

panel_bounds <- function(row, col, grid) {
  list(
    left = (as.integer(col) - 1) / grid$cols,
    right = as.integer(col) / grid$cols,
    top = (as.integer(row) - 1) / grid$rows,
    bottom = as.integer(row) / grid$rows
  )
}

panel_label_from_layout <- function(layout_row) {
  facet_cols <- setdiff(names(layout_row), standard_layout_columns())

  if (!length(facet_cols)) {
    return(NULL)
  }

  parts <- vapply(
    facet_cols,
    function(column) {
      paste0(column, "=", as.character(layout_row[[column]][[1]]))
    },
    character(1)
  )

  paste(parts, collapse = ", ")
}

has_free_panel_scales <- function(layout) {
  length(unique(layout$SCALE_X %||% 1L)) > 1L || length(unique(layout$SCALE_Y %||% 1L)) > 1L
}

extract_panel_viewport <- function(built_plot, panel_id) {
  panel_params <- built_plot$layout$panel_params[[panel_id]]

  list(
    x = normalise_range(panel_params$x.range %||% c(0, 1)),
    y = normalise_range(panel_params$y.range %||% c(0, 1))
  )
}

extract_panel_contract <- function(built_plot) {
  layout <- panel_layout_dataframe(built_plot)
  grid <- panel_grid_dimensions(layout)

  list(
    grid = grid,
    has_free_scales = has_free_panel_scales(layout),
    panels = lapply(seq_len(nrow(layout)), function(i) {
      layout_row <- layout[i, , drop = FALSE]

      compact_list(list(
        panel_id = as.integer(layout_row$PANEL[[1]]),
        row = as.integer(layout_row$ROW[[1]] %||% 1L),
        col = as.integer(layout_row$COL[[1]] %||% 1L),
        label = panel_label_from_layout(layout_row),
        bounds = panel_bounds(layout_row$ROW[[1]] %||% 1L, layout_row$COL[[1]] %||% 1L, grid),
        viewport = extract_panel_viewport(built_plot, as.integer(layout_row$PANEL[[1]]))
      ))
    })
  )
}

empty_payload_map <- function() {
  stats::setNames(list(), character())
}

first_group_value <- function(data) {
  if (!"group" %in% names(data) || !nrow(data)) {
    return("")
  }

  value <- data$group[[1]]

  if (is.null(value) || !length(value) || is.na(value)) {
    return("")
  }

  as.character(value)
}

point_hover_labels <- function(data) {
  label_columns <- intersect(c("label", "text", "tooltip", "key", "sample_id", "point_id"), names(data))

  if (!length(label_columns) || !nrow(data)) {
    return(NULL)
  }

  labels <- as.character(data[[label_columns[[1L]]]])
  labels[is.na(labels)] <- ""
  labels
}

point_selection_ids <- function(data) {
  id_columns <- intersect(c("id", "key", "sample_id", "point_id"), names(data))

  if (!length(id_columns) || !nrow(data)) {
    return(NULL)
  }

  ids <- as.character(data[[id_columns[[1L]]]])
  ids[is.na(ids)] <- ""
  ids
}

extract_point_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  colour <- coalesce_colour(data)
  rgba <- colour_to_rgba(colour, data$alpha %||% NULL)
  size <- data$size %||% rep(2, nrow(data))
  size <- mm_to_pixels(size)
  size[!is.finite(size) | size <= 0] <- 4
  labels <- point_hover_labels(data)
  ids <- point_selection_ids(data)
  z <- if ("z" %in% names(data)) as.numeric(data$z) else NULL
  frame <- if ("frame" %in% names(data)) as.integer(data$frame) else NULL
  time <- if ("time" %in% names(data)) as.numeric(data$time) else NULL
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    idx <- split_index[[id]]

    compact_list(list(
      panel_id = as.integer(id),
      type = "points",
      geom = class(layer$geom)[1],
      rows = length(idx),
      x = unname(as.numeric(data$x[idx])),
      y = unname(as.numeric(data$y[idx])),
      z = if (length(z)) unname(z[idx]) else NULL,
      size = unname(as.numeric(size[idx])),
      age = rep(1, length(idx)),
      label = if (length(labels)) unname(labels[idx]) else NULL,
      id = if (length(ids)) unname(ids[idx]) else NULL,
      frame = if (length(frame)) unname(frame[idx]) else NULL,
      time = if (length(time)) unname(time[idx]) else NULL,
      rgba = unname(as.numeric(t(rgba[idx, , drop = FALSE])))
    ))
  })
  names(payloads) <- names(split_index)
  payloads
}

extract_line_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  subtype <- if (is_path3d_geom(layer)) "path3d" else NULL
  payloads <- lapply(names(split_index), function(id) {
    panel_data <- data[split_index[[id]], , drop = FALSE]
    path_runs <- if (is_ordered_path_geom(layer)) {
      split_ordered_group_path_runs(panel_data)
    } else {
      split_path_runs(panel_data)
    }

    if (!length(path_runs)) {
      return(NULL)
    }

    paths <- lapply(path_runs, function(idx) {
      path <- panel_data[idx, , drop = FALSE]
      colour <- coalesce_line_colour(path, layer)
      rgba <- colour_to_rgba(colour, path$alpha %||% NULL)
      linewidth <- path$linewidth %||% path$size %||% rep(1, nrow(path))
      linewidth <- mm_to_pixels(linewidth)
      linewidth <- linewidth[is.finite(linewidth) & linewidth > 0]
      z <- if ("z" %in% names(path)) as.numeric(path$z) else NULL
      frame <- if ("frame" %in% names(path)) as.integer(path$frame) else NULL
      time <- if ("time" %in% names(path)) as.numeric(path$time) else NULL
      level <- if ("level" %in% names(path)) path$level else NULL
      level <- if (length(level)) {
        if (is.factor(level)) as.character(level) else unname(level)
      } else {
        NULL
      }

      compact_list(list(
        rows = nrow(path),
        group = first_group_value(path),
        subtype = subtype,
        x = unname(as.numeric(path$x)),
        y = unname(as.numeric(path$y)),
        z = if (length(z)) unname(z) else NULL,
        width = if (length(linewidth)) as.numeric(linewidth[[1]]) else 1,
        age = if (nrow(path) <= 1L) rep(1, nrow(path)) else seq(0, 1, length.out = nrow(path)),
        frame = unname(frame),
        time = unname(time),
        level = level,
        rgba = unname(as.numeric(t(rgba)))
      ))
    })

    compact_list(list(
      panel_id = as.integer(id),
      type = "lines",
      geom = class(layer$geom)[1],
      subtype = subtype,
      rows = sum(vapply(paths, `[[`, integer(1), "rows")),
      path_count = length(paths),
      paths = paths
    ))
  })
  names(payloads) <- names(split_index)
  payloads <- Filter(Negate(is.null), payloads)
  payloads
}

extract_vector_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  colour <- coalesce_colour(data)
  rgba <- colour_to_rgba(colour, data$alpha %||% NULL)
  width <- data$linewidth %||% data$size %||% rep(1, nrow(data))
  width <- mm_to_pixels(width)
  width[!is.finite(width) | width <= 0] <- 1.5
  no_head_geoms <- c(
    "GeomSegmentWebGL",
    "GeomLinerangeWebGL",
    "GeomErrorbarWebGL",
    "GeomPointrangeWebGL",
    "GeomCrossbarWebGL",
    "GeomBoxplotWebGL"
  )
  default_head_size <- if (class(layer$geom)[1] %in% no_head_geoms) 0 else 9
  head_size <- layer$geom_params$head_size %||% rep(default_head_size, nrow(data))
  head_size <- rep(as.numeric(head_size)[[1]], nrow(data))
  ids <- point_selection_ids(data)
  z <- if ("z" %in% names(data)) as.numeric(data$z) else NULL
  zend <- if ("zend" %in% names(data)) as.numeric(data$zend) else NULL
  frame <- if ("frame" %in% names(data)) as.integer(data$frame) else NULL
  time <- if ("time" %in% names(data)) as.numeric(data$time) else NULL
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))

  payloads <- lapply(names(split_index), function(id) {
    idx <- split_index[[id]]

    compact_list(list(
      panel_id = as.integer(id),
      type = "vectors",
      geom = class(layer$geom)[1],
      rows = length(idx),
      x = unname(as.numeric(data$x[idx])),
      y = unname(as.numeric(data$y[idx])),
      z = if (length(z)) unname(z[idx]) else NULL,
      xend = unname(as.numeric(data$xend[idx])),
      yend = unname(as.numeric(data$yend[idx])),
      zend = if (length(zend)) unname(zend[idx]) else NULL,
      width = unname(as.numeric(width[idx])),
      head_size = unname(as.numeric(head_size[idx])),
      id = if (length(ids)) unname(ids[idx]) else NULL,
      frame = if (length(frame)) unname(frame[idx]) else NULL,
      time = if (length(time)) unname(time[idx]) else NULL,
      rgba = unname(as.numeric(t(rgba[idx, , drop = FALSE])))
    ))
  })
  names(payloads) <- names(split_index)
  payloads
}

range_segment_data <- function(data) {
  required <- c("x", "ymin", "ymax")
  if (!all(required %in% names(data))) {
    return(data.frame())
  }

  out <- data
  out$y <- data$ymin
  out$xend <- data$x
  out$yend <- data$ymax
  out
}

extract_linerange_payloads <- function(layer, data) {
  segment_data <- range_segment_data(as.data.frame(data))
  if (!nrow(segment_data)) {
    return(empty_payload_map())
  }

  extract_vector_payloads(layer, segment_data)
}

extract_errorbar_payloads <- function(layer, data) {
  data <- as.data.frame(data)
  segment_data <- range_segment_data(data)

  if (!nrow(segment_data)) {
    return(empty_payload_map())
  }

  if (all(c("xmin", "xmax") %in% names(data))) {
    lower_cap <- data
    lower_cap$x <- data$xmin
    lower_cap$y <- data$ymin
    lower_cap$xend <- data$xmax
    lower_cap$yend <- data$ymin

    upper_cap <- data
    upper_cap$x <- data$xmin
    upper_cap$y <- data$ymax
    upper_cap$xend <- data$xmax
    upper_cap$yend <- data$ymax

    segment_data <- rbind(segment_data, lower_cap, upper_cap)
  }

  extract_vector_payloads(layer, segment_data)
}

extract_pointrange_payloads <- function(layer, data) {
  data <- as.data.frame(data)
  point_payloads <- extract_point_payloads(layer, data)
  range_payloads <- extract_linerange_payloads(layer, data)
  panel_names <- union(names(point_payloads), names(range_payloads))

  payloads <- lapply(panel_names, function(id) {
    Filter(
      Negate(is.null),
      list(point_payloads[[id]] %||% NULL, range_payloads[[id]] %||% NULL)
    )
  })
  names(payloads) <- panel_names
  payloads
}

crossbar_middle_data <- function(data) {
  required <- c("xmin", "xmax")
  if (!all(required %in% names(data))) {
    return(data.frame())
  }

  middle <- if ("middle" %in% names(data)) data$middle else data$y %||% NULL
  if (is.null(middle)) {
    return(data.frame())
  }

  out <- data
  out$x <- data$xmin
  out$y <- middle
  out$xend <- data$xmax
  out$yend <- middle
  out
}

extract_crossbar_payloads <- function(layer, data) {
  data <- as.data.frame(data)
  rect_payloads <- extract_rect_payloads(layer, data)
  middle_payloads <- extract_vector_payloads(layer, crossbar_middle_data(data))
  panel_names <- union(names(rect_payloads), names(middle_payloads))

  payloads <- lapply(panel_names, function(id) {
    Filter(
      Negate(is.null),
      list(rect_payloads[[id]] %||% NULL, middle_payloads[[id]] %||% NULL)
    )
  })
  names(payloads) <- panel_names
  payloads
}

boxplot_body_data <- function(data) {
  required <- c("xmin", "xmax", "lower", "upper")
  if (!all(required %in% names(data))) {
    return(data.frame())
  }

  out <- data
  out$ymin <- data$lower
  out$ymax <- data$upper
  out
}

boxplot_segment_data <- function(data) {
  required <- c("x", "xmin", "xmax", "ymin", "lower", "middle", "upper", "ymax")
  if (!all(required %in% names(data))) {
    return(data.frame())
  }

  lower_whisker <- data
  lower_whisker$y <- data$ymin
  lower_whisker$xend <- data$x
  lower_whisker$yend <- data$lower

  upper_whisker <- data
  upper_whisker$y <- data$upper
  upper_whisker$xend <- data$x
  upper_whisker$yend <- data$ymax

  median <- data
  median$x <- data$xmin
  median$y <- data$middle
  median$xend <- data$xmax
  median$yend <- data$middle

  rbind(lower_whisker, upper_whisker, median)
}

boxplot_outlier_data <- function(data) {
  if (!"outliers" %in% names(data) || !"x" %in% names(data)) {
    return(data.frame())
  }

  rows <- lapply(seq_len(nrow(data)), function(i) {
    values <- unlist(data$outliers[[i]], use.names = FALSE)
    values <- as.numeric(values)
    values <- values[is.finite(values)]
    if (!length(values)) {
      return(NULL)
    }

    out <- data[rep(i, length(values)), , drop = FALSE]
    out$y <- values
    out
  })
  rows <- Filter(Negate(is.null), rows)

  if (!length(rows)) {
    return(data.frame())
  }

  do.call(rbind, rows)
}

extract_boxplot_payloads <- function(layer, data) {
  data <- as.data.frame(data)
  rect_payloads <- extract_rect_payloads(layer, boxplot_body_data(data))
  segment_payloads <- extract_vector_payloads(layer, boxplot_segment_data(data))
  outlier_payloads <- extract_point_payloads(layer, boxplot_outlier_data(data))
  panel_names <- Reduce(union, list(names(rect_payloads), names(segment_payloads), names(outlier_payloads)))

  payloads <- lapply(panel_names, function(id) {
    Filter(
      Negate(is.null),
      list(
        rect_payloads[[id]] %||% NULL,
        segment_payloads[[id]] %||% NULL,
        outlier_payloads[[id]] %||% NULL
      )
    )
  })
  names(payloads) <- panel_names
  payloads
}

extract_rect_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  required <- c("xmin", "xmax", "ymin", "ymax")
  if (!all(required %in% names(data))) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    panel_data <- data[split_index[[id]], , drop = FALSE]
    bounds <- panel_data[, required, drop = FALSE]
    finite_bounds <- Reduce(`&`, lapply(bounds, function(column) is.finite(as.numeric(column))))
    panel_data <- panel_data[finite_bounds, , drop = FALSE]

    if (!nrow(panel_data)) {
      return(NULL)
    }

    fill <- panel_data$fill %||% rep("#2C3E50", nrow(panel_data))
    stroke <- panel_data$colour %||% panel_data$color %||% NULL
    if (!is.null(stroke) && all(is.na(stroke))) {
      stroke <- NULL
    }
    linewidth <- panel_data$linewidth %||% panel_data$size %||% rep(if (is.null(stroke)) 0 else 0.5, nrow(panel_data))
    linewidth <- mm_to_pixels(linewidth)
    linewidth[!is.finite(linewidth) | linewidth < 0] <- 0

    ggwebgl_layer_rects(
      xmin = panel_data$xmin,
      xmax = panel_data$xmax,
      ymin = panel_data$ymin,
      ymax = panel_data$ymax,
      fill = fill,
      colour = stroke,
      alpha = panel_data$alpha %||% NULL,
      linewidth = linewidth,
      count = if ("count" %in% names(panel_data)) panel_data$count else NULL,
      density = if ("density" %in% names(panel_data)) panel_data$density else NULL,
      frame = if ("frame" %in% names(panel_data)) panel_data$frame else NULL,
      time = if ("time" %in% names(panel_data)) panel_data$time else NULL,
      panel_id = as.integer(id),
      geom = class(layer$geom)[1]
    )
  })
  names(payloads) <- names(split_index)
  Filter(Negate(is.null), payloads)
}

extract_ribbon_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  required <- c("x", "ymin", "ymax")
  if (!all(required %in% names(data))) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    panel_data <- data[split_index[[id]], , drop = FALSE]
    ribbon_runs <- split_ribbon_runs(panel_data)

    if (!length(ribbon_runs)) {
      return(NULL)
    }

    strips <- lapply(ribbon_runs, function(idx) {
      strip <- panel_data[idx, , drop = FALSE]
      fill <- strip$fill %||% rep("#2C3E50", nrow(strip))
      rgba <- colour_to_rgba(fill, strip$alpha %||% NULL)
      stroke <- strip$colour %||% strip$color %||% NULL
      if (!is.null(stroke) && all(is.na(stroke))) {
        stroke <- NULL
      }
      stroke_rgba <- if (is.null(stroke)) NULL else colour_to_rgba(stroke, strip$alpha %||% NULL)
      linewidth <- strip$linewidth %||% strip$size %||% rep(if (is.null(stroke)) 0 else 0.5, nrow(strip))
      linewidth <- mm_to_pixels(linewidth)
      linewidth <- linewidth[is.finite(linewidth) & linewidth >= 0]
      frame <- if ("frame" %in% names(strip)) as.integer(strip$frame) else NULL
      time <- if ("time" %in% names(strip)) as.numeric(strip$time) else NULL

      compact_list(list(
        rows = nrow(strip),
        group = first_group_value(strip),
        x = unname(as.numeric(strip$x)),
        ymin = unname(as.numeric(strip$ymin)),
        ymax = unname(as.numeric(strip$ymax)),
        width = if (length(linewidth)) as.numeric(linewidth[[1]]) else 0,
        frame = unname(frame),
        time = unname(time),
        rgba = unname(as.numeric(t(rgba))),
        stroke_rgba = if (is.null(stroke_rgba)) NULL else unname(as.numeric(t(stroke_rgba)))
      ))
    })

    compact_list(list(
      panel_id = as.integer(id),
      type = "ribbons",
      geom = class(layer$geom)[1],
      rows = sum(vapply(strips, `[[`, integer(1), "rows")),
      strip_count = length(strips),
      triangle_count = sum(pmax(0L, vapply(strips, `[[`, integer(1), "rows") - 1L) * 2L),
      strips = strips
    ))
  })
  names(payloads) <- names(split_index)
  Filter(Negate(is.null), payloads)
}

extract_raster_panel_payload <- function(layer, data, panel_id) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(NULL)
  }

  x_values <- sort(unique(as.numeric(data$x)))
  y_values <- sort(unique(as.numeric(data$y)))
  width <- length(x_values)
  height <- length(y_values)

  if (!width || !height) {
    return(NULL)
  }

  rgba <- colour_to_rgba(coalesce_colour(data), data$alpha %||% NULL)
  rgba_bytes <- integer(width * height * 4L)

  x_index <- match(as.numeric(data$x), x_values)
  y_index <- match(as.numeric(data$y), y_values)

  for (i in seq_len(nrow(data))) {
    if (!is.finite(x_index[[i]]) || !is.finite(y_index[[i]])) {
      next
    }

    offset <- ((y_index[[i]] - 1L) * width + (x_index[[i]] - 1L)) * 4L
    rgba_bytes[offset + seq_len(4L)] <- rgba_to_bytes(rgba[i, , drop = FALSE])
  }

  compact_list(list(
    panel_id = as.integer(panel_id),
    type = "raster",
    geom = class(layer$geom)[1],
    rows = nrow(data),
    width = width,
    height = height,
    xmin = min(as.numeric(data$xmin), na.rm = TRUE),
    xmax = max(as.numeric(data$xmax), na.rm = TRUE),
    ymin = min(as.numeric(data$ymin), na.rm = TRUE),
    ymax = max(as.numeric(data$ymax), na.rm = TRUE),
    interpolate = isTRUE(layer$geom_params$interpolate %||% FALSE),
    rgba = rgba_bytes
  ))
}

extract_raster_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    extract_raster_panel_payload(layer, data[split_index[[id]], , drop = FALSE], panel_id = as.integer(id))
  })
  names(payloads) <- names(split_index)
  Filter(Negate(is.null), payloads)
}

polygon_has_multiple_subgroups <- function(data) {
  if (!"subgroup" %in% names(data)) {
    return(FALSE)
  }

  length(unique(as.character(data$subgroup))) > 1L
}

polygon_fill_values <- function(data) {
  fill <- data$fill %||% NULL
  if (is.null(fill) || all(is.na(fill))) {
    fill <- data$colour %||% data$color %||% NULL
  }
  fill %||% rep("#2C3E50", nrow(data))
}

polygon_outline_colour <- function(data) {
  stroke <- data$colour %||% data$color %||% NULL
  if (is.null(stroke) || all(is.na(stroke))) {
    return(rep(NA_character_, nrow(data)))
  }
  stroke
}

polygon_outline_width <- function(data) {
  width <- data$linewidth %||% data$size %||% rep(0, nrow(data))
  width <- mm_to_pixels(width)
  width[!is.finite(width) | width < 0] <- 0
  width
}

extract_polygon_panel_payload <- function(layer, panel_data, panel_id) {
  group_chr <- as.character(panel_data$group %||% seq_len(nrow(panel_data)))
  group_index <- split(seq_len(nrow(panel_data)), group_chr)
  vertices <- list()
  triangles <- list()
  outline <- list()
  offset <- 0L

  for (group_name in names(group_index)) {
    ring <- panel_data[group_index[[group_name]], , drop = FALSE]
    if (polygon_has_multiple_subgroups(ring)) {
      rlang::abort("`geom_polygon_webgl()` does not support holes or multiple rings within one polygon group.")
    }

    ring <- ggwebgl_polygon_prepare_ring(ring)
    tri <- ggwebgl_polygon_triangulate_ring(ring$x, ring$y)
    tri$pick_id <- group_name
    tri[, c("i", "j", "k")] <- tri[, c("i", "j", "k"), drop = FALSE] + offset

    fill <- polygon_fill_values(ring)
    alpha <- ring$alpha %||% rep(1, nrow(ring))
    vertices[[length(vertices) + 1L]] <- data.frame(
      x = as.numeric(ring$x),
      y = as.numeric(ring$y),
      z = 0,
      fill = fill,
      alpha = alpha,
      id = rep(group_name, nrow(ring)),
      stringsAsFactors = FALSE
    )
    triangles[[length(triangles) + 1L]] <- tri

    outline[[length(outline) + 1L]] <- compact_list(list(
      group = group_name,
      colour = as.character(polygon_outline_colour(ring)[[1L]]),
      linewidth = as.numeric(polygon_outline_width(ring)[[1L]])
    ))
    offset <- offset + nrow(ring)
  }

  if (!length(vertices) || !length(triangles)) {
    return(NULL)
  }

  vertices <- do.call(rbind, vertices)
  triangles <- do.call(rbind, triangles)
  wireframe <- any(vapply(outline, function(item) {
    !is.na(item$colour %||% NA_character_) && isTRUE((item$linewidth %||% 0) > 0)
  }, logical(1)))

  payload <- ggwebgl_layer_mesh(
    vertices = vertices,
    x = "x",
    y = "y",
    z = "z",
    triangles = triangles,
    i = "i",
    j = "j",
    k = "k",
    colour = "fill",
    alpha = "alpha",
    id = "id",
    material = layer$geom_params$material %||% ggwebgl_material(shading = "mesh_flat", wireframe = wireframe),
    shading = layer$geom_params$shading %||% "mesh_flat",
    pick_id = "pick_id",
    panel_id = as.integer(panel_id),
    geom = class(layer$geom)[1],
    wireframe = wireframe
  )
  payload$polygon_meta <- compact_list(list(
    simple = TRUE,
    triangulation = "ear_clipping",
    groups = names(group_index),
    outline = outline
  ))
  payload
}

extract_polygon_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    extract_polygon_panel_payload(layer, data[split_index[[id]], , drop = FALSE], panel_id = as.integer(id))
  })
  names(payloads) <- names(split_index)
  Filter(Negate(is.null), payloads)
}

extract_mesh_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  if (!all(c("i", "j", "k") %in% names(data))) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    panel_data <- data[split_index[[id]], , drop = FALSE]
    tri_data <- panel_data[stats::complete.cases(panel_data[, c("i", "j", "k"), drop = FALSE]), , drop = FALSE]

    if (!nrow(tri_data)) {
      return(NULL)
    }

    z <- if ("z" %in% names(panel_data)) panel_data$z else rep(0, nrow(panel_data))
    ids <- point_selection_ids(panel_data)

    ggwebgl_layer_mesh(
      vertices = panel_data,
      x = "x",
      y = "y",
      z = z,
      triangles = tri_data,
      i = "i",
      j = "j",
      k = "k",
      colour = coalesce_colour(panel_data),
      alpha = panel_data$alpha %||% NULL,
      id = ids,
      scalar = if ("scalar" %in% names(panel_data)) panel_data$scalar else NULL,
      normals = layer$geom_params$normals %||% NULL,
      material = layer$geom_params$material %||% ggwebgl_material(wireframe = isTRUE(layer$geom_params$wireframe %||% FALSE)),
      shading = layer$geom_params$shading %||% NULL,
      pick_id = layer$geom_params$pick_id %||% NULL,
      panel_id = as.integer(id),
      geom = class(layer$geom)[1],
      wireframe = layer$geom_params$wireframe %||% NULL
    )
  })
  names(payloads) <- names(split_index)
  Filter(Negate(is.null), payloads)
}

extract_surface_payloads <- function(layer, data) {
  data <- as.data.frame(data)

  if (!nrow(data)) {
    return(empty_payload_map())
  }

  panel_id <- as.integer(data$PANEL %||% rep(1L, nrow(data)))
  split_index <- split(seq_len(nrow(data)), as.character(panel_id))
  payloads <- lapply(names(split_index), function(id) {
    panel_data <- data[split_index[[id]], , drop = FALSE]
    x_values <- sort(unique(as.numeric(panel_data$x)))
    y_values <- sort(unique(as.numeric(panel_data$y)))
    if (length(x_values) < 2L || length(y_values) < 2L) {
      return(NULL)
    }

    z_values <- if ("z" %in% names(panel_data)) as.numeric(panel_data$z) else seq_len(nrow(panel_data))
    z_matrix <- matrix(NA_real_, nrow = length(y_values), ncol = length(x_values))
    colour_matrix <- matrix(NA_character_, nrow = length(y_values), ncol = length(x_values))
    alpha_matrix <- matrix(NA_real_, nrow = length(y_values), ncol = length(x_values))
    uncertainty_matrix <- if ("uncertainty" %in% names(panel_data)) {
      matrix(NA_real_, nrow = length(y_values), ncol = length(x_values))
    } else {
      NULL
    }
    x_index <- match(as.numeric(panel_data$x), x_values)
    y_index <- match(as.numeric(panel_data$y), y_values)
    colours <- coalesce_colour(panel_data)
    alpha_values <- as.numeric(panel_data$alpha %||% rep(1, nrow(panel_data)))

    for (i in seq_len(nrow(panel_data))) {
      if (is.finite(x_index[[i]]) && is.finite(y_index[[i]])) {
        z_matrix[y_index[[i]], x_index[[i]]] <- z_values[[i]]
        colour_matrix[y_index[[i]], x_index[[i]]] <- colours[[i]]
        alpha_matrix[y_index[[i]], x_index[[i]]] <- alpha_values[[i]]
        if (!is.null(uncertainty_matrix)) {
          uncertainty_matrix[y_index[[i]], x_index[[i]]] <- as.numeric(panel_data$uncertainty[[i]])
        }
      }
    }

    if (any(!is.finite(z_matrix))) {
      rlang::abort("Surface layers require a complete regular x/y grid; missing cells are not interpolated.")
    }

    ggwebgl_layer_surface(
      z = z_matrix,
      x = x_values,
      y = y_values,
      colour = as.vector(t(colour_matrix)),
      alpha = as.vector(t(alpha_matrix)),
      shading = layer$geom_params$shading %||% "surface_lambert",
      normals = layer$geom_params$normals %||% "auto",
      material = layer$geom_params$material %||% ggwebgl_material(shading = "lambert", wireframe = isTRUE(layer$geom_params$wireframe %||% FALSE)),
      uncertainty = if (is.null(uncertainty_matrix)) NULL else as.vector(t(uncertainty_matrix)),
      pick_id = layer$geom_params$pick_id %||% NULL,
      panel_id = as.integer(id),
      geom = class(layer$geom)[1],
      wireframe = layer$geom_params$wireframe %||% FALSE,
      contours = layer$geom_params$contours %||% FALSE,
      contour_levels = layer$geom_params$contour_levels %||% NULL,
      contour_colour = layer$geom_params$contour_colour %||% "#1f2937",
      contour_width = layer$geom_params$contour_width %||% 1
    )
  })
  names(payloads) <- names(split_index)
  Filter(Negate(is.null), payloads)
}

extract_supported_layer_source <- function(layer, data, index) {
  registry_entry <- ggwebgl_geom_registry_match(layer)

  if (!is.null(registry_entry)) {
    extractor <- get(registry_entry$extractor, mode = "function", inherits = TRUE)

    return(compact_list(list(
      index = index,
      type = registry_entry$primitive,
      geom = class(layer$geom)[1],
      subtype = registry_entry$subtype %||% NULL,
      payloads = extractor(layer, data)
    )))
  }

  NULL
}

extract_unsupported_layer_metadata <- function(layer, data, index) {
  compact_list(list(
    index = index,
    geom = class(layer$geom)[1],
    stat = class(layer$stat)[1],
    rows = if (is.null(data)) 0L else nrow(data)
  ))
}

extract_ggplot_scene_source <- function(plot) {
  built_plot <- ggplot2::ggplot_build(plot)
  layer_metadata <- build_layer_metadata(plot, built_plot$data)
  layer_sources <- list()
  unsupported_layers <- list()

  for (i in seq_along(plot$layers)) {
    layer <- plot$layers[[i]]
    data <- built_plot$data[[i]]

    if (is_supported_geom(layer)) {
      layer_sources[[length(layer_sources) + 1L]] <- extract_supported_layer_source(layer, data, i)
    } else {
      unsupported_layers[[length(unsupported_layers) + 1L]] <- extract_unsupported_layer_metadata(layer, data, i)
    }
  }

  compact_list(list(
    labels = compact_list(list(
      title = plot$labels$title %||% NULL,
      subtitle = plot$labels$subtitle %||% NULL,
      x = plot$labels$x %||% NULL,
      y = plot$labels$y %||% NULL
    )),
    webgl = ggwebgl_scene_webgl_options(plot$ggwebgl),
    layer_count = length(plot$layers),
    layer_metadata = layer_metadata,
    panel_contract = extract_panel_contract(built_plot),
    layer_sources = layer_sources,
    unsupported_layers = unsupported_layers
  ))
}

panel_layer_payloads <- function(layer_source, panel_id) {
  payload <- layer_source$payloads[[as.character(panel_id)]] %||% NULL

  if (is.null(payload)) {
    return(list())
  }
  if (!is.null(payload$type)) {
    return(list(payload))
  }
  payload
}

build_panel_spec <- function(panel_contract, layer_sources) {
  panel_id <- panel_contract$panel_id
  render_layers <- Filter(
    Negate(is.null),
    unlist(lapply(layer_sources, panel_layer_payloads, panel_id = panel_id), recursive = FALSE)
  )

  point_layers <- Filter(function(x) identical(x$type, "points"), render_layers)
  line_layers <- Filter(function(x) identical(x$type, "lines"), render_layers)
  raster_layers <- Filter(function(x) identical(x$type, "raster"), render_layers)
  vector_layers <- Filter(function(x) identical(x$type, "vectors"), render_layers)
  rect_layers <- Filter(function(x) identical(x$type, "rects"), render_layers)
  ribbon_layers <- Filter(function(x) identical(x$type, "ribbons"), render_layers)
  mesh_layers <- Filter(function(x) identical(x$type, "mesh"), render_layers)
  surface_layers <- Filter(function(x) identical(x$type, "surface"), render_layers)

  compact_list(list(
    panel_id = panel_contract$panel_id,
    row = panel_contract$row,
    col = panel_contract$col,
    label = panel_contract$label,
    bounds = panel_contract$bounds,
    viewport = panel_contract$viewport,
    primitives = unique(vapply(render_layers, `[[`, character(1), "type")),
    point_count = sum(vapply(point_layers, `[[`, integer(1), "rows")),
    line_vertex_count = sum(vapply(line_layers, `[[`, integer(1), "rows")),
    path_count = sum(vapply(line_layers, `[[`, integer(1), "path_count")),
    raster_cell_count = sum(vapply(raster_layers, function(x) x$width * x$height, integer(1))),
    vector_count = sum(vapply(vector_layers, `[[`, integer(1), "rows")),
    rect_count = sum(vapply(rect_layers, `[[`, integer(1), "rows")),
    ribbon_count = sum(vapply(ribbon_layers, `[[`, integer(1), "strip_count")),
    ribbon_vertex_count = sum(vapply(ribbon_layers, `[[`, integer(1), "rows")),
    ribbon_triangle_count = sum(vapply(ribbon_layers, `[[`, integer(1), "triangle_count")),
    mesh_vertex_count = sum(vapply(mesh_layers, `[[`, integer(1), "vertex_count")),
    mesh_triangle_count = sum(vapply(mesh_layers, `[[`, integer(1), "triangle_count")),
    surface_vertex_count = sum(vapply(surface_layers, `[[`, integer(1), "vertex_count")),
    surface_triangle_count = sum(vapply(surface_layers, `[[`, integer(1), "triangle_count")),
    layers = render_layers
  ))
}

empty_panel_render <- function(panel_contract) {
  compact_list(list(
    panel_id = panel_contract$panel_id,
    row = panel_contract$row,
    col = panel_contract$col,
    label = panel_contract$label,
    bounds = panel_contract$bounds,
    viewport = panel_contract$viewport,
    primitives = character(),
    point_count = 0L,
    line_vertex_count = 0L,
    path_count = 0L,
    raster_cell_count = 0L,
    vector_count = 0L,
    rect_count = 0L,
    ribbon_count = 0L,
    ribbon_vertex_count = 0L,
    ribbon_triangle_count = 0L,
    mesh_vertex_count = 0L,
    mesh_triangle_count = 0L,
    surface_vertex_count = 0L,
    surface_triangle_count = 0L,
    layers = list()
  ))
}

add_single_panel_compatibility <- function(render) {
  derive_single_panel_compatibility(render)
}

build_render_plan <- function(scene_source) {
  panel_contract <- scene_source$panel_contract
  messages <- character()

  if (panel_contract$has_free_scales) {
    messages <- c(
      messages,
      "Facet layouts with free x or y scales are not rendered yet; only fixed-scale facets are currently supported."
    )

    return(add_single_panel_compatibility(compact_list(list(
      mode = "metadata",
      grid = panel_contract$grid,
      panels = lapply(panel_contract$panels, empty_panel_render),
      primitives = character(),
      point_count = 0L,
      line_vertex_count = 0L,
      path_count = 0L,
      raster_cell_count = 0L,
      vector_count = 0L,
      rect_count = 0L,
      ribbon_count = 0L,
      ribbon_vertex_count = 0L,
      ribbon_triangle_count = 0L,
      mesh_vertex_count = 0L,
      mesh_triangle_count = 0L,
      surface_vertex_count = 0L,
      surface_triangle_count = 0L,
      unsupported_layers = scene_source$unsupported_layers,
      messages = unname(messages)
    ))))
  }

  panels <- lapply(panel_contract$panels, function(panel) {
    build_panel_spec(panel, scene_source$layer_sources)
  })

  point_count <- sum(vapply(panels, `[[`, integer(1), "point_count"))
  line_vertex_count <- sum(vapply(panels, `[[`, integer(1), "line_vertex_count"))
  path_count <- sum(vapply(panels, `[[`, integer(1), "path_count"))
  raster_cell_count <- sum(vapply(panels, `[[`, integer(1), "raster_cell_count"))
  vector_count <- sum(vapply(panels, `[[`, integer(1), "vector_count"))
  rect_count <- sum(vapply(panels, `[[`, integer(1), "rect_count"))
  ribbon_count <- sum(vapply(panels, `[[`, integer(1), "ribbon_count"))
  ribbon_vertex_count <- sum(vapply(panels, `[[`, integer(1), "ribbon_vertex_count"))
  ribbon_triangle_count <- sum(vapply(panels, `[[`, integer(1), "ribbon_triangle_count"))
  mesh_vertex_count <- sum(vapply(panels, `[[`, integer(1), "mesh_vertex_count"))
  mesh_triangle_count <- sum(vapply(panels, `[[`, integer(1), "mesh_triangle_count"))
  surface_vertex_count <- sum(vapply(panels, `[[`, integer(1), "surface_vertex_count"))
  surface_triangle_count <- sum(vapply(panels, `[[`, integer(1), "surface_triangle_count"))
  primitives <- unique(unlist(lapply(panels, `[[`, "primitives"), use.names = FALSE))
  has_renderable_content <- any(vapply(panels, function(panel) length(panel$layers), integer(1)) > 0L)

  if (!has_renderable_content) {
    messages <- c(
      messages,
      "No supported point, line, raster, vector, rectangle, ribbon, mesh, or surface layers are currently available for the WebGL renderer."
    )
  }

  render <- compact_list(list(
    mode = if (has_renderable_content) "webgl" else "metadata",
    grid = panel_contract$grid,
    panels = panels,
    primitives = primitives,
    point_count = point_count,
    line_vertex_count = line_vertex_count,
    path_count = path_count,
    raster_cell_count = raster_cell_count,
    vector_count = vector_count,
    rect_count = rect_count,
    ribbon_count = ribbon_count,
    ribbon_vertex_count = ribbon_vertex_count,
    ribbon_triangle_count = ribbon_triangle_count,
    mesh_vertex_count = mesh_vertex_count,
    mesh_triangle_count = mesh_triangle_count,
    surface_vertex_count = surface_vertex_count,
    surface_triangle_count = surface_triangle_count,
    unsupported_layers = scene_source$unsupported_layers,
    messages = unname(messages)
  ))

  add_single_panel_compatibility(render)
}

build_ggwebgl_spec <- function(plot) {
  scene_source <- extract_ggplot_scene_source(plot)
  render <- build_render_plan(scene_source)
  webgl <- ggwebgl_complete_timeline(scene_source$webgl, render)
  render <- ggwebgl_apply_transport(render, webgl)

  validate_ggwebgl_scene(compact_list(list(
    scene_version = ggwebgl_scene_version(),
    package_version = as.character(utils::packageVersion("ggWebGL")),
    labels = scene_source$labels,
    webgl = webgl,
    layer_count = scene_source$layer_count,
    layers = scene_source$layer_metadata,
    render = ggwebgl_enrich_render(render, webgl)
  )), allow_legacy = FALSE)
}

#' Create a ggWebGL htmlwidget
#'
#' Low-level constructor for the package widget binding.
#'
#' @param x Named list describing a widget payload.
#' @param width,height Optional widget dimensions passed through to
#'   [htmlwidgets::createWidget()].
#' @param elementId Optional DOM element id.
#'
#' @return An `htmlwidget`.
#'
#' @examples
#' point_layer <- ggwebgl_layer_points(
#'   data.frame(x = c(0, 1, 2), y = c(2, 1, 0)),
#'   x = "x",
#'   y = "y"
#' )
#' spec <- ggwebgl_spec(layers = list(point_layer))
#'
#' ggWebGL(spec, width = 320, height = 240)
#' @export
ggWebGL <- function(x = list(), width = NULL, height = NULL, elementId = NULL) {
  classed_adapter <- inherits(x, "ggwebgl_spec") ||
    (!is.null(attr(x, "class")) && !identical(class(x), "list"))
  if (inherits(x, "ggwebgl_spec") ||
      (!is.null(attr(x, "class")) && !identical(class(x), "list"))) {
    x <- as_ggwebgl_spec(x)
  }
  if (isTRUE(classed_adapter) || !is.null(x$scene_version)) {
    x <- validate_ggwebgl_scene(x, allow_legacy = TRUE)
  }

  htmlwidgets::createWidget(
    name = "ggWebGL",
    x = x,
    width = width,
    height = height,
    package = "ggWebGL",
    elementId = elementId
  )
}

#' Convert a ggplot to a ggWebGL Widget
#'
#' Build a widget payload from a `ggplot` object. The current implementation
#' renders supported point, line, raster, and fixed-scale facet layouts through
#' the browser WebGL path while keeping unsupported layers explicit in the
#' payload.
#'
#' @param plot A `ggplot` object.
#' @param width,height Optional widget dimensions.
#' @param elementId Optional DOM element id.
#'
#' @return An `htmlwidget`.
#'
#' @examples
#' plot <- ggplot2::ggplot(
#'   mtcars[1:10, ],
#'   ggplot2::aes(mpg, wt, colour = factor(cyl))
#' ) +
#'   geom_point_webgl(size = 2) +
#'   theme_webgl(shader = "default")
#'
#' ggplot_webgl(plot, width = 420, height = 320)
#' @export
ggplot_webgl <- function(plot, width = NULL, height = NULL, elementId = NULL) {
  if (!inherits(plot, "ggplot")) {
    rlang::abort("`plot` must be a ggplot object.")
  }

  ggWebGL(
    x = build_ggwebgl_spec(plot),
    width = width,
    height = height,
    elementId = elementId
  )
}

#' Shiny Output Binding for ggWebGL
#'
#' @param outputId Output variable to read from.
#' @param width,height Widget dimensions.
#'
#' @return A Shiny output tag.
#'
#' @examplesIf requireNamespace("shiny", quietly = TRUE)
#' ui <- shiny::fluidPage(
#'   ggWebGLOutput("plot", height = "320px")
#' )
#'
#' ui
#' @export
ggWebGLOutput <- function(outputId, width = "100%", height = "480px") {
  htmlwidgets::shinyWidgetOutput(outputId, "ggWebGL", width, height, package = "ggWebGL")
}

#' Render a ggWebGL Widget in Shiny
#'
#' @param expr An expression returning a `ggWebGL` widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#'
#' @return A Shiny render function.
#'
#' @examplesIf requireNamespace("shiny", quietly = TRUE)
#' server <- function(input, output, session) {
#'   output$plot <- renderGgWebGL({
#'     ggplot_webgl(
#'       ggplot2::ggplot(
#'         mtcars[1:8, ],
#'         ggplot2::aes(mpg, wt, colour = factor(cyl))
#'       ) +
#'         geom_point_webgl(size = 2) +
#'         theme_webgl()
#'     )
#'   })
#' }
#'
#' server
#' @export
renderGgWebGL <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }

  htmlwidgets::shinyRenderWidget(expr, ggWebGLOutput, env, quoted = TRUE)
}
