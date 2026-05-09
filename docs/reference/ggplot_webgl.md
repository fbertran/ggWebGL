# Convert a ggplot to a ggWebGL Widget

Build a widget payload from a `ggplot` object. The current
implementation renders supported point, line, raster, and fixed-scale
facet layouts through the browser WebGL path while keeping unsupported
layers explicit in the payload.

## Usage

``` r
ggplot_webgl(plot, width = NULL, height = NULL, elementId = NULL)
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Optional widget dimensions.

- elementId:

  Optional DOM element id.

## Value

An `htmlwidget`.

## Examples

``` r
plot <- ggplot2::ggplot(
  mtcars[1:10, ],
  ggplot2::aes(mpg, wt, colour = factor(cyl))
) +
  geom_point_webgl(size = 2) +
  theme_webgl(shader = "default")

ggplot_webgl(plot, width = 420, height = 320)

{"x":{"scene_version":2,"package_version":"0.7.0","labels":{},"webgl":{"shader":"default","antialias":true,"transparent":true,"buffer_size":65536,"interactions":["pan","zoom"],"rendering":"visualization","panel_overlay":"auto","view":{"dimension":"2d","projection":"orthographic","controller":"panzoom","state":{"yaw":0,"pitch":0,"distance":2.8,"target":[0,0,0],"rotation":[0,0,0,1],"up":[0,1,0],"fov":45,"near":0.01,"far":1000}},"selection":{"mode":"none","highlight":true,"emit":true},"dimension":"2d","camera":"orbit","projection":"orthographic","camera_state":{"yaw":0,"pitch":0,"distance":2.8,"target":[0,0,0],"rotation":[0,0,0,1],"up":[0,1,0],"fov":45,"near":0.01,"far":1000},"depth_test":false,"blend_mode":"auto","line_mode":"auto","line_join":"bevel","line_cap":"round","extra":[]},"layer_count":1,"layers":{"geom_point_webgl":{"geom":"GeomPointWebGL","stat":"StatIdentity","supported":true,"rows":10,"data_preview":{"x":[21,21,22.8,21.4,18.7,18.1,14.3,24.4,22.8,19.2],"y":[2.62,2.875,2.32,3.215,3.44,3.46,3.57,3.19,3.15,3.44],"colour":["#00BA38","#00BA38","#F8766D","#00BA38","#619CFF","#00BA38","#619CFF","#F8766D","#F8766D","#00BA38"],"fill":[null,null,null,null,null,null,null,null,null,null],"size":[2,2,2,2,2,2,2,2,2,2],"alpha":[null,null,null,null,null,null,null,null,null,null],"group":[2,2,1,2,3,2,3,1,1,2],"PANEL":["1","1","1","1","1","1","1","1","1","1"]}}},"render":{"mode":"webgl","grid":{"rows":1,"cols":1},"panels":[{"panel_id":1,"row":1,"col":1,"bounds":{"left":0,"right":1,"top":0,"bottom":1},"viewport":{"x":[13.795,24.905],"y":[2.2575,3.6325]},"primitives":"points","point_count":10,"line_vertex_count":0,"path_count":0,"raster_cell_count":0,"vector_count":0,"mesh_vertex_count":0,"mesh_triangle_count":0,"surface_vertex_count":0,"surface_triangle_count":0,"layers":[{"panel_id":1,"type":"points","geom":"GeomPointWebGL","rows":10,"x":[21,21,22.8,21.4,18.7,18.1,14.3,24.4,22.8,19.2],"y":[2.62,2.875,2.32,3.215,3.44,3.46,3.57,3.19,3.15,3.44],"size":[7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237],"age":[1,1,1,1,1,1,1,1,1,1],"rgba":[0,0.7294117647058823,0.2196078431372549,1,0,0.7294117647058823,0.2196078431372549,1,0.9725490196078431,0.4627450980392157,0.4274509803921568,1,0,0.7294117647058823,0.2196078431372549,1,0.3803921568627451,0.611764705882353,1,1,0,0.7294117647058823,0.2196078431372549,1,0.3803921568627451,0.611764705882353,1,1,0.9725490196078431,0.4627450980392157,0.4274509803921568,1,0.9725490196078431,0.4627450980392157,0.4274509803921568,1,0,0.7294117647058823,0.2196078431372549,1]}]}],"primitives":"points","point_count":10,"line_vertex_count":0,"path_count":0,"raster_cell_count":0,"vector_count":0,"mesh_vertex_count":0,"mesh_triangle_count":0,"surface_vertex_count":0,"surface_triangle_count":0,"unsupported_layers":[],"messages":[],"panel":1,"viewport":{"x":[13.795,24.905],"y":[2.2575,3.6325]},"layers":[{"panel_id":1,"type":"points","geom":"GeomPointWebGL","rows":10,"x":[21,21,22.8,21.4,18.7,18.1,14.3,24.4,22.8,19.2],"y":[2.62,2.875,2.32,3.215,3.44,3.46,3.57,3.19,3.15,3.44],"size":[7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237,7.559055118110237],"age":[1,1,1,1,1,1,1,1,1,1],"rgba":[0,0.7294117647058823,0.2196078431372549,1,0,0.7294117647058823,0.2196078431372549,1,0.9725490196078431,0.4627450980392157,0.4274509803921568,1,0,0.7294117647058823,0.2196078431372549,1,0.3803921568627451,0.611764705882353,1,1,0,0.7294117647058823,0.2196078431372549,1,0.3803921568627451,0.611764705882353,1,1,0.9725490196078431,0.4627450980392157,0.4274509803921568,1,0.9725490196078431,0.4627450980392157,0.4274509803921568,1,0,0.7294117647058823,0.2196078431372549,1]}],"dimension":"2d","coordinate_system":"cartesian2d","camera":{"mode":"panzoom","controller":"panzoom","projection":"orthographic","state":{"yaw":0,"pitch":0,"distance":2.8,"target":[0,0,0],"rotation":[0,0,0,1],"up":[0,1,0],"fov":45,"near":0.01,"far":1000}},"depth_test":false,"blend_mode":"auto","selection":{"mode":"none","highlight":true,"emit":true}}},"evals":[],"jsHooks":[]}
```
