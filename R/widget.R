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
    path_runs <- if (identical(subtype, "path3d")) {
      split_ordered_group_path_runs(panel_data)
    } else {
      split_path_runs(panel_data)
    }

    if (!length(path_runs)) {
      return(NULL)
    }

    paths <- lapply(path_runs, function(idx) {
      path <- panel_data[idx, , drop = FALSE]
      colour <- coalesce_colour(path)
      rgba <- colour_to_rgba(colour, path$alpha %||% NULL)
      linewidth <- path$linewidth %||% path$size %||% rep(1, nrow(path))
      linewidth <- mm_to_pixels(linewidth)
      linewidth <- linewidth[is.finite(linewidth) & linewidth > 0]
      z <- if ("z" %in% names(path)) as.numeric(path$z) else NULL
      frame <- if ("frame" %in% names(path)) as.integer(path$frame) else NULL
      time <- if ("time" %in% names(path)) as.numeric(path$time) else NULL

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
  head_size <- layer$geom_params$head_size %||% rep(9, nrow(data))
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
  if (is_vector_geom(layer)) {
    return(compact_list(list(
      index = index,
      type = "vectors",
      geom = class(layer$geom)[1],
      payloads = extract_vector_payloads(layer, data)
    )))
  }

  if (is_mesh_geom(layer)) {
    return(compact_list(list(
      index = index,
      type = "mesh",
      geom = class(layer$geom)[1],
      payloads = extract_mesh_payloads(layer, data)
    )))
  }

  if (is_surface_geom(layer)) {
    return(compact_list(list(
      index = index,
      type = "surface",
      geom = class(layer$geom)[1],
      payloads = extract_surface_payloads(layer, data)
    )))
  }

  if (is_point_geom(layer)) {
    return(compact_list(list(
      index = index,
      type = "points",
      geom = class(layer$geom)[1],
      payloads = extract_point_payloads(layer, data)
    )))
  }

  if (is_line_geom(layer)) {
    return(compact_list(list(
      index = index,
      type = "lines",
      geom = class(layer$geom)[1],
      payloads = extract_line_payloads(layer, data)
    )))
  }

  if (is_raster_geom(layer)) {
    return(compact_list(list(
      index = index,
      type = "raster",
      geom = class(layer$geom)[1],
      payloads = extract_raster_payloads(layer, data)
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

panel_layer_payload <- function(layer_source, panel_id) {
  layer_source$payloads[[as.character(panel_id)]] %||% NULL
}

build_panel_spec <- function(panel_contract, layer_sources) {
  panel_id <- panel_contract$panel_id
  render_layers <- Filter(
    Negate(is.null),
    lapply(layer_sources, panel_layer_payload, panel_id = panel_id)
  )

  point_layers <- Filter(function(x) identical(x$type, "points"), render_layers)
  line_layers <- Filter(function(x) identical(x$type, "lines"), render_layers)
  raster_layers <- Filter(function(x) identical(x$type, "raster"), render_layers)
  vector_layers <- Filter(function(x) identical(x$type, "vectors"), render_layers)
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
  mesh_vertex_count <- sum(vapply(panels, `[[`, integer(1), "mesh_vertex_count"))
  mesh_triangle_count <- sum(vapply(panels, `[[`, integer(1), "mesh_triangle_count"))
  surface_vertex_count <- sum(vapply(panels, `[[`, integer(1), "surface_vertex_count"))
  surface_triangle_count <- sum(vapply(panels, `[[`, integer(1), "surface_triangle_count"))
  primitives <- unique(unlist(lapply(panels, `[[`, "primitives"), use.names = FALSE))
  has_renderable_content <- any(vapply(panels, function(panel) length(panel$layers), integer(1)) > 0L)

  if (!has_renderable_content) {
    messages <- c(
      messages,
      "No supported point, line, raster, vector, mesh, or surface layers are currently available for the WebGL renderer."
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

  validate_ggwebgl_scene(compact_list(list(
    scene_version = ggwebgl_scene_version(),
    package_version = as.character(utils::packageVersion("ggWebGL")),
    labels = scene_source$labels,
    webgl = scene_source$webgl,
    layer_count = scene_source$layer_count,
    layers = scene_source$layer_metadata,
    render = ggwebgl_enrich_render(build_render_plan(scene_source), scene_source$webgl)
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
