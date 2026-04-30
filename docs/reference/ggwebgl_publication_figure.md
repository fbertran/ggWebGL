# Build a Publication-Mode Figure Container from ggWebGL Panels

Create a package-owned HTML container for publication capture. Each
child panel is rendered through ggWebGL in publication mode unless it
already declares a different rendering contract explicitly.

## Usage

``` r
ggwebgl_publication_figure(
  panels,
  layout = c("single", "row", "grid"),
  labels = NULL,
  annotations = NULL,
  inset = NULL,
  background = "white",
  preset = c("clean", "publication"),
  width = NULL,
  height = NULL
)
```

## Arguments

- panels:

  A non-empty list of panel sources. Supported sources are `ggplot`
  objects, `ggWebGL` htmlwidgets, `ggwebgl_spec` objects, or raw
  renderer payloads accepted by
  [`ggWebGL()`](https://fbertran.github.io/ggWebGL/reference/ggWebGL.md).
  Each element may also be a list with `source` plus optional
  `show_panel_overlay`.

- layout:

  One of `"single"`, `"row"`, or `"grid"`.

- labels:

  Optional character vector of panel labels.

- annotations:

  Optional list of figure-level text annotations. Each entry should
  contain `text`, `x`, and `y`, with optional `size`, `colour`, `font`,
  `hjust`, and `vjust`.

- inset:

  Optional inset specification containing a panel `source` plus
  fractional `left`, `top`, `width`, and `height`.

- background:

  Figure background colour.

- preset:

  Publication styling preset. `"publication"` adds subtle panel borders
  and muted overlay text.

- width, height:

  Optional figure dimensions in pixels.

## Value

A browsable HTML container with class `ggwebgl_publication_figure`.

## Examples

``` r
demo_spec <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(
      data.frame(x = c(0.15, 0.52, 0.84), y = c(0.20, 0.78, 0.42)),
      x = "x",
      y = "y",
      colour = c("#0f766e", "#f97316", "#2563eb"),
      alpha = 0.8,
      size = 5
    )
  )
)

figure <- ggwebgl_publication_figure(
  panels = list(demo_spec),
  width = 420,
  height = 280
)

inherits(figure, "ggwebgl_publication_figure")
#> [1] TRUE
```
