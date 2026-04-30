# Convert backend objects to a ggWebGL renderer specification

`ggWebGL` exposes a renderer-adapter protocol for converting explicit
backend inputs into normalized primitive scenes. Backend-specific
methods must resolve semantics before the widget consumes the payload.

## Usage

``` r
as_ggwebgl_spec(x, ...)
```

## Arguments

- x:

  Input object.

- ...:

  Passed to method-specific implementations.

## Value

A normalized ggWebGL renderer specification.

## Examples

``` r
point_layer <- ggwebgl_layer_points(
  data.frame(x = c(0, 1), y = c(1, 0)),
  x = "x",
  y = "y"
)
spec <- ggwebgl_spec(layers = list(point_layer))

as_ggwebgl_spec(spec)
#> $package_version
#> [1] "0.4.0"
#> 
#> $labels
#> named list()
#> 
#> $webgl
#> $webgl$shader
#> [1] "default"
#> 
#> $webgl$antialias
#> [1] TRUE
#> 
#> $webgl$transparent
#> [1] TRUE
#> 
#> $webgl$buffer_size
#> [1] 65536
#> 
#> $webgl$interactions
#> [1] "pan"  "zoom"
#> 
#> $webgl$rendering
#> [1] "visualization"
#> 
#> $webgl$panel_overlay
#> [1] "auto"
#> 
#> $webgl$view
#> $webgl$view$dimension
#> [1] "2d"
#> 
#> $webgl$view$projection
#> [1] "orthographic"
#> 
#> $webgl$view$controller
#> [1] "panzoom"
#> 
#> $webgl$view$state
#> $webgl$view$state$yaw
#> [1] 0
#> 
#> $webgl$view$state$pitch
#> [1] 0
#> 
#> $webgl$view$state$distance
#> [1] 2.8
#> 
#> $webgl$view$state$target
#> [1] 0 0 0
#> 
#> $webgl$view$state$rotation
#> [1] 0 0 0 1
#> 
#> $webgl$view$state$up
#> [1] 0 1 0
#> 
#> $webgl$view$state$fov
#> [1] 45
#> 
#> $webgl$view$state$near
#> [1] 0.01
#> 
#> $webgl$view$state$far
#> [1] 1000
#> 
#> 
#> 
#> $webgl$selection
#> $webgl$selection$mode
#> [1] "none"
#> 
#> $webgl$selection$highlight
#> [1] TRUE
#> 
#> $webgl$selection$emit
#> [1] TRUE
#> 
#> 
#> $webgl$dimension
#> [1] "2d"
#> 
#> $webgl$camera
#> [1] "orbit"
#> 
#> $webgl$projection
#> [1] "orthographic"
#> 
#> $webgl$camera_state
#> $webgl$camera_state$yaw
#> [1] 0
#> 
#> $webgl$camera_state$pitch
#> [1] 0
#> 
#> $webgl$camera_state$distance
#> [1] 2.8
#> 
#> $webgl$camera_state$target
#> [1] 0 0 0
#> 
#> $webgl$camera_state$rotation
#> [1] 0 0 0 1
#> 
#> $webgl$camera_state$up
#> [1] 0 1 0
#> 
#> $webgl$camera_state$fov
#> [1] 45
#> 
#> $webgl$camera_state$near
#> [1] 0.01
#> 
#> $webgl$camera_state$far
#> [1] 1000
#> 
#> 
#> $webgl$line_mode
#> [1] "auto"
#> 
#> $webgl$line_join
#> [1] "bevel"
#> 
#> $webgl$line_cap
#> [1] "round"
#> 
#> $webgl$extra
#> list()
#> 
#> attr(,"explicit_fields")
#> character(0)
#> 
#> $layer_count
#> [1] 1
#> 
#> $layers
#> $layers[[1]]
#> $layers[[1]]$index
#> [1] 1
#> 
#> $layers[[1]]$geom
#> [1] "adapter_points"
#> 
#> $layers[[1]]$stat
#> [1] "identity"
#> 
#> $layers[[1]]$supported
#> [1] TRUE
#> 
#> $layers[[1]]$primitive
#> [1] "points"
#> 
#> $layers[[1]]$rows
#> [1] 2
#> 
#> 
#> 
#> $render
#> $render$mode
#> [1] "webgl"
#> 
#> $render$grid
#> $render$grid$rows
#> [1] 1
#> 
#> $render$grid$cols
#> [1] 1
#> 
#> 
#> $render$panels
#> $render$panels[[1]]
#> $render$panels[[1]]$panel_id
#> [1] "1"
#> 
#> $render$panels[[1]]$row
#> [1] 1
#> 
#> $render$panels[[1]]$col
#> [1] 1
#> 
#> $render$panels[[1]]$bounds
#> $render$panels[[1]]$bounds$left
#> [1] 0
#> 
#> $render$panels[[1]]$bounds$right
#> [1] 1
#> 
#> $render$panels[[1]]$bounds$top
#> [1] 0
#> 
#> $render$panels[[1]]$bounds$bottom
#> [1] 1
#> 
#> 
#> $render$panels[[1]]$viewport
#> $render$panels[[1]]$viewport$x
#> [1] 0 1
#> 
#> $render$panels[[1]]$viewport$y
#> [1] 0 1
#> 
#> 
#> $render$panels[[1]]$primitives
#> [1] "points"
#> 
#> $render$panels[[1]]$point_count
#> [1] 2
#> 
#> $render$panels[[1]]$line_vertex_count
#> [1] 0
#> 
#> $render$panels[[1]]$path_count
#> [1] 0
#> 
#> $render$panels[[1]]$raster_cell_count
#> [1] 0
#> 
#> $render$panels[[1]]$vector_count
#> [1] 0
#> 
#> $render$panels[[1]]$mesh_vertex_count
#> [1] 0
#> 
#> $render$panels[[1]]$mesh_triangle_count
#> [1] 0
#> 
#> $render$panels[[1]]$layers
#> $render$panels[[1]]$layers[[1]]
#> $render$panels[[1]]$layers[[1]]$panel_id
#> [1] 1
#> 
#> $render$panels[[1]]$layers[[1]]$type
#> [1] "points"
#> 
#> $render$panels[[1]]$layers[[1]]$geom
#> [1] "adapter_points"
#> 
#> $render$panels[[1]]$layers[[1]]$rows
#> [1] 2
#> 
#> $render$panels[[1]]$layers[[1]]$x
#> [1] 0 1
#> 
#> $render$panels[[1]]$layers[[1]]$y
#> [1] 1 0
#> 
#> $render$panels[[1]]$layers[[1]]$size
#> [1] 4 4
#> 
#> $render$panels[[1]]$layers[[1]]$age
#> [1] 1 1
#> 
#> $render$panels[[1]]$layers[[1]]$rgba
#> [1] 0.1725490 0.2431373 0.3137255 1.0000000 0.1725490 0.2431373 0.3137255
#> [8] 1.0000000
#> 
#> 
#> 
#> 
#> attr(,"grid")
#> attr(,"grid")$rows
#> [1] 1
#> 
#> attr(,"grid")$cols
#> [1] 1
#> 
#> 
#> $render$primitives
#> [1] "points"
#> 
#> $render$point_count
#> [1] 2
#> 
#> $render$line_vertex_count
#> [1] 0
#> 
#> $render$path_count
#> [1] 0
#> 
#> $render$raster_cell_count
#> [1] 0
#> 
#> $render$vector_count
#> [1] 0
#> 
#> $render$mesh_vertex_count
#> [1] 0
#> 
#> $render$mesh_triangle_count
#> [1] 0
#> 
#> $render$unsupported_layers
#> list()
#> 
#> $render$messages
#> character(0)
#> 
#> $render$panel
#> [1] "1"
#> 
#> $render$viewport
#> $render$viewport$x
#> [1] 0 1
#> 
#> $render$viewport$y
#> [1] 0 1
#> 
#> 
#> $render$layers
#> $render$layers[[1]]
#> $render$layers[[1]]$panel_id
#> [1] 1
#> 
#> $render$layers[[1]]$type
#> [1] "points"
#> 
#> $render$layers[[1]]$geom
#> [1] "adapter_points"
#> 
#> $render$layers[[1]]$rows
#> [1] 2
#> 
#> $render$layers[[1]]$x
#> [1] 0 1
#> 
#> $render$layers[[1]]$y
#> [1] 1 0
#> 
#> $render$layers[[1]]$size
#> [1] 4 4
#> 
#> $render$layers[[1]]$age
#> [1] 1 1
#> 
#> $render$layers[[1]]$rgba
#> [1] 0.1725490 0.2431373 0.3137255 1.0000000 0.1725490 0.2431373 0.3137255
#> [8] 1.0000000
#> 
#> 
#> 
#> $render$dimension
#> [1] "2d"
#> 
#> $render$camera
#> $render$camera$mode
#> [1] "panzoom"
#> 
#> $render$camera$controller
#> [1] "panzoom"
#> 
#> $render$camera$projection
#> [1] "orthographic"
#> 
#> $render$camera$state
#> $render$camera$state$yaw
#> [1] 0
#> 
#> $render$camera$state$pitch
#> [1] 0
#> 
#> $render$camera$state$distance
#> [1] 2.8
#> 
#> $render$camera$state$target
#> [1] 0 0 0
#> 
#> $render$camera$state$rotation
#> [1] 0 0 0 1
#> 
#> $render$camera$state$up
#> [1] 0 1 0
#> 
#> $render$camera$state$fov
#> [1] 45
#> 
#> $render$camera$state$near
#> [1] 0.01
#> 
#> $render$camera$state$far
#> [1] 1000
#> 
#> 
#> 
#> $render$selection
#> $render$selection$mode
#> [1] "none"
#> 
#> $render$selection$highlight
#> [1] TRUE
#> 
#> $render$selection$emit
#> [1] TRUE
#> 
#> 
#> 
```
