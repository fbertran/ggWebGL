ggwebgl_point_lod_grid <- function(layer, max_points = 5000L, grid_size = 128L) {
  n <- as.integer(layer$rows %||% 0L)
  if (!is.finite(n) || n <= max_points) {
    return(NULL)
  }

  x <- as.numeric(layer$x %||% numeric())
  y <- as.numeric(layer$y %||% numeric())
  if (length(x) < n || length(y) < n) {
    return(NULL)
  }

  ok <- is.finite(x) & is.finite(y)
  if (!any(ok)) {
    return(NULL)
  }

  xr <- normalise_range(range(x[ok], finite = TRUE))
  yr <- normalise_range(range(y[ok], finite = TRUE))
  grid_size <- max(8L, as.integer(grid_size)[[1L]])
  max_points <- max(1L, as.integer(max_points)[[1L]])
  x_bin <- pmax(0L, pmin(grid_size - 1L, floor((x - xr[[1L]]) / diff(xr) * grid_size)))
  y_bin <- pmax(0L, pmin(grid_size - 1L, floor((y - yr[[1L]]) / diff(yr) * grid_size)))
  cell <- ifelse(ok, x_bin + y_bin * grid_size, NA_integer_)
  first <- !duplicated(cell) & !is.na(cell)
  idx <- which(first)
  if (length(idx) > max_points) {
    order_cells <- order(cell[idx], idx)
    idx <- idx[order_cells[seq_len(max_points)]]
  }
  idx <- sort(idx)

  rgba <- layer$rgba %||% numeric()
  rgba_idx <- if (length(rgba) >= n * 4L) {
    as.numeric(matrix(rgba[seq_len(n * 4L)], ncol = 4L, byrow = TRUE)[idx, , drop = FALSE])
  } else {
    NULL
  }

  compact_list(list(
    strategy = "grid",
    rows = as.integer(length(idx)),
    source_rows = n,
    max_points = max_points,
    x = unname(x[idx]),
    y = unname(y[idx]),
    z = if (length(layer$z %||% NULL) >= n) unname(as.numeric(layer$z)[idx]) else NULL,
    size = if (length(layer$size %||% NULL) >= n) unname(as.numeric(layer$size)[idx]) else NULL,
    age = if (length(layer$age %||% NULL) >= n) unname(as.numeric(layer$age)[idx]) else NULL,
    rgba = rgba_idx
  ))
}
