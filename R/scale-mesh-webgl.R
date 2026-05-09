ggwebgl_mesh_scalar_range <- function(scalar) {
  if (is.null(scalar)) {
    return(NULL)
  }

  values <- as.numeric(scalar)
  if (!length(values) || any(!is.finite(values))) {
    rlang::abort("Mesh `scalar` values must be finite numeric values.")
  }

  range(values, finite = TRUE)
}

ggwebgl_resolve_mesh_scalar <- function(scalar, n, fallback = NULL) {
  if (is.null(scalar)) {
    scalar <- fallback
  }
  if (is.null(scalar)) {
    return(NULL)
  }

  values <- as.numeric(ggwebgl_recycle(scalar, n, "scalar"))
  if (any(!is.finite(values))) {
    rlang::abort("Mesh `scalar` values must be finite numeric values.")
  }

  values
}
