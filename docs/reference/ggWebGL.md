# Create a ggWebGL htmlwidget

Low-level constructor for the package widget binding.

## Usage

``` r
ggWebGL(x = list(), width = NULL, height = NULL, elementId = NULL)
```

## Arguments

- x:

  Named list describing a widget payload.

- width, height:

  Optional widget dimensions passed through to
  [`htmlwidgets::createWidget()`](https://rdrr.io/pkg/htmlwidgets/man/createWidget.html).

- elementId:

  Optional DOM element id.

## Value

An `htmlwidget`.

## Examples

``` r
point_layer <- ggwebgl_layer_points(
  data.frame(x = c(0, 1, 2), y = c(2, 1, 0)),
  x = "x",
  y = "y"
)
spec <- ggwebgl_spec(layers = list(point_layer))

ggWebGL(spec, width = 320, height = 240)

{"x":{"scene_version":2,"package_version":"0.7.0","labels":{},"webgl":{"shader":"default","antialias":true,"transparent":true,"buffer_size":65536,"interactions":["pan","zoom"],"interactions_spec":{"hover":false,"click":false,"brush":false,"lasso":false,"camera":false,"shiny":true,"modes":[]},"rendering":"visualization","panel_overlay":"auto","view":{"dimension":"2d","projection":"orthographic","controller":"panzoom","state":{"yaw":0,"pitch":0,"distance":2.8,"target":[0,0,0],"rotation":[0,0,0,1],"up":[0,1,0],"fov":45,"near":0.01,"far":1000}},"selection":{"mode":"none","highlight":true,"emit":true},"dimension":"2d","camera":"orbit","projection":"orthographic","camera_state":{"yaw":0,"pitch":0,"distance":2.8,"target":[0,0,0],"rotation":[0,0,0,1],"up":[0,1,0],"fov":45,"near":0.01,"far":1000},"depth_test":false,"blend_mode":"auto","transport":{"mode":"auto","threshold":100000,"progressive":"auto","chunk_size":100000,"position":"float32","colors":"auto","lod":"auto","lod_max_points":5000},"line_mode":"auto","line_join":"bevel","line_cap":"round","extra":[]},"layer_count":1,"layers":[{"index":1,"geom":"adapter_points","stat":"identity","supported":true,"primitive":"points","rows":3}],"render":{"mode":"webgl","grid":{"rows":1,"cols":1},"panels":[{"panel_id":"1","row":1,"col":1,"bounds":{"left":0,"right":1,"top":0,"bottom":1},"viewport":{"x":[0,2],"y":[0,2]},"primitives":"points","point_count":3,"line_vertex_count":0,"path_count":0,"raster_cell_count":0,"vector_count":0,"mesh_vertex_count":0,"mesh_triangle_count":0,"surface_vertex_count":0,"surface_triangle_count":0,"layers":[{"panel_id":1,"type":"points","geom":"adapter_points","rows":3,"x":[0,1,2],"y":[2,1,0],"size":[4,4,4],"age":[1,1,1],"rgba":[0.1725490196078431,0.2431372549019608,0.3137254901960784,1,0.1725490196078431,0.2431372549019608,0.3137254901960784,1,0.1725490196078431,0.2431372549019608,0.3137254901960784,1]}]}],"primitives":"points","point_count":3,"line_vertex_count":0,"path_count":0,"raster_cell_count":0,"vector_count":0,"mesh_vertex_count":0,"mesh_triangle_count":0,"surface_vertex_count":0,"surface_triangle_count":0,"unsupported_layers":[],"messages":[],"panel":"1","viewport":{"x":[0,2],"y":[0,2]},"layers":[{"panel_id":1,"type":"points","geom":"adapter_points","rows":3,"x":[0,1,2],"y":[2,1,0],"size":[4,4,4],"age":[1,1,1],"rgba":[0.1725490196078431,0.2431372549019608,0.3137254901960784,1,0.1725490196078431,0.2431372549019608,0.3137254901960784,1,0.1725490196078431,0.2431372549019608,0.3137254901960784,1]}],"transport":{"mode":"auto","threshold":100000,"position":"float32","colors":"auto","progressive":"auto","chunk_size":100000,"compact_layers":0,"compact_point_count":0,"decoded_bytes":0},"lod":{"mesh_hooks":"external"},"dimension":"2d","coordinate_system":"cartesian2d","camera":{"mode":"panzoom","controller":"panzoom","projection":"orthographic","state":{"yaw":0,"pitch":0,"distance":2.8,"target":[0,0,0],"rotation":[0,0,0,1],"up":[0,1,0],"fov":45,"near":0.01,"far":1000}},"depth_test":false,"blend_mode":"auto","selection":{"mode":"none","highlight":true,"emit":true},"interactions":{"hover":false,"click":false,"brush":false,"lasso":false,"camera":false,"shiny":true,"modes":[]}}},"evals":[],"jsHooks":[]}
```
