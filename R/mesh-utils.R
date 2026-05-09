normalise_mesh_shading <- function(shading = NULL) {
  shading <- as.character(shading %||% "mesh_lambert")[[1L]]
  shading <- tolower(shading)
  aliases <- c(
    flat = "mesh_flat",
    lambert = "mesh_lambert",
    phong = "mesh_phong_simple",
    scalar = "mesh_scalar_colormap",
    selected = "mesh_selection_highlight",
    mesh_flat = "mesh_flat",
    mesh_lambert = "mesh_lambert",
    mesh_phong_simple = "mesh_phong_simple",
    mesh_scalar_colormap = "mesh_scalar_colormap",
    mesh_selection_highlight = "mesh_selection_highlight"
  )

  if (!shading %in% names(aliases)) {
    rlang::abort("Unknown mesh shading mode.")
  }
  unname(aliases[[shading]])
}

normalise_mesh_material <- function(material = NULL, wireframe = NULL, shading = NULL) {
  if (inherits(material, "ggwebgl_material")) {
    material <- unclass(material)
  }
  if (!is.list(material)) {
    material <- list()
  }
  material$shading <- normalise_mesh_shading(shading %||% material[["shading"]] %||% "mesh_lambert")
  material$ambient <- as.numeric(material[["ambient"]] %||% 0.35)[[1L]]
  material$diffuse <- as.numeric(material[["diffuse"]] %||% 0.75)[[1L]]
  material$specular <- as.numeric(material[["specular"]] %||% 0.25)[[1L]]
  material$light_dir <- normalise_vector3(material[["light_dir"]], c(0.35, 0.45, 0.82), "light_dir")
  material$wireframe <- isTRUE(wireframe %||% material[["wireframe"]] %||% FALSE)
  material$cull <- tolower(as.character(material[["cull"]] %||% "back")[[1L]])
  if (!material$cull %in% c("back", "none")) {
    material$cull <- "back"
  }
  material
}

ggwebgl_validate_mesh_tables <- function(vertices,
                                         triangles,
                                         x = "x",
                                         y = "y",
                                         z = "z",
                                         i = "i",
                                         j = "j",
                                         k = "k") {
  if (!is.data.frame(vertices) || !nrow(vertices)) {
    rlang::abort("Mesh `vertices` must be a non-empty data frame.")
  }
  if (!is.data.frame(triangles) || !nrow(triangles)) {
    rlang::abort("Mesh `triangles` must be a non-empty data frame.")
  }

  vertex_columns <- c(x, y, z)
  triangle_columns <- c(i, j, k)
  if (!all(vertex_columns %in% names(vertices))) {
    rlang::abort("Mesh vertices must include `x`, `y`, and `z` coordinate columns.")
  }
  if (!all(triangle_columns %in% names(triangles))) {
    rlang::abort("Mesh triangles must include `i`, `j`, and `k` index columns.")
  }

  coords <- as.matrix(vertices[, vertex_columns, drop = FALSE])
  storage.mode(coords) <- "double"
  if (any(!is.finite(coords))) {
    rlang::abort("Mesh vertex coordinates must be finite.")
  }

  raw_indices <- as.numeric(c(rbind(triangles[[i]], triangles[[j]], triangles[[k]])))
  if (any(!is.finite(raw_indices)) || any(is.na(raw_indices)) || any(raw_indices != floor(raw_indices))) {
    rlang::abort("Mesh triangle indices must be finite one-based integers.")
  }
  indices <- as.integer(raw_indices)
  if (any(indices < 1L | indices > nrow(vertices))) {
    rlang::abort("Mesh triangle indices must refer to existing vertices.")
  }

  invisible(TRUE)
}

ggwebgl_resolve_pick_id <- function(pick_id, triangle_count) {
  if (is.null(pick_id)) {
    return(NULL)
  }
  pick_id <- as.character(ggwebgl_recycle(pick_id, triangle_count, "pick_id"))
  pick_id[is.na(pick_id)] <- ""
  pick_id
}

ggwebgl_resolve_normals <- function(normals, xs, ys, zs, indices) {
  n <- length(xs)
  if (is.null(normals) || identical(normals, "auto")) {
    return(ggwebgl_mesh_normals(xs, ys, zs, indices))
  }

  values <- as.numeric(normals)
  if (is.matrix(normals) || is.data.frame(normals)) {
    matrix_values <- as.matrix(normals)
    if (ncol(matrix_values) != 3L || nrow(matrix_values) != n) {
      rlang::abort("`normals` must have three columns and one row per vertex.")
    }
    out <- matrix(as.numeric(matrix_values), ncol = 3L)
  } else {
    if (length(values) != n * 3L) {
      rlang::abort("`normals` must have length `vertex_count * 3`.")
    }
    out <- matrix(values, ncol = 3L, byrow = TRUE)
  }

  ggwebgl_normalise_normal_matrix(out)
}

ggwebgl_normalise_normal_matrix <- function(normals) {
  normals <- as.matrix(normals)
  storage.mode(normals) <- "double"
  norms <- sqrt(rowSums(normals^2))
  bad <- !is.finite(norms) | norms <= 0
  norms[bad] <- 1
  normals <- normals / norms
  if (any(bad)) {
    normals[bad, ] <- matrix(c(0, 0, 1), nrow = sum(bad), ncol = 3L, byrow = TRUE)
  }
  normals
}

ggwebgl_mesh_normals <- function(xs, ys, zs, indices) {
  n <- length(xs)
  normals <- matrix(0, nrow = n, ncol = 3L)
  for (offset in seq(1L, length(indices), by = 3L)) {
    tri <- indices[offset + 0:2]
    if (length(tri) != 3L || any(!is.finite(tri)) || any(tri < 1L | tri > n)) {
      next
    }
    p1 <- c(xs[tri[[1L]]], ys[tri[[1L]]], zs[tri[[1L]]])
    p2 <- c(xs[tri[[2L]]], ys[tri[[2L]]], zs[tri[[2L]]])
    p3 <- c(xs[tri[[3L]]], ys[tri[[3L]]], zs[tri[[3L]]])
    normal <- c(
      (p2[[2L]] - p1[[2L]]) * (p3[[3L]] - p1[[3L]]) - (p2[[3L]] - p1[[3L]]) * (p3[[2L]] - p1[[2L]]),
      (p2[[3L]] - p1[[3L]]) * (p3[[1L]] - p1[[1L]]) - (p2[[1L]] - p1[[1L]]) * (p3[[3L]] - p1[[3L]]),
      (p2[[1L]] - p1[[1L]]) * (p3[[2L]] - p1[[2L]]) - (p2[[2L]] - p1[[2L]]) * (p3[[1L]] - p1[[1L]])
    )
    normals[tri, ] <- normals[tri, , drop = FALSE] + matrix(normal, nrow = 3L, ncol = 3L, byrow = TRUE)
  }
  ggwebgl_normalise_normal_matrix(normals)
}

ggwebgl_mesh_wire_indices <- function(indices) {
  triangles <- matrix(as.integer(indices), ncol = 3L, byrow = TRUE)
  if (!nrow(triangles)) {
    return(integer())
  }
  edges <- rbind(
    triangles[, c(1L, 2L), drop = FALSE],
    triangles[, c(2L, 3L), drop = FALSE],
    triangles[, c(3L, 1L), drop = FALSE]
  )
  edges <- t(apply(edges, 1L, sort))
  edges <- unique(edges)
  as.integer(c(t(edges - 1L)))
}

#' Renderer-Ready Mesh Layer
#'
#' Build an indexed triangle mesh layer for downstream adapters.
#' Triangle indices are supplied as one-based R indices and normalized to
#' zero-based WebGL indices in the returned payload.
#'
#' @inheritParams ggwebgl_layer_points
#' @param vertices Data frame, `ggwebgl_mesh` object, or list accepted by
#'   [as_mesh_webgl()].
#' @param z Optional z coordinate vector or column name. Defaults to zero.
#' @param triangles Optional data frame supplying triangle index columns.
#' @param i,j,k One-based triangle index vectors or column names.
#' @param scalar Optional per-vertex scalar vector or column name.
#' @param normals Optional vertex-normal matrix/data frame/vector or `"auto"`.
#' @param material Mesh material created by [ggwebgl_material()].
#' @param shading Optional mesh shader mode overriding `material$shading`.
#' @param pick_id Optional face picking ids. Length must be one or the number of
#'   triangles.
#' @param wireframe Legacy shortcut for `material$wireframe`.
#'
#' @return A normalized mesh layer list.
#'
#' @examples
#' vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0))
#' triangles <- data.frame(i = 1L, j = 2L, k = 3L)
#' ggwebgl_layer_mesh(vertices, x = "x", y = "y", z = "z", triangles = triangles)
#' @export
ggwebgl_layer_mesh <- function(vertices,
                               x = NULL,
                               y = NULL,
                               z = NULL,
                               triangles = NULL,
                               i = NULL,
                               j = NULL,
                               k = NULL,
                               colour = NULL,
                               rgba = NULL,
                               alpha = NULL,
                               id = NULL,
                               scalar = NULL,
                               normals = NULL,
                               material = ggwebgl_material(),
                               shading = NULL,
                               pick_id = NULL,
                               panel_id = 1L,
                               geom = "adapter_mesh",
                               wireframe = NULL) {
  if (inherits(vertices, "ggwebgl_mesh") ||
      (is.list(vertices) && !is.data.frame(vertices) && !is.null(vertices$vertices) && !is.null(vertices$triangles))) {
    mesh <- as_mesh_webgl(vertices)
    return(ggwebgl_layer_mesh(
      vertices = mesh$vertices,
      x = mesh$x,
      y = mesh$y,
      z = mesh$z,
      triangles = mesh$triangles,
      i = mesh$i,
      j = mesh$j,
      k = mesh$k,
      colour = colour %||% mesh$colour,
      rgba = rgba %||% mesh$rgba,
      alpha = alpha %||% mesh$alpha,
      id = id %||% mesh$id,
      scalar = scalar %||% mesh$scalar,
      normals = normals %||% mesh$normals,
      material = material,
      shading = shading,
      pick_id = pick_id %||% mesh$pick_id,
      panel_id = panel_id,
      geom = geom,
      wireframe = wireframe
    ))
  }

  vertices <- ggwebgl_adapter_data(vertices)
  env <- parent.frame()
  xs <- ggwebgl_resolve_arg(vertices, substitute(x), env, "x", required = TRUE)
  ys <- ggwebgl_resolve_arg(vertices, substitute(y), env, "y", required = TRUE)
  zs <- ggwebgl_resolve_arg(vertices, substitute(z), env, "z", default = NULL)
  n <- ggwebgl_common_length(x = xs, y = ys)

  xs <- ggwebgl_recycle(xs, n, "x")
  ys <- ggwebgl_recycle(ys, n, "y")
  zs <- ggwebgl_recycle(zs %||% 0, n, "z")

  colour_values <- ggwebgl_resolve_arg(vertices, substitute(colour), env, "colour", default = NULL)
  rgba_values <- ggwebgl_resolve_arg(vertices, substitute(rgba), env, "rgba", default = NULL)
  alpha_values <- ggwebgl_resolve_arg(vertices, substitute(alpha), env, "alpha", default = NULL)
  id_values <- ggwebgl_resolve_arg(vertices, substitute(id), env, "id", default = NULL)
  scalar_values <- ggwebgl_resolve_arg(vertices, substitute(scalar), env, "scalar", default = NULL)
  if (is.null(scalar_values) && "scalar" %in% names(vertices)) {
    scalar_values <- vertices$scalar
  }

  material <- normalise_mesh_material(material, wireframe = wireframe, shading = shading)
  scalar_values <- ggwebgl_resolve_mesh_scalar(
    scalar_values,
    n,
    fallback = if (identical(material$shading, "mesh_scalar_colormap")) zs else NULL
  )
  rgba_matrix <- ggwebgl_resolve_rgba(rgba_values, colour_values, alpha_values, n)
  id_values <- if (is.null(id_values)) NULL else as.character(ggwebgl_recycle(id_values, n, "id"))

  if (is.null(triangles)) {
    triangles <- vertices
  } else {
    triangles <- ggwebgl_adapter_data(triangles)
  }

  tri_env <- parent.frame()
  ii <- ggwebgl_resolve_arg(triangles, substitute(i), tri_env, "i", default = NULL)
  jj <- ggwebgl_resolve_arg(triangles, substitute(j), tri_env, "j", default = NULL)
  kk <- ggwebgl_resolve_arg(triangles, substitute(k), tri_env, "k", default = NULL)
  if (is.null(ii) && all(c("i", "j", "k") %in% names(triangles))) {
    ii <- triangles$i
    jj <- triangles$j
    kk <- triangles$k
  }
  if (is.null(ii) || is.null(jj) || is.null(kk)) {
    rlang::abort("Mesh layers require triangle indices `i`, `j`, and `k`.")
  }

  m <- ggwebgl_common_length(i = ii, j = jj, k = kk)
  raw_indices <- as.numeric(c(rbind(
    ggwebgl_recycle(ii, m, "i"),
    ggwebgl_recycle(jj, m, "j"),
    ggwebgl_recycle(kk, m, "k")
  )))
  if (any(!is.finite(raw_indices)) || any(is.na(raw_indices)) || any(raw_indices != floor(raw_indices))) {
    rlang::abort("Mesh triangle indices must be finite one-based integers.")
  }
  indices <- as.integer(raw_indices)
  keep <- is.finite(indices)
  if (!all(keep)) {
    indices <- indices[keep]
  }
  if (length(indices) %% 3L != 0L || !length(indices)) {
    rlang::abort("Mesh triangle indices must form complete triangles.")
  }
  if (any(indices < 1L | indices > n)) {
    rlang::abort("Mesh triangle indices must refer to existing vertices.")
  }
  triangle_count <- as.integer(length(indices) / 3L)
  normals_matrix <- ggwebgl_resolve_normals(normals, xs, ys, zs, indices)
  pick_values <- ggwebgl_resolve_arg(triangles, substitute(pick_id), tri_env, "pick_id", default = NULL)
  if (is.null(pick_values) && "pick_id" %in% names(triangles)) {
    pick_values <- triangles$pick_id
  }
  pick_values <- ggwebgl_resolve_pick_id(pick_values, triangle_count)

  compact_list(list(
    panel_id = ggwebgl_panel_id(panel_id),
    type = "mesh",
    geom = as.character(geom)[[1L]],
    rows = triangle_count,
    vertex_count = as.integer(n),
    triangle_count = triangle_count,
    x = unname(as.numeric(xs)),
    y = unname(as.numeric(ys)),
    z = unname(as.numeric(zs)),
    indices = unname(as.integer(indices - 1L)),
    wire_indices = unname(ggwebgl_mesh_wire_indices(indices)),
    id = unname(id_values),
    scalar = unname(scalar_values),
    scalar_range = unname(ggwebgl_mesh_scalar_range(scalar_values)),
    normal = unname(as.numeric(t(normals_matrix))),
    rgba = unname(as.numeric(t(rgba_matrix))),
    material = material,
    pick_id = unname(pick_values),
    wireframe = isTRUE(material$wireframe),
    bbox3d = list(
      xmin = min(as.numeric(xs)),
      xmax = max(as.numeric(xs)),
      ymin = min(as.numeric(ys)),
      ymax = max(as.numeric(ys)),
      zmin = min(as.numeric(zs)),
      zmax = max(as.numeric(zs))
    )
  ))
}
