# Statistical and annotation WebGL layers

This vignette covers statistical summaries, curve/contour layers, filled
regions, raster grids, annotations, and fixed-scale facets. Evaluation
is disabled during CRAN, package checks, and CI unless explicitly
enabled with `GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` or `NOT_CRAN=true`.
Live WebGL widgets are additionally disabled unless
`GGWEBGL_EVAL_LIVE_WIDGETS=true` is set; rich local or pkgdown builds
should set both `GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` and
`GGWEBGL_EVAL_LIVE_WIDGETS=true`.

## Curves and Contours

Frequency polygons, density curves, two-dimensional density contours,
and regular contour lines all serialize to line/path primitives. The
statistical work remains with `ggplot2`.

### Applet: Frequency polygons

``` r
p <- ggplot(mtcars, aes(mpg, colour = factor(cyl))) +
  geom_freqpoly_webgl(binwidth = 4, linewidth = 1.1) +
  labs(title = "Frequency polygons")
ggplot_webgl(p, height = 420)
```

### Applet: Density curves

``` r
p <- ggplot(mtcars, aes(mpg, colour = factor(cyl))) +
  geom_density_webgl(linewidth = 1.1) +
  labs(title = "Density curves")
ggplot_webgl(p, height = 420)
```

### Code-only: Two-dimensional density contours

[`geom_density2d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_density2d_webgl.md)
uses `ggplot2`’s two-dimensional density statistic, which requires
`MASS` at render time. The chunk is skipped when that optional runtime
dependency is unavailable.

``` r
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_density2d_webgl(linewidth = 0.8) +
  labs(title = "Two-dimensional density contours")
ggplot_webgl(p, height = 420)
```

### Code-only: Gridded contour lines

``` r
volcano_df <- as.data.frame(as.table(volcano))
names(volcano_df) <- c("x", "y", "z")
volcano_df$x <- as.numeric(volcano_df$x)
volcano_df$y <- as.numeric(volcano_df$y)

p <- ggplot(volcano_df, aes(x, y, z = z)) +
  geom_contour_webgl(bins = 8) +
  labs(title = "Gridded contour lines")

ggplot_webgl(p, height = 420)
```

## Ranges and Summaries

Range and summary geoms combine segment, point, and rectangle
primitives.

### Applet: Linerange and pointrange

``` r
summary_df <- data.frame(
  group = factor(c("a", "b", "c")),
  y = c(4.1, 5.3, 6.0),
  ymin = c(3.6, 4.7, 5.4),
  ymax = c(4.8, 6.1, 6.8)
)

p <- ggplot(summary_df, aes(group, y, ymin = ymin, ymax = ymax)) +
  geom_linerange_webgl(linewidth = 1.2) +
  geom_pointrange_webgl(colour = "#2563eb") +
  labs(title = "Linerange and pointrange")
ggplot_webgl(p, height = 420)
```

### Applet: Error bars and crossbars

``` r
p <- ggplot(summary_df, aes(group, y, ymin = ymin, ymax = ymax)) +
  geom_errorbar_webgl(width = 0.25) +
  geom_crossbar_webgl(aes(fill = group), width = 0.45, alpha = 0.55) +
  labs(title = "Error bars and crossbars")
ggplot_webgl(p, height = 420)
```

### Applet: Boxplot summary

``` r
p <- ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) +
  geom_boxplot_webgl() +
  labs(title = "Boxplot summary")
ggplot_webgl(p, height = 420)
```

### Applet: Violin density summary

Violin rendering uses `ggplot2`’s built density output.

``` r
p <- ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) +
  geom_violin_webgl(alpha = 0.7) +
  labs(title = "Violin density summary")
ggplot_webgl(p, height = 420)
```

## Filled Regions

Ribbon, area, and simple polygon layers are filled-region APIs. They are
useful for compact displays, but complex polygon topology such as holes
or self-intersections should be treated as outside the current core
contract.

### Applet: Ribbon band

``` r
band <- data.frame(
  x = seq(0, 2 * pi, length.out = 80)
)
band$y <- sin(band$x)
band$ymin <- band$y - 0.15
band$ymax <- band$y + 0.15

p <- ggplot(band, aes(x, ymin = ymin, ymax = ymax)) +
  geom_ribbon_webgl(fill = "#93c5fd", alpha = 0.6) +
  geom_line_webgl(aes(y = y), colour = "#1d4ed8") +
  labs(title = "Ribbon band")
ggplot_webgl(p, height = 420)
```

### Code-only: Area band

``` r
p <- ggplot(band, aes(x, y)) +
  geom_area_webgl(fill = "#a7f3d0", alpha = 0.7) +
  labs(title = "Area band")
ggplot_webgl(p, height = 420)
```

### Applet: Simple polygon

``` r
triangle <- data.frame(
  x = c(0, 1, 0.2),
  y = c(0, 0.2, 1),
  group = 1
)

p <- ggplot(triangle, aes(x, y, group = group)) +
  geom_polygon_webgl(fill = "#f97316", alpha = 0.7) +
  labs(title = "Simple polygon")
ggplot_webgl(p, height = 420)
```

## Raster and Annotation Layers

Raster layers are intended for regular cell displays. Text and label
layers are overlay metadata, not full WebGL glyph rendering.

### Applet: Raster grid

``` r
small_raster <- expand.grid(
  x = seq_len(8),
  y = seq_len(6),
  KEEP.OUT.ATTRS = FALSE
)
small_raster$value <- with(small_raster, x * y)

p <- ggplot(small_raster, aes(x, y, fill = value)) +
  geom_raster_webgl() +
  labs(title = "Raster grid")
ggplot_webgl(p, height = 420)
```

### Applet: Text and rug overlays

``` r
labels <- data.frame(
  x = c(2, 6),
  y = c(2, 5),
  label = c("low", "high")
)

p <- ggplot(small_raster, aes(x, y, fill = value)) +
  geom_tile_webgl(alpha = 0.55) +
  geom_text_webgl(data = labels, aes(x = x, y = y, label = label), inherit.aes = FALSE) +
  geom_rug_webgl(colour = "#334155") +
  labs(title = "Text and rug overlays")
ggplot_webgl(p, height = 420)
```

### Code-only: Label overlay metadata

``` r
p <- ggplot(labels, aes(x, y, label = label)) +
  geom_label_webgl(fill = "#ffffff", colour = "#0f172a") +
  labs(title = "Label overlay metadata")
ggplot_webgl(p, height = 420)
```

## Facets, Coordinates, and Fallbacks

Fixed-scale facets are supported across the primitive families.
Free-scale facets are serialized conservatively as metadata unless
panel-local scaling is available for the layer combination being
rendered.

### Code-only: Fixed-scale facets

``` r
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point_webgl() +
  facet_wrap(~am) +
  labs(title = "Fixed-scale facets")

ggplot_webgl(p, height = 420)
```

Unsupported geoms remain visible to the extraction layer as unsupported
metadata rather than being silently claimed as WebGL primitives. When a
plot needs exact `ggplot2` parity for an unsupported layer, keep that
layer in a static ggplot or replace it with one of the supported WebGL
primitives above.
