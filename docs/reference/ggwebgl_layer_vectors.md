# Renderer-Ready Vector Arrow Layer

Build a vector-arrow layer for downstream adapters.

## Usage

``` r
ggwebgl_layer_vectors(
  data,
  x,
  y,
  xend,
  yend,
  z = NULL,
  zend = NULL,
  colour = NULL,
  rgba = NULL,
  alpha = NULL,
  width = NULL,
  head_size = NULL,
  id = NULL,
  frame = NULL,
  time = NULL,
  panel_id = 1L,
  geom = "adapter_vectors"
)
```

## Arguments

- data:

  Optional data frame supplying columns referenced by other arguments.

- x, y:

  Coordinate vectors or column names in `data`.

- xend, yend:

  Arrow endpoint coordinates.

- z:

  Optional z coordinate vector or column name for 3D scenes.

- zend:

  Optional arrow endpoint z coordinate for 3D scenes. When `z` or `zend`
  is omitted it defaults to zero in 3D projection.

- colour:

  Optional colour vector or column name. Ignored when `rgba` is
  supplied.

- rgba:

  Optional renderer-ready RGBA matrix/data frame with four columns, or
  vector of length `n * 4`, using values in `[0, 1]` or `[0, 255]`.

- alpha:

  Optional alpha vector or column name used with `colour`.

- width:

  Optional shaft width in renderer pixels.

- head_size:

  Optional arrowhead size in renderer pixels.

- id:

  Optional stable primitive id vector or column name for selection.

- frame, time:

  Optional timeline frame or time vector or column name.

- panel_id:

  Scalar panel identifier for this layer.

- geom:

  Debug geom name recorded in the payload.

## Value

A normalized vector layer list.

## Examples

``` r
arrows <- data.frame(x = 0:1, y = 0:1, xend = c(0.5, 1.4), yend = c(0.2, 1.2))
ggwebgl_layer_vectors(arrows, x = "x", y = "y", xend = "xend", yend = "yend")
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "vectors"
#> 
#> $geom
#> [1] "adapter_vectors"
#> 
#> $rows
#> [1] 2
#> 
#> $x
#> [1] 0 1
#> 
#> $y
#> [1] 0 1
#> 
#> $xend
#> [1] 0.5 1.4
#> 
#> $yend
#> [1] 0.2 1.2
#> 
#> $width
#> [1] 1.5 1.5
#> 
#> $head_size
#> [1] 8 8
#> 
#> $rgba
#> [1] 0.1725490 0.2431373 0.3137255 1.0000000 0.1725490 0.2431373 0.3137255
#> [8] 1.0000000
#> 
```
