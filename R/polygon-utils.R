ggwebgl_polygon_eps <- function() {
  1e-10
}

ggwebgl_polygon_signed_area <- function(x, y) {
  n <- length(x)
  j <- c(seq.int(2L, n), 1L)
  sum(x * y[j] - x[j] * y) / 2
}

ggwebgl_polygon_cross <- function(a, b, c) {
  (b[[1L]] - a[[1L]]) * (c[[2L]] - a[[2L]]) -
    (b[[2L]] - a[[2L]]) * (c[[1L]] - a[[1L]])
}

ggwebgl_polygon_on_segment <- function(a, p, b, eps = ggwebgl_polygon_eps()) {
  abs(ggwebgl_polygon_cross(a, b, p)) <= eps &&
    p[[1L]] >= min(a[[1L]], b[[1L]]) - eps &&
    p[[1L]] <= max(a[[1L]], b[[1L]]) + eps &&
    p[[2L]] >= min(a[[2L]], b[[2L]]) - eps &&
    p[[2L]] <= max(a[[2L]], b[[2L]]) + eps
}

ggwebgl_polygon_segments_intersect <- function(a, b, c, d, eps = ggwebgl_polygon_eps()) {
  o1 <- ggwebgl_polygon_cross(a, b, c)
  o2 <- ggwebgl_polygon_cross(a, b, d)
  o3 <- ggwebgl_polygon_cross(c, d, a)
  o4 <- ggwebgl_polygon_cross(c, d, b)

  proper_ab <- (o1 > eps && o2 < -eps) || (o1 < -eps && o2 > eps)
  proper_cd <- (o3 > eps && o4 < -eps) || (o3 < -eps && o4 > eps)
  if (proper_ab && proper_cd) {
    return(TRUE)
  }

  (abs(o1) <= eps && ggwebgl_polygon_on_segment(a, c, b, eps)) ||
    (abs(o2) <= eps && ggwebgl_polygon_on_segment(a, d, b, eps)) ||
    (abs(o3) <= eps && ggwebgl_polygon_on_segment(c, a, d, eps)) ||
    (abs(o4) <= eps && ggwebgl_polygon_on_segment(c, b, d, eps))
}

ggwebgl_polygon_has_self_intersection <- function(x, y) {
  n <- length(x)
  if (n < 4L) {
    return(FALSE)
  }

  points <- Map(c, x, y)
  for (i in seq_len(n)) {
    i2 <- if (i == n) 1L else i + 1L
    if (i == n) {
      next
    }
    for (j in seq.int(i + 1L, n)) {
      j2 <- if (j == n) 1L else j + 1L
      adjacent <- i == j || i2 == j || j2 == i
      if (adjacent) {
        next
      }
      if (ggwebgl_polygon_segments_intersect(points[[i]], points[[i2]], points[[j]], points[[j2]])) {
        return(TRUE)
      }
    }
  }

  FALSE
}

ggwebgl_polygon_point_in_triangle <- function(p, a, b, c, eps = ggwebgl_polygon_eps()) {
  ggwebgl_polygon_cross(a, b, p) >= -eps &&
    ggwebgl_polygon_cross(b, c, p) >= -eps &&
    ggwebgl_polygon_cross(c, a, p) >= -eps
}

ggwebgl_polygon_prepare_ring <- function(data) {
  x <- as.numeric(data$x)
  y <- as.numeric(data$y)

  if (any(!is.finite(x) | !is.finite(y))) {
    rlang::abort("`geom_polygon_webgl()` supports finite simple polygon coordinates only.")
  }

  if (length(x) > 1L && identical(c(x[[1L]], y[[1L]]), c(x[[length(x)]], y[[length(y)]]))) {
    data <- data[-nrow(data), , drop = FALSE]
    x <- x[-length(x)]
    y <- y[-length(y)]
  }

  if (length(x) < 3L || nrow(unique(data.frame(x = x, y = y))) < 3L) {
    rlang::abort("`geom_polygon_webgl()` requires at least three unique vertices per simple polygon.")
  }

  if (ggwebgl_polygon_has_self_intersection(x, y)) {
    rlang::abort("`geom_polygon_webgl()` does not support self-intersecting polygons.")
  }

  if (abs(ggwebgl_polygon_signed_area(x, y)) <= ggwebgl_polygon_eps()) {
    rlang::abort("`geom_polygon_webgl()` requires simple polygons with non-zero area.")
  }

  data
}

ggwebgl_polygon_triangulate_ring <- function(x, y) {
  x <- as.numeric(x)
  y <- as.numeric(y)
  n <- length(x)
  active <- seq_len(n)
  if (ggwebgl_polygon_signed_area(x, y) < 0) {
    active <- rev(active)
  }

  triangles <- list()
  guard <- 0L
  while (length(active) > 3L) {
    guard <- guard + 1L
    if (guard > n * n) {
      rlang::abort("`geom_polygon_webgl()` could not triangulate this simple polygon.")
    }

    ear_found <- FALSE
    m <- length(active)
    for (pos in seq_len(m)) {
      prev <- active[[if (pos == 1L) m else pos - 1L]]
      curr <- active[[pos]]
      nxt <- active[[if (pos == m) 1L else pos + 1L]]
      a <- c(x[[prev]], y[[prev]])
      b <- c(x[[curr]], y[[curr]])
      c <- c(x[[nxt]], y[[nxt]])

      if (ggwebgl_polygon_cross(a, b, c) <= ggwebgl_polygon_eps()) {
        next
      }

      other <- setdiff(active, c(prev, curr, nxt))
      contains_point <- any(vapply(other, function(idx) {
        ggwebgl_polygon_point_in_triangle(c(x[[idx]], y[[idx]]), a, b, c)
      }, logical(1)))
      if (contains_point) {
        next
      }

      triangles[[length(triangles) + 1L]] <- c(prev, curr, nxt)
      active <- active[-pos]
      ear_found <- TRUE
      break
    }

    if (!ear_found) {
      rlang::abort("`geom_polygon_webgl()` could not triangulate this simple polygon.")
    }
  }

  triangles[[length(triangles) + 1L]] <- active
  triangles <- do.call(rbind, triangles)
  data.frame(
    i = as.integer(triangles[, 1L]),
    j = as.integer(triangles[, 2L]),
    k = as.integer(triangles[, 3L])
  )
}
