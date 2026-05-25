# Build a ggWebGL Specification from Renderer-Ready Layers

Build a ggWebGL Specification from Renderer-Ready Layers

## Usage

``` r
ggwebgl_spec(
  layers,
  labels = list(),
  webgl = list(),
  grid = NULL,
  panels = NULL,
  messages = character(),
  timeline = NULL
)
```

## Arguments

- layers:

  A list of normalized point, line, raster, vector, ribbon, mesh, or
  surface layers.

- labels:

  Optional labels list (`title`, `subtitle`, `x`, `y`).

- webgl:

  Optional renderer options passed to
  [`theme_webgl()`](https://fbertran.github.io/ggWebGL/reference/theme_webgl.md).

- grid:

  Optional list with `rows` and `cols`.

- panels:

  Optional panel metadata list or data frame with `panel_id`, `row`,
  `col`, optional `label`, and optional `viewport`.

- messages:

  Optional character vector of renderer messages.

- timeline:

  Optional
  [`ggwebgl_timeline()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_timeline.md)
  specification.

## Value

A classed `ggwebgl_spec` object accepted by
[`ggWebGL()`](https://fbertran.github.io/ggWebGL/reference/ggWebGL.md).

## Examples

``` r
panel_points <- ggwebgl_layer_points(
  data.frame(x = c(0, 1), y = c(1, 0)),
  x = "x",
  y = "y"
)
panel_lines <- ggwebgl_layer_lines(
  data.frame(x = c(0, 1, 2), y = c(0, 1, 0)),
  x = "x",
  y = "y",
  panel_id = "B"
)

spec <- ggwebgl_spec(
  layers = list(panel_points, panel_lines),
  labels = list(title = "adapter spec"),
  panels = data.frame(
    panel_id = c(1L, "B"),
    row = c(1L, 1L),
    col = c(1L, 2L),
    stringsAsFactors = FALSE
  )
)

spec$render$grid
#> $rows
#> [1] 1
#> 
#> $cols
#> [1] 2
#> 
```
