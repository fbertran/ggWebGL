# ggplot-like geom coverage in ggWebGL

This vignette summarizes the `ggplot2`-style layers currently exposed by
`ggWebGL` and shows compact CRAN-safe usage patterns. The examples use
in-memory data only and avoid file output.

The code examples construct `ggplot2`-style WebGL layers and, when
evaluated, convert them into browser-side WebGL htmlwidgets with
[`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md).
Evaluation is disabled during CRAN, package checks, and CI unless
explicitly enabled with `GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` or
`NOT_CRAN=true`.

## Two Workflows

Most users start with a grammar-style plot:

``` r
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point_webgl() +
  geom_line_webgl(aes(group = cyl), alpha = 0.35) +
  theme_webgl(shader = "density_splat")

ggplot_webgl(p, height = 420)
```

The same renderer can also consume a renderer-ready specification. This
is useful when data have already been transformed into primitive
payloads:

``` r
spec <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(mtcars, x = "wt", y = "mpg", colour = "#2563eb")
  ),
  labels = list(title = "Renderer-ready point layer"),
  webgl = webgl_spec(shader = "density_splat")
)

ggWebGL(spec)
```

## Coverage Summary

The table below uses conservative status labels. `Stable` means the API
is part of the core two-dimensional renderer workflow. `Experimental`
means the API is exported and tested, but the rendering contract or
interaction details may still evolve. `Metadata-only` means metadata can
be serialized without implying full runtime parity with every `ggplot2`
feature.

| Family | Public APIs | Status | Notes |
|----|----|----|----|
| Points | [`geom_point_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_point_webgl.md) | Stable | Core scatter and dense point rendering. |
| Lines and paths | [`geom_line_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_line_webgl.md), [`geom_path_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_path_webgl.md), [`geom_path3d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_path3d_webgl.md) | Stable / Experimental | Two-dimensional line/path rendering is core; 3D paths are experimental. |
| Segments and vectors | [`geom_segment_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_segment_webgl.md), [`geom_vector_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_vector_webgl.md) | Stable / Experimental | Segments are plain line segments; vectors add arrow-oriented metadata. |
| Rectangles and tiles | [`geom_rect_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_rect_webgl.md), [`geom_tile_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_tile_webgl.md) | Stable | Uses `ggplot2`-built rectangle bounds. |
| Count and bin geoms | [`geom_bar_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_bar_webgl.md), [`geom_histogram_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_histogram_webgl.md), [`geom_bin2d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_bin2d_webgl.md) | Stable | Counts and bins are computed by `ggplot2`. |
| Curves and contours | [`geom_freqpoly_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_freqpoly_webgl.md), [`geom_density_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_density_webgl.md), [`geom_density2d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_density2d_webgl.md), [`geom_contour_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_contour_webgl.md) | Stable | Rendered as line/path primitives; filled contours are not claimed. |
| Ranges and summaries | [`geom_linerange_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_linerange_webgl.md), [`geom_errorbar_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_errorbar_webgl.md), [`geom_pointrange_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_pointrange_webgl.md), [`geom_crossbar_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_crossbar_webgl.md), [`geom_boxplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_boxplot_webgl.md) | Stable | Uses built summary columns and point/segment/rectangle primitives. |
| Filled regions | [`geom_ribbon_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_ribbon_webgl.md), [`geom_area_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_area_webgl.md), [`geom_polygon_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_polygon_webgl.md), [`geom_violin_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_violin_webgl.md) | Experimental | Filled regions use simple polygon/ribbon-style rendering; complex polygon topology is limited. |
| Raster and grids | [`geom_raster_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_raster_webgl.md) | Stable | Intended for regular raster-like cell displays. |
| Text annotations | [`geom_text_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_text_webgl.md), [`geom_label_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_label_webgl.md), [`geom_rug_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_rug_webgl.md) | Metadata-only / Stable | Text and label layers are overlay metadata, not WebGL glyph rendering; rugs use segment primitives. |
| Meshes and surfaces | [`geom_mesh_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_mesh_webgl.md), [`geom_surface_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_surface_webgl.md) | Experimental | Browser-side WebGL mesh and structured-grid surface rendering. |

## Core 2D Layers

Points, ordered paths, sorted lines, and plain segments cover the most
common two-dimensional display cases.

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
  )

ggplot_webgl(p, height = 420)
```

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
  geom_path_webgl(colour = "#dc2626", linewidth = 1.2)

ggplot_webgl(p, height = 420)
```

## Rectangles, Tiles, and Bins

Rectangle-style geoms use boundaries computed by
[`ggplot2::ggplot_build()`](https://ggplot2.tidyverse.org/reference/ggplot_build.html).
This keeps position adjustments and statistical transformations owned by
`ggplot2`.

``` r
tile_grid <- expand.grid(
  x = seq_len(5),
  y = seq_len(4),
  KEEP.OUT.ATTRS = FALSE
)
tile_grid$value <- with(tile_grid, sin(x / 2) + cos(y / 2))

p <- ggplot(tile_grid, aes(x, y, fill = value)) +
  geom_tile_webgl(alpha = 0.85)
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(mtcars, aes(factor(cyl), fill = factor(am))) +
  geom_bar_webgl(position = "stack")
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(mtcars, aes(mpg)) +
  geom_histogram_webgl(binwidth = 4)
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_bin2d_webgl(bins = 8)
ggplot_webgl(p, height = 420)
```

Explicit rectangle bounds are also supported:

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
  )

ggplot_webgl(p, height = 420)
```

## Curves and Contours

Frequency polygons, density curves, two-dimensional density contours,
and regular contour lines all serialize to line/path primitives. The
statistical work remains with `ggplot2`.

``` r
p <- ggplot(mtcars, aes(mpg, colour = factor(cyl))) +
  geom_freqpoly_webgl(binwidth = 4, linewidth = 1.1)
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(mtcars, aes(mpg, colour = factor(cyl))) +
  geom_density_webgl(linewidth = 1.1)
ggplot_webgl(p, height = 420)
```

[`geom_density2d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_density2d_webgl.md)
uses `ggplot2`’s two-dimensional density statistic, which requires
`MASS` at render time. The chunk is skipped when that optional runtime
dependency is unavailable.

``` r
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_density2d_webgl(linewidth = 0.8)
ggplot_webgl(p, height = 420)
```

Regular contour lines use gridded `z` values:

``` r
volcano_df <- as.data.frame(as.table(volcano))
names(volcano_df) <- c("x", "y", "z")
volcano_df$x <- as.numeric(volcano_df$x)
volcano_df$y <- as.numeric(volcano_df$y)

p <- ggplot(volcano_df, aes(x, y, z = z)) +
  geom_contour_webgl(bins = 8)

ggplot_webgl(p, height = 420)
```

## Ranges and Summaries

Range and summary geoms combine segment, point, and rectangle
primitives.

``` r
summary_df <- data.frame(
  group = factor(c("a", "b", "c")),
  y = c(4.1, 5.3, 6.0),
  ymin = c(3.6, 4.7, 5.4),
  ymax = c(4.8, 6.1, 6.8)
)

p <- ggplot(summary_df, aes(group, y, ymin = ymin, ymax = ymax)) +
  geom_linerange_webgl(linewidth = 1.2) +
  geom_pointrange_webgl(colour = "#2563eb")
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(summary_df, aes(group, y, ymin = ymin, ymax = ymax)) +
  geom_errorbar_webgl(width = 0.25) +
  geom_crossbar_webgl(aes(fill = group), width = 0.45, alpha = 0.55)
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) +
  geom_boxplot_webgl()
ggplot_webgl(p, height = 420)
```

Violin rendering uses `ggplot2`’s built density output:

``` r
p <- ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) +
  geom_violin_webgl(alpha = 0.7)
ggplot_webgl(p, height = 420)
```

## Filled Regions

Ribbon, area, and simple polygon layers are filled-region APIs. They are
useful for compact displays, but complex polygon topology such as holes
or self-intersections should be treated as outside the current core
contract.

``` r
band <- data.frame(
  x = seq(0, 2 * pi, length.out = 80)
)
band$y <- sin(band$x)
band$ymin <- band$y - 0.15
band$ymax <- band$y + 0.15

p <- ggplot(band, aes(x, ymin = ymin, ymax = ymax)) +
  geom_ribbon_webgl(fill = "#93c5fd", alpha = 0.6) +
  geom_line_webgl(aes(y = y), colour = "#1d4ed8")
ggplot_webgl(p, height = 420)
```

``` r
p <- ggplot(band, aes(x, y)) +
  geom_area_webgl(fill = "#a7f3d0", alpha = 0.7)
ggplot_webgl(p, height = 420)
```

``` r
triangle <- data.frame(
  x = c(0, 1, 0.2),
  y = c(0, 0.2, 1),
  group = 1
)

p <- ggplot(triangle, aes(x, y, group = group)) +
  geom_polygon_webgl(fill = "#f97316", alpha = 0.7)
ggplot_webgl(p, height = 420)
```

## Raster and Annotation Layers

Raster layers are intended for regular cell displays. Text and label
layers are overlay metadata, not full WebGL glyph rendering.

``` r
small_raster <- expand.grid(
  x = seq_len(8),
  y = seq_len(6),
  KEEP.OUT.ATTRS = FALSE
)
small_raster$value <- with(small_raster, x * y)

p <- ggplot(small_raster, aes(x, y, fill = value)) +
  geom_raster_webgl()
ggplot_webgl(p, height = 420)
```

``` r
labels <- data.frame(
  x = c(2, 6),
  y = c(2, 5),
  label = c("low", "high")
)

p <- ggplot(small_raster, aes(x, y, fill = value)) +
  geom_tile_webgl(alpha = 0.55) +
  geom_text_webgl(data = labels, aes(x = x, y = y, label = label), inherit.aes = FALSE) +
  geom_rug_webgl(colour = "#334155")
ggplot_webgl(p, height = 420)
```

If label backgrounds are needed,
[`geom_label_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_label_webgl.md)
serializes label metadata for the overlay path:

``` r
p <- ggplot(labels, aes(x, y, label = label)) +
  geom_label_webgl(fill = "#ffffff", colour = "#0f172a")
ggplot_webgl(p, height = 420)
```

## Experimental 3D, Mesh, and Surface Layers

The 3D and indexed-geometry APIs are exported for browser-side WebGL
rendering, but they remain experimental because camera, picking, and
material behavior may still evolve.

``` r
helix_t <- seq(0, 4 * pi, length.out = 80)
helix <- data.frame(
  x = cos(helix_t),
  y = sin(helix_t),
  z = helix_t / max(helix_t),
  time = helix_t,
  group = "helix"
)

p <- ggplot(helix, aes(x, y, z = z, group = group, time = time)) +
  geom_path3d_webgl(colour = "#2563eb") +
  coord_webgl_3d()

ggplot_webgl(p, height = 420)
```

Structured surfaces use a regular grid:

``` r
surface_grid <- expand.grid(
  x = seq(-1, 1, length.out = 12),
  y = seq(-1, 1, length.out = 12),
  KEEP.OUT.ATTRS = FALSE
)
surface_grid$z <- with(surface_grid, exp(-(x^2 + y^2)))

p <- ggplot(surface_grid, aes(x, y, z = z, fill = z)) +
  geom_surface_webgl(shading = "surface_height_colormap") +
  coord_webgl_3d()

ggplot_webgl(p, height = 420)
```

Unstructured meshes can be supplied with explicit vertices and triangle
indices:

``` r
mesh_vertices <- data.frame(
  x = c(0, 1, 0, 0),
  y = c(0, 0, 1, 0),
  z = c(0, 0, 0, 1),
  scalar = c(0, 1, 1, 0.5),
  i = c(1, 1, 1, 2),
  j = c(2, 2, 3, 3),
  k = c(3, 4, 4, 4)
)

p <- ggplot(mesh_vertices, aes(x, y, z = z, i = i, j = j, k = k, scalar = scalar)) +
  geom_mesh_webgl(shading = "mesh_scalar_colormap") +
  coord_webgl_3d()

ggplot_webgl(p, height = 420)
```

## Facets, Coordinates, and Fallbacks

Fixed-scale facets are supported across the primitive families.
Free-scale facets are serialized conservatively as metadata unless
panel-local scaling is available for the layer combination being
rendered.

``` r
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point_webgl() +
  facet_wrap(~am)

ggplot_webgl(p, height = 420)
```

Unsupported geoms remain visible to the extraction layer as unsupported
metadata rather than being silently claimed as WebGL primitives. When a
plot needs exact `ggplot2` parity for an unsupported layer, keep that
layer in a static ggplot or replace it with one of the supported WebGL
primitives above.
