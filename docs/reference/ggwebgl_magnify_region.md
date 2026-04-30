# Build a Linked Magnifying-Glass Zoom Scene

Create a deterministic zoom view from a rectangular data region. The
helper is renderer-generic: callers provide renderer-ready ggWebGL
sources and the selected region, and ggWebGL derives either a two-panel
zoom spec or a publication figure with a linked inset.

## Usage

``` r
ggwebgl_magnify_region(
  source,
  region,
  display = c("panel", "inset"),
  source_panel = NULL,
  zoom_layers = NULL,
  global_panel_id = "global",
  zoom_panel_id = "local",
  global_label = "Global",
  zoom_label = "Zoomed region",
  box = TRUE,
  box_colour = "#334155",
  box_alpha = 0.65,
  box_width = 1.5,
  inset = list(left = 0.68, top = 0.06, width = 0.24, height = 0.24),
  interactive = FALSE,
  width = NULL,
  height = NULL,
  background = "white",
  preset = c("clean", "publication"),
  labels = NULL,
  webgl = NULL
)
```

## Arguments

- source:

  A `ggplot`, `ggWebGL` widget, `ggwebgl_spec`, or raw renderer payload
  accepted by
  [`ggWebGL()`](https://fbertran.github.io/ggWebGL/reference/ggWebGL.md).

- region:

  Rectangle to magnify. Use either
  `list(x = c(xmin, xmax), y = c(ymin, ymax))` or
  `list(xmin = ..., xmax = ..., ymin = ..., ymax = ...)`.

- display:

  One of `"panel"` or `"inset"`.

- source_panel:

  Optional panel id to magnify when `source` has multiple panels.
  Defaults to the first panel.

- zoom_layers:

  Optional renderer-ready layers to use in the zoom view. When omitted,
  the source panel layers are reused.

- global_panel_id, zoom_panel_id:

  Panel ids used in `display = "panel"`.

- global_label, zoom_label:

  Optional panel labels.

- box:

  Whether to add a rectangle overlay to the global panel.

- box_colour, box_alpha, box_width:

  Rectangle styling.

- inset:

  Inset placement list for `display = "inset"` with fractional `left`,
  `top`, `width`, and `height`.

- interactive:

  Whether a two-panel magnifier should let browser-side brush rectangles
  on the global panel update the zoom panel viewport live.

- width, height:

  Optional publication figure dimensions for inset output.

- background, preset:

  Publication figure styling for inset output.

- labels:

  Optional labels for the derived renderer specs.

- webgl:

  Optional renderer options for the derived specs. Defaults to the
  source webgl options.

## Value

A `ggwebgl_spec` for `display = "panel"` or a
`ggwebgl_publication_figure` for `display = "inset"`.

## Examples

``` r
source <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(
      data.frame(x = c(0, 1, 2, 3), y = c(0, 2, 1, 3)),
      x = "x",
      y = "y",
      colour = "#2563eb",
      alpha = 0.75,
      size = 4
    )
  )
)

ggwebgl_magnify_region(
  source,
  region = list(x = c(0.75, 2.25), y = c(0.75, 2.25)),
  display = "panel"
)
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
#> [1] 3
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
#> [1] 4
#> 
#> 
#> $layers[[2]]
#> $layers[[2]]$index
#> [1] 2
#> 
#> $layers[[2]]$geom
#> [1] "ggwebgl_magnify_region_box"
#> 
#> $layers[[2]]$stat
#> [1] "identity"
#> 
#> $layers[[2]]$supported
#> [1] TRUE
#> 
#> $layers[[2]]$primitive
#> [1] "lines"
#> 
#> $layers[[2]]$rows
#> [1] 5
#> 
#> 
#> $layers[[3]]
#> $layers[[3]]$index
#> [1] 3
#> 
#> $layers[[3]]$geom
#> [1] "adapter_points"
#> 
#> $layers[[3]]$stat
#> [1] "identity"
#> 
#> $layers[[3]]$supported
#> [1] TRUE
#> 
#> $layers[[3]]$primitive
#> [1] "points"
#> 
#> $layers[[3]]$rows
#> [1] 4
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
#> [1] 2
#> 
#> 
#> $render$panels
#> $render$panels[[1]]
#> $render$panels[[1]]$panel_id
#> [1] "global"
#> 
#> $render$panels[[1]]$row
#> [1] 1
#> 
#> $render$panels[[1]]$col
#> [1] 1
#> 
#> $render$panels[[1]]$label
#> [1] "Global"
#> 
#> $render$panels[[1]]$bounds
#> $render$panels[[1]]$bounds$left
#> [1] 0
#> 
#> $render$panels[[1]]$bounds$right
#> [1] 0.5
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
#> [1] 0 3
#> 
#> $render$panels[[1]]$viewport$y
#> [1] 0 3
#> 
#> 
#> $render$panels[[1]]$primitives
#> [1] "points" "lines" 
#> 
#> $render$panels[[1]]$point_count
#> [1] 4
#> 
#> $render$panels[[1]]$line_vertex_count
#> [1] 5
#> 
#> $render$panels[[1]]$path_count
#> [1] 1
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
#> [1] "global"
#> 
#> $render$panels[[1]]$layers[[1]]$type
#> [1] "points"
#> 
#> $render$panels[[1]]$layers[[1]]$geom
#> [1] "adapter_points"
#> 
#> $render$panels[[1]]$layers[[1]]$rows
#> [1] 4
#> 
#> $render$panels[[1]]$layers[[1]]$x
#> [1] 0 1 2 3
#> 
#> $render$panels[[1]]$layers[[1]]$y
#> [1] 0 2 1 3
#> 
#> $render$panels[[1]]$layers[[1]]$size
#> [1] 4 4 4 4
#> 
#> $render$panels[[1]]$layers[[1]]$age
#> [1] 1 1 1 1
#> 
#> $render$panels[[1]]$layers[[1]]$rgba
#>  [1] 0.1450980 0.3882353 0.9215686 0.7500000 0.1450980 0.3882353 0.9215686
#>  [8] 0.7500000 0.1450980 0.3882353 0.9215686 0.7500000 0.1450980 0.3882353
#> [15] 0.9215686 0.7500000
#> 
#> 
#> $render$panels[[1]]$layers[[2]]
#> $render$panels[[1]]$layers[[2]]$panel_id
#> [1] "global"
#> 
#> $render$panels[[1]]$layers[[2]]$type
#> [1] "lines"
#> 
#> $render$panels[[1]]$layers[[2]]$geom
#> [1] "ggwebgl_magnify_region_box"
#> 
#> $render$panels[[1]]$layers[[2]]$rows
#> [1] 5
#> 
#> $render$panels[[1]]$layers[[2]]$path_count
#> [1] 1
#> 
#> $render$panels[[1]]$layers[[2]]$paths
#> $render$panels[[1]]$layers[[2]]$paths[[1]]
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$rows
#> [1] 5
#> 
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$group
#> [1] "magnify_region"
#> 
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$x
#> [1] 0.75 2.25 2.25 0.75 0.75
#> 
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$y
#> [1] 0.75 0.75 2.25 2.25 0.75
#> 
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$width
#> [1] 1.5
#> 
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$age
#> [1] 0.00 0.25 0.50 0.75 1.00
#> 
#> $render$panels[[1]]$layers[[2]]$paths[[1]]$rgba
#>  [1] 0.2000000 0.2549020 0.3333333 0.6500000 0.2000000 0.2549020 0.3333333
#>  [8] 0.6500000 0.2000000 0.2549020 0.3333333 0.6500000 0.2000000 0.2549020
#> [15] 0.3333333 0.6500000 0.2000000 0.2549020 0.3333333 0.6500000
#> 
#> 
#> 
#> 
#> 
#> 
#> $render$panels[[2]]
#> $render$panels[[2]]$panel_id
#> [1] "local"
#> 
#> $render$panels[[2]]$row
#> [1] 1
#> 
#> $render$panels[[2]]$col
#> [1] 2
#> 
#> $render$panels[[2]]$label
#> [1] "Zoomed region"
#> 
#> $render$panels[[2]]$bounds
#> $render$panels[[2]]$bounds$left
#> [1] 0.5
#> 
#> $render$panels[[2]]$bounds$right
#> [1] 1
#> 
#> $render$panels[[2]]$bounds$top
#> [1] 0
#> 
#> $render$panels[[2]]$bounds$bottom
#> [1] 1
#> 
#> 
#> $render$panels[[2]]$viewport
#> $render$panels[[2]]$viewport$x
#> [1] 0.75 2.25
#> 
#> $render$panels[[2]]$viewport$y
#> [1] 0.75 2.25
#> 
#> 
#> $render$panels[[2]]$primitives
#> [1] "points"
#> 
#> $render$panels[[2]]$point_count
#> [1] 4
#> 
#> $render$panels[[2]]$line_vertex_count
#> [1] 0
#> 
#> $render$panels[[2]]$path_count
#> [1] 0
#> 
#> $render$panels[[2]]$raster_cell_count
#> [1] 0
#> 
#> $render$panels[[2]]$vector_count
#> [1] 0
#> 
#> $render$panels[[2]]$mesh_vertex_count
#> [1] 0
#> 
#> $render$panels[[2]]$mesh_triangle_count
#> [1] 0
#> 
#> $render$panels[[2]]$layers
#> $render$panels[[2]]$layers[[1]]
#> $render$panels[[2]]$layers[[1]]$panel_id
#> [1] "local"
#> 
#> $render$panels[[2]]$layers[[1]]$type
#> [1] "points"
#> 
#> $render$panels[[2]]$layers[[1]]$geom
#> [1] "adapter_points"
#> 
#> $render$panels[[2]]$layers[[1]]$rows
#> [1] 4
#> 
#> $render$panels[[2]]$layers[[1]]$x
#> [1] 0 1 2 3
#> 
#> $render$panels[[2]]$layers[[1]]$y
#> [1] 0 2 1 3
#> 
#> $render$panels[[2]]$layers[[1]]$size
#> [1] 4 4 4 4
#> 
#> $render$panels[[2]]$layers[[1]]$age
#> [1] 1 1 1 1
#> 
#> $render$panels[[2]]$layers[[1]]$rgba
#>  [1] 0.1450980 0.3882353 0.9215686 0.7500000 0.1450980 0.3882353 0.9215686
#>  [8] 0.7500000 0.1450980 0.3882353 0.9215686 0.7500000 0.1450980 0.3882353
#> [15] 0.9215686 0.7500000
#> 
#> 
#> 
#> 
#> attr(,"grid")
#> attr(,"grid")$rows
#> [1] 1
#> 
#> attr(,"grid")$cols
#> [1] 2
#> 
#> 
#> $render$primitives
#> [1] "points" "lines" 
#> 
#> $render$point_count
#> [1] 8
#> 
#> $render$line_vertex_count
#> [1] 5
#> 
#> $render$path_count
#> [1] 1
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
#> attr(,"class")
#> [1] "ggwebgl_spec" "list"        
```
