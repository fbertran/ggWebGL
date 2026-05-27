# Core ggplot-like WebGL layers

This vignette covers the core two-dimensional `ggplot2`-style layers and
the renderer-ready specification workflow. The code examples construct
`ggplot2`-style WebGL layers and, when evaluated, convert them into
browser-side WebGL htmlwidgets with
[`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md)
or
[`ggWebGL()`](https://fbertran.github.io/ggWebGL/reference/ggWebGL.md).

Evaluation is disabled during CRAN, package checks, and CI unless
explicitly enabled with `GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` or
`NOT_CRAN=true`.

## Two Workflows

### Applet: Grammar-style points and lines

``` r
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point_webgl() +
  geom_line_webgl(aes(group = cyl), alpha = 0.35) +
  labs(title = "Grammar-style points and lines") +
  theme_webgl(shader = "density_splat")

ggplot_webgl(p, height = 420)
```

### Applet: Renderer-ready point specification

Renderer-ready specifications are useful when data have already been
transformed into primitive payloads.

``` r
spec <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(mtcars, x = "wt", y = "mpg", colour = "#2563eb")
  ),
  labels = list(title = "Renderer-ready point specification"),
  webgl = webgl_spec(shader = "density_splat")
)

ggWebGL(spec)
```

## Coverage Summary

| Family | Public APIs | Status | Notes |
|----|----|----|----|
| Points | [`geom_point_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_point_webgl.md) | Stable | Core scatter and dense point rendering. |
| Lines and paths | [`geom_line_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_line_webgl.md), [`geom_path_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_path_webgl.md), [`geom_path3d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_path3d_webgl.md) | Stable / Experimental | Two-dimensional line/path rendering is core; 3D paths are experimental. |
| Segments and vectors | [`geom_segment_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_segment_webgl.md), [`geom_vector_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_vector_webgl.md) | Stable / Experimental | Segments are plain line segments; vectors add arrow-oriented metadata. |
| Rectangles and tiles | [`geom_rect_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_rect_webgl.md), [`geom_tile_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_tile_webgl.md) | Stable | Uses `ggplot2`-built rectangle bounds. |
| Count and bin geoms | [`geom_bar_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_bar_webgl.md), [`geom_histogram_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_histogram_webgl.md), [`geom_bin2d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_bin2d_webgl.md) | Experimental | Counts and bins are computed by `ggplot2`; WebGL serialization is newer than core point/line/raster paths. |
| Curves and contours | [`geom_freqpoly_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_freqpoly_webgl.md), [`geom_density_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_density_webgl.md), [`geom_density2d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_density2d_webgl.md), [`geom_contour_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_contour_webgl.md) | Experimental | Rendered as line/path primitives; see the statistical coverage vignette. |

Status labels reflect API maturity, test coverage, and
rendering-contract stability; they are not simply an export list.

## Core 2D Layers

### Applet: Ordered 2D path with segments

``` r
trajectory <- data.frame(
  x = cos(seq(0, 2 * pi, length.out = 48)) * seq(0.2, 1, length.out = 48),
  y = sin(seq(0, 2 * pi, length.out = 48)) * seq(0.2, 1, length.out = 48),
  frame = seq_len(48),
  group = "spiral"
)

arrows <- data.frame(
  x = c(-0.8, -0.2, 0.4),
  y = c(-0.6, 0.1, 0.5),
  xend = c(-0.45, 0.15, 0.75),
  yend = c(-0.25, 0.35, 0.2)
)

p <- ggplot(trajectory, aes(x, y, group = group)) +
  geom_path_webgl(aes(frame = frame), colour = "#2563eb", linewidth = 1.2) +
  geom_point_webgl(aes(frame = frame), colour = "#0f766e", size = 1.8) +
  geom_segment_webgl(
    data = arrows,
    aes(x = x, y = y, xend = xend, yend = yend),
    inherit.aes = FALSE,
    colour = "#334155"
  ) +
  labs(title = "Ordered 2D path with segments")

ggplot_webgl(p, height = 420)
```

### Applet: Line sorting versus path order

[`geom_line_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_line_webgl.md)
keeps the usual line semantics, while
[`geom_path_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_path_webgl.md)
preserves row order within groups.

``` r
ordered <- data.frame(
  x = c(3, 1, 2, 4),
  y = c(1, 3, 2, 4),
  group = "ordered"
)

p <- ggplot(ordered, aes(x, y, group = group)) +
  geom_line_webgl(colour = "#64748b") +
  geom_path_webgl(colour = "#dc2626", linewidth = 1.2) +
  labs(title = "Line sorting versus path order")

ggplot_webgl(p, height = 420)
```

## Rectangles, Tiles, and Bins

Rectangle-style geoms use boundaries computed by
[`ggplot2::ggplot_build()`](https://ggplot2.tidyverse.org/reference/ggplot_build.html).
This keeps position adjustments and statistical transformations owned by
`ggplot2`.

### Applet: Tile grid

``` r
tile_grid <- expand.grid(
  x = seq_len(5),
  y = seq_len(4),
  KEEP.OUT.ATTRS = FALSE
)
tile_grid$value <- with(tile_grid, sin(x / 2) + cos(y / 2))

p <- ggplot(tile_grid, aes(x, y, fill = value)) +
  geom_tile_webgl(alpha = 0.85) +
  labs(title = "Tile grid")
ggplot_webgl(p, height = 420)
```

### Applet: Stacked bar counts

``` r
p <- ggplot(mtcars, aes(factor(cyl), fill = factor(am))) +
  geom_bar_webgl(position = "stack") +
  labs(title = "Stacked bar counts")
ggplot_webgl(p, height = 420)
```

### Applet: Histogram bins

``` r
p <- ggplot(mtcars, aes(mpg)) +
  geom_histogram_webgl(binwidth = 4) +
  labs(title = "Histogram bins")
ggplot_webgl(p, height = 420)
```

### Applet: Two-dimensional bins

``` r
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_bin2d_webgl(bins = 8) +
  labs(title = "Two-dimensional bins")
ggplot_webgl(p, height = 420)
```

### Applet: Explicit rectangles

``` r
rectangles <- data.frame(
  xmin = c(0.0, 1.2),
  xmax = c(1.0, 2.0),
  ymin = c(0.0, 0.4),
  ymax = c(0.8, 1.4),
  label = c("a", "b")
)

p <- ggplot(rectangles) +
  geom_rect_webgl(
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = label),
    alpha = 0.75
  ) +
  labs(title = "Explicit rectangles")

ggplot_webgl(p, height = 420)
```

## Curves and Contours

Curve and contour applets are in
[`vignette("ggplot-coverage-summaries", package = "ggWebGL")`](https://fbertran.github.io/ggWebGL/articles/ggplot-coverage-summaries.md)
so this page keeps its live widget count moderate.
