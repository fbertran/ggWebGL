# Define a ggWebGL View Contract

Build a structured renderer view specification. This replaces the
previous loose `dimension`, `camera`, `projection`, and `camera_state`
fields while keeping them mirrored internally for older renderer paths.

## Usage

``` r
ggwebgl_view(
  dimension = c("2d", "3d"),
  projection = c("orthographic", "perspective"),
  controller = NULL,
  state = list()
)
```

## Arguments

- dimension:

  Renderer dimensionality, `"2d"` or `"3d"`.

- projection:

  Projection mode, `"orthographic"` or `"perspective"`.

- controller:

  Interaction controller. Use `"panzoom"` for 2D scenes and `"orbit"` or
  `"trackball"` for 3D scenes.

- state:

  Camera/view state list. Recognized fields include `target`,
  `distance`, `rotation`, `up`, `fov`, `near`, and `far`. Legacy `yaw`
  and `pitch` are converted to `rotation`.

## Value

A `ggwebgl_view` list.

## Examples

``` r
ggwebgl_view(dimension = "3d", controller = "trackball")
#> $dimension
#> [1] "3d"
#> 
#> $projection
#> [1] "orthographic"
#> 
#> $controller
#> [1] "trackball"
#> 
#> $state
#> $state$yaw
#> [1] 0
#> 
#> $state$pitch
#> [1] 0
#> 
#> $state$distance
#> [1] 2.8
#> 
#> $state$target
#> [1] 0 0 0
#> 
#> $state$rotation
#> [1] 0 0 0 1
#> 
#> $state$up
#> [1] 0 1 0
#> 
#> $state$fov
#> [1] 45
#> 
#> $state$near
#> [1] 0.01
#> 
#> $state$far
#> [1] 1000
#> 
#> 
#> attr(,"class")
#> [1] "ggwebgl_view" "list"        
```
