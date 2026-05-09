#' Structured Surface Matrix
#'
#' Create a structured surface-grid object from a numeric matrix. Rows map to
#' `y`, columns map to `x`, and the matrix values map to `z`.
#'
#' @param z Numeric matrix of height values.
#' @param x Optional x-coordinate vector with one value per matrix column.
#' @param y Optional y-coordinate vector with one value per matrix row.
#'
#' @return A `ggwebgl_surface_matrix` object accepted by
#'   [ggwebgl_layer_surface()].
#'
#' @examples
#' surface_matrix(volcano[1:3, 1:3])
#' @export
surface_matrix <- function(z, x = NULL, y = NULL) {
  if (!is.matrix(z)) {
    z <- as.matrix(z)
  }
  storage.mode(z) <- "double"

  nr <- nrow(z)
  nc <- ncol(z)
  if (!length(z) || nr < 2L || nc < 2L) {
    rlang::abort("`z` must be a numeric matrix with at least two rows and two columns.")
  }
  if (any(!is.finite(z))) {
    rlang::abort("`z` must contain finite numeric values; missing surface cells are not interpolated.")
  }

  x <- as.numeric(x %||% seq_len(nc))
  y <- as.numeric(y %||% seq_len(nr))
  if (length(x) != nc || length(y) != nr) {
    rlang::abort("`x` and `y` must match the matrix columns and rows.")
  }
  if (any(!is.finite(x)) || any(!is.finite(y))) {
    rlang::abort("`x` and `y` must contain finite numeric values.")
  }
  if (anyDuplicated(x) || anyDuplicated(y)) {
    rlang::abort("`x` and `y` coordinates must be unique.")
  }

  structure(
    list(z = z, x = x, y = y, nrow = as.integer(nr), ncol = as.integer(nc)),
    class = c("ggwebgl_surface_matrix", "list")
  )
}

#' Renderer-Ready Structured Surface Layer
#'
#' Build a first-class structured-grid surface layer from a numeric matrix or
#' `surface_matrix()` object.
#'
#' @param z Numeric matrix or `ggwebgl_surface_matrix` object.
#' @param x,y Optional coordinate vectors for matrix input.
#' @param colour Optional colour vector. Ignored when `rgba` is supplied.
#' @param rgba Optional renderer-ready RGBA matrix/data frame with four columns,
#'   or vector of length `vertex_count * 4`, using values in `[0, 1]` or
#'   `[0, 255]`.
#' @param alpha Optional alpha vector used with `colour`.
#' @param palette HCL palette used when neither `colour` nor `rgba` is supplied.
#' @param shading Surface shader mode.
#' @param normals Normal-generation mode. `"auto"` computes vertex normals.
#' @param material Surface material created by [ggwebgl_material()].
#' @param uncertainty Optional per-vertex uncertainty values in `[0, 1]`.
#' @param pick_id Optional triangle picking ids.
#' @param panel_id Scalar panel identifier.
#' @param geom Debug geom name recorded in the payload.
#' @param wireframe Whether to request a wireframe overlay.
#' @param contours Whether to generate contour-line overlays on the R side.
#' @param contour_levels Optional numeric contour levels.
#' @param contour_colour Contour line colour.
#' @param contour_width Contour line width in renderer pixels.
#'
#' @return A normalized structured surface layer list.
#'
#' @examples
#' ggwebgl_layer_surface(volcano[1:4, 1:4])
#' @export
ggwebgl_layer_surface <- function(z,
                                  x = NULL,
                                  y = NULL,
                                  colour = NULL,
                                  rgba = NULL,
                                  alpha = NULL,
                                  palette = "Terrain 2",
                                  shading = c(
                                    "surface_lambert",
                                    "surface_flat",
                                    "surface_height_colormap",
                                    "surface_uncertainty_alpha"
                                  ),
                                  normals = "auto",
                                  material = NULL,
                                  uncertainty = NULL,
                                  pick_id = NULL,
                                  panel_id = 1L,
                                  geom = "adapter_surface",
                                  wireframe = FALSE,
                                  contours = FALSE,
                                  contour_levels = NULL,
                                  contour_colour = "#1f2937",
                                  contour_width = 1) {
  grid <- ggwebgl_as_surface_matrix(z, x = x, y = y)
  shading <- normalise_surface_shading(shading)
  material <- material %||% ggwebgl_material(
    shading = if (identical(shading, "surface_lambert")) "lambert" else "flat",
    wireframe = wireframe
  )
  material <- normalise_material(material, wireframe = isTRUE(wireframe) || isTRUE(material$wireframe))

  nr <- grid$nrow
  nc <- grid$ncol
  vertex_count <- as.integer(nr * nc)
  vertices <- expand.grid(x = grid$x, y = grid$y)
  z_values <- as.numeric(t(grid$z))
  positions <- as.numeric(t(cbind(vertices$x, vertices$y, z_values)))

  if (is.null(rgba) && is.null(colour)) {
    rng <- range(z_values, finite = TRUE)
    scaled <- if (diff(rng) > 0) (z_values - rng[[1]]) / diff(rng) else rep(0.5, vertex_count)
    ramp <- grDevices::colorRampPalette(grDevices::hcl.colors(9L, palette))
    colour <- ramp(256L)[pmax(1L, pmin(256L, as.integer(round(scaled * 255)) + 1L))]
  }

  rgba_matrix <- ggwebgl_resolve_rgba(rgba, colour, alpha %||% 1, vertex_count)
  triangles <- ggwebgl_surface_triangles(nr, nc)
  indices <- as.integer(c(rbind(triangles$i, triangles$j, triangles$k)))
  triangle_count <- as.integer(length(indices) / 3L)
  normal_matrix <- ggwebgl_resolve_normals(normals, vertices$x, vertices$y, z_values, indices)
  uncertainty_values <- ggwebgl_resolve_surface_uncertainty(uncertainty, nr, nc, vertex_count)
  contour_payload <- if (isTRUE(contours)) {
    ggwebgl_surface_contours(
      x = grid$x,
      y = grid$y,
      z = grid$z,
      levels = contour_levels,
      colour = contour_colour,
      width = contour_width
    )
  } else {
    NULL
  }

  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "surface",
    geom = as.character(geom)[[1L]],
    rows = vertex_count,
    vertex_count = vertex_count,
    triangle_count = triangle_count,
    positions = unname(positions),
    normals = unname(as.numeric(t(normal_matrix))),
    colors = unname(as.numeric(t(rgba_matrix))),
    indices = unname(as.integer(indices - 1L)),
    wire_indices = unname(ggwebgl_surface_wire_indices(nr, nc)),
    contours = contour_payload,
    uncertainty = unname(uncertainty_values),
    material = material,
    pick_id = unname(ggwebgl_resolve_pick_id(pick_id, triangle_count)),
    wireframe = isTRUE(wireframe) || isTRUE(material$wireframe),
    bbox3d = list(
      xmin = min(grid$x),
      xmax = max(grid$x),
      ymin = min(grid$y),
      ymax = max(grid$y),
      zmin = min(z_values),
      zmax = max(z_values)
    ),
    surface_meta = list(
      nrow = as.integer(nr),
      ncol = as.integer(nc),
      x = unname(as.numeric(grid$x)),
      y = unname(as.numeric(grid$y)),
      z_range = unname(range(z_values, finite = TRUE)),
      shading = shading,
      triangulation = "regular_grid"
    )
  ))
}

ggwebgl_as_surface_matrix <- function(z, x = NULL, y = NULL) {
  if (inherits(z, "ggwebgl_surface_matrix")) {
    if (!is.null(x) || !is.null(y)) {
      return(surface_matrix(z$z, x = x %||% z$x, y = y %||% z$y))
    }
    return(z)
  }

  surface_matrix(z, x = x, y = y)
}

normalise_surface_shading <- function(shading) {
  shading <- match.arg(as.character(shading)[[1L]], c(
    "surface_lambert",
    "surface_flat",
    "surface_height_colormap",
    "surface_uncertainty_alpha",
    "lambert",
    "flat",
    "height",
    "uncertainty"
  ))

  switch(
    shading,
    lambert = "surface_lambert",
    flat = "surface_flat",
    height = "surface_height_colormap",
    uncertainty = "surface_uncertainty_alpha",
    shading
  )
}

ggwebgl_surface_triangles <- function(nr, nc) {
  if (nr < 2L || nc < 2L) {
    return(data.frame(i = integer(), j = integer(), k = integer()))
  }

  cells <- expand.grid(row = seq_len(nr - 1L), col = seq_len(nc - 1L))
  index <- function(row, col) {
    as.integer((row - 1L) * nc + col)
  }

  tris <- do.call(rbind, lapply(seq_len(nrow(cells)), function(cell_id) {
    row <- cells$row[[cell_id]]
    col <- cells$col[[cell_id]]
    v00 <- index(row, col)
    v10 <- index(row, col + 1L)
    v01 <- index(row + 1L, col)
    v11 <- index(row + 1L, col + 1L)
    rbind(
      c(i = v00, j = v10, k = v11),
      c(i = v00, j = v11, k = v01)
    )
  }))

  as.data.frame(tris)
}

ggwebgl_surface_wire_indices <- function(nr, nc) {
  index <- function(row, col) {
    as.integer((row - 1L) * nc + col - 1L)
  }

  horizontal <- if (nc > 1L) {
    do.call(c, lapply(seq_len(nr), function(row) {
      unlist(lapply(seq_len(nc - 1L), function(col) {
        c(index(row, col), index(row, col + 1L))
      }), use.names = FALSE)
    }))
  } else {
    integer()
  }

  vertical <- if (nr > 1L) {
    do.call(c, lapply(seq_len(nr - 1L), function(row) {
      unlist(lapply(seq_len(nc), function(col) {
        c(index(row, col), index(row + 1L, col))
      }), use.names = FALSE)
    }))
  } else {
    integer()
  }

  as.integer(c(horizontal, vertical))
}

ggwebgl_resolve_surface_uncertainty <- function(uncertainty, nr, nc, vertex_count) {
  if (is.null(uncertainty)) {
    return(NULL)
  }

  values <- if (is.matrix(uncertainty)) {
    if (!identical(dim(uncertainty), c(nr, nc))) {
      rlang::abort("`uncertainty` matrices must match the surface grid dimensions.")
    }
    as.numeric(t(uncertainty))
  } else {
    as.numeric(ggwebgl_recycle(uncertainty, vertex_count, "uncertainty"))
  }

  if (any(!is.finite(values))) {
    rlang::abort("`uncertainty` must contain finite values.")
  }
  pmax(0, pmin(1, values))
}

ggwebgl_surface_contours <- function(x,
                                     y,
                                     z,
                                     levels = NULL,
                                     colour = "#1f2937",
                                     width = 1) {
  z_range <- range(z, finite = TRUE)
  levels <- levels %||% pretty(z_range, n = 8L)
  levels <- levels[is.finite(levels) & levels >= z_range[[1L]] & levels <= z_range[[2L]]]
  if (!length(levels)) {
    return(NULL)
  }

  contours <- grDevices::contourLines(x = x, y = y, z = t(z), levels = levels)
  if (!length(contours)) {
    return(NULL)
  }

  rgba <- as.numeric(t(colour_to_rgba(colour, 1)))
  lapply(seq_along(contours), function(i) {
    contour <- contours[[i]]
    compact_list(list(
      rows = as.integer(length(contour$x)),
      group = paste0("contour-", i),
      level = unname(as.numeric(contour$level)),
      x = unname(as.numeric(contour$x)),
      y = unname(as.numeric(contour$y)),
      z = rep(as.numeric(contour$level), length(contour$x)),
      width = as.numeric(width)[[1L]],
      age = rep(1, length(contour$x)),
      rgba = rep(rgba, length(contour$x))
    ))
  })
}
