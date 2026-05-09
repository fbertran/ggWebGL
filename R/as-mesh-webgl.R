#' Convert Explicit Mesh Data to a ggWebGL Mesh Object
#'
#' `as_mesh_webgl()` converts CRAN-safe explicit mesh inputs into a lightweight
#' helper object accepted by [ggwebgl_layer_mesh()]. Core ggWebGL does not
#' convert external mesh package classes in this milestone.
#'
#' @param x Object to convert. Supported inputs are `ggwebgl_mesh` objects,
#'   lists with `vertices` and `triangles`, and data frames containing explicit
#'   `x`, `y`, `z`, `i`, `j`, and `k` columns.
#' @param ... Additional arguments passed to [ggwebgl_mesh()].
#'
#' @return A `ggwebgl_mesh` object.
#'
#' @examples
#' vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0))
#' triangles <- data.frame(i = 1L, j = 2L, k = 3L)
#' as_mesh_webgl(list(vertices = vertices, triangles = triangles))
#' @export
as_mesh_webgl <- function(x, ...) {
  UseMethod("as_mesh_webgl")
}

#' @export
as_mesh_webgl.ggwebgl_mesh <- function(x, ...) {
  x
}

#' @export
as_mesh_webgl.default <- function(x, ...) {
  if (is.list(x) && !is.null(x$vertices) && !is.null(x$triangles)) {
    return(ggwebgl_mesh(x$vertices, x$triangles, ...))
  }

  rlang::abort(
    "`as_mesh_webgl()` supports explicit `vertices` and `triangles` tables only; external mesh package adapters are future optional integrations."
  )
}

#' @export
as_mesh_webgl.data.frame <- function(x, ...) {
  required <- c("x", "y", "z", "i", "j", "k")
  if (!all(required %in% names(x))) {
    rlang::abort("Mesh data frames must include `x`, `y`, `z`, `i`, `j`, and `k` columns.")
  }

  triangles <- x[stats::complete.cases(x[, c("i", "j", "k"), drop = FALSE]), , drop = FALSE]
  ggwebgl_mesh(x, triangles, ...)
}

#' Build a ggWebGL Mesh Helper Object
#'
#' Build a lightweight unstructured mesh object from explicit vertex and
#' triangle tables.
#'
#' @param vertices Data frame with vertex coordinates.
#' @param triangles Data frame with one-based triangle indices.
#' @param x,y,z Vertex coordinate column names.
#' @param i,j,k Triangle index column names.
#' @param scalar Optional scalar column name or vector for per-vertex scalar
#'   colouring.
#' @param id Optional vertex id column name or vector.
#' @param normals Optional normal matrix/data frame/vector or column triplet
#'   named `nx`, `ny`, `nz` in `vertices`.
#' @param colour,rgba,alpha Optional vertex colour inputs passed through to
#'   [ggwebgl_layer_mesh()].
#' @param pick_id Optional face picking ids.
#'
#' @return A `ggwebgl_mesh` object.
#'
#' @examples
#' vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0))
#' triangles <- data.frame(i = 1L, j = 2L, k = 3L)
#' ggwebgl_mesh(vertices, triangles)
#' @export
ggwebgl_mesh <- function(vertices,
                         triangles,
                         x = "x",
                         y = "y",
                         z = "z",
                         i = "i",
                         j = "j",
                         k = "k",
                         scalar = NULL,
                         id = NULL,
                         normals = NULL,
                         colour = NULL,
                         rgba = NULL,
                         alpha = NULL,
                         pick_id = NULL) {
  vertices <- as.data.frame(vertices, stringsAsFactors = FALSE)
  triangles <- as.data.frame(triangles, stringsAsFactors = FALSE)
  ggwebgl_validate_mesh_tables(vertices, triangles, x = x, y = y, z = z, i = i, j = j, k = k)

  if (is.null(normals) && all(c("nx", "ny", "nz") %in% names(vertices))) {
    normals <- as.matrix(vertices[, c("nx", "ny", "nz"), drop = FALSE])
  }

  structure(
    list(
      vertices = vertices,
      triangles = triangles,
      x = x,
      y = y,
      z = z,
      i = i,
      j = j,
      k = k,
      scalar = scalar %||% if ("scalar" %in% names(vertices)) "scalar" else NULL,
      id = id %||% if ("id" %in% names(vertices)) "id" else NULL,
      normals = normals,
      colour = colour %||% if ("colour" %in% names(vertices)) "colour" else NULL,
      rgba = rgba,
      alpha = alpha %||% if ("alpha" %in% names(vertices)) "alpha" else NULL,
      pick_id = pick_id %||% if ("pick_id" %in% names(triangles)) "pick_id" else NULL
    ),
    class = c("ggwebgl_mesh", "list")
  )
}
