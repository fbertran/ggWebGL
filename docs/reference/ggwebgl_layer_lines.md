# Renderer-Ready Line Layer

Build a normalized line layer for downstream adapters.

## Usage

``` r
ggwebgl_layer_lines(
  data,
  x,
  y,
  z = NULL,
  group = NULL,
  colour = NULL,
  rgba = NULL,
  alpha = NULL,
  width = NULL,
  age = NULL,
  frame = NULL,
  time = NULL,
  panel_id = 1L,
  geom = "adapter_lines"
)
```

## Arguments

- data:

  Optional data frame supplying columns referenced by other arguments.

- x, y:

  Coordinate vectors or column names in `data`.

- z:

  Optional z coordinate vector or column name for 3D scenes.

- group:

  Optional path-group vector or column name. When omitted, all rows form
  one path.

- colour:

  Optional colour vector or column name. Ignored when `rgba` is
  supplied.

- rgba:

  Optional renderer-ready RGBA matrix/data frame with four columns, or
  vector of length `n * 4`, using values in `[0, 1]` or `[0, 255]`.

- alpha:

  Optional alpha vector or column name used with `colour`.

- width:

  Optional line-width vector or column name in renderer pixels.

- age:

  Optional normalized age vector or column name in `[0, 1]`.

- frame, time:

  Optional timeline frame or time vector or column name.

- panel_id:

  Scalar panel identifier for this layer.

- geom:

  Debug geom name recorded in the payload.

## Value

A normalized line layer list.

## Examples

``` r
lines <- data.frame(
  x = c(0, 1, 2, 0, 1, 2),
  y = c(0, 1, 0, 1, 2, 1),
  group = c("a", "a", "a", "b", "b", "b")
)

ggwebgl_layer_lines(
  lines,
  x = "x",
  y = "y",
  group = "group",
  colour = "#334155",
  alpha = 0.75,
  width = 2
)
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "lines"
#> 
#> $geom
#> [1] "adapter_lines"
#> 
#> $rows
#> [1] 6
#> 
#> $path_count
#> [1] 2
#> 
#> $paths
#> $paths[[1]]
#> $paths[[1]]$rows
#> [1] 3
#> 
#> $paths[[1]]$group
#> [1] "a"
#> 
#> $paths[[1]]$x
#> [1] 0 1 2
#> 
#> $paths[[1]]$y
#> [1] 0 1 0
#> 
#> $paths[[1]]$width
#> [1] 2
#> 
#> $paths[[1]]$age
#> [1] 0.0 0.5 1.0
#> 
#> $paths[[1]]$rgba
#>  [1] 0.2000000 0.2549020 0.3333333 0.7500000 0.2000000 0.2549020 0.3333333
#>  [8] 0.7500000 0.2000000 0.2549020 0.3333333 0.7500000
#> 
#> 
#> $paths[[2]]
#> $paths[[2]]$rows
#> [1] 3
#> 
#> $paths[[2]]$group
#> [1] "b"
#> 
#> $paths[[2]]$x
#> [1] 0 1 2
#> 
#> $paths[[2]]$y
#> [1] 1 2 1
#> 
#> $paths[[2]]$width
#> [1] 2
#> 
#> $paths[[2]]$age
#> [1] 0.0 0.5 1.0
#> 
#> $paths[[2]]$rgba
#>  [1] 0.2000000 0.2549020 0.3333333 0.7500000 0.2000000 0.2549020 0.3333333
#>  [8] 0.7500000 0.2000000 0.2549020 0.3333333 0.7500000
#> 
#> 
#> 
```
