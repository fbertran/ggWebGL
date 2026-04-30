# Renderer-Ready Point Layer

Build a normalized point layer for downstream adapters. Inputs must
already represent renderer coordinates and styling; package-specific
semantics should be resolved before calling this helper.

## Usage

``` r
ggwebgl_layer_points(
  data,
  x,
  y,
  z = NULL,
  colour = NULL,
  rgba = NULL,
  alpha = NULL,
  size = NULL,
  age = NULL,
  label = NULL,
  id = NULL,
  frame = NULL,
  time = NULL,
  panel_id = 1L,
  geom = "adapter_points"
)
```

## Arguments

- data:

  Optional data frame supplying columns referenced by other arguments.

- x, y:

  Coordinate vectors or column names in `data`.

- z:

  Optional z coordinate vector or column name for 3D scenes.

- colour:

  Optional colour vector or column name. Ignored when `rgba` is
  supplied.

- rgba:

  Optional renderer-ready RGBA matrix/data frame with four columns, or
  vector of length `n * 4`, using values in `[0, 1]` or `[0, 255]`.

- alpha:

  Optional alpha vector or column name used with `colour`.

- size:

  Optional point-size vector or column name in renderer pixels.

- age:

  Optional normalized age vector or column name in `[0, 1]`.

- label:

  Optional hover label vector or column name.

- id:

  Optional stable primitive id vector or column name for selection.

- frame, time:

  Optional timeline frame or time vector or column name.

- panel_id:

  Scalar panel identifier for this layer.

- geom:

  Debug geom name recorded in the payload.

## Value

A normalized point layer list.

## Examples

``` r
points <- data.frame(
  x = c(0, 1, 2),
  y = c(2, 1, 0),
  colour = c("#0f766e", "#f97316", "#2563eb"),
  label = c("a", "b", "c")
)

ggwebgl_layer_points(
  points,
  x = "x",
  y = "y",
  colour = "colour",
  alpha = 0.6,
  size = 3,
  label = "label"
)
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "points"
#> 
#> $geom
#> [1] "adapter_points"
#> 
#> $rows
#> [1] 3
#> 
#> $x
#> [1] 0 1 2
#> 
#> $y
#> [1] 2 1 0
#> 
#> $size
#> [1] 3 3 3
#> 
#> $age
#> [1] 1 1 1
#> 
#> $label
#> [1] "a" "b" "c"
#> 
#> $rgba
#>  [1] 0.05882353 0.46274510 0.43137255 0.60000000 0.97647059 0.45098039
#>  [7] 0.08627451 0.60000000 0.14509804 0.38823529 0.92156863 0.60000000
#> 
```
