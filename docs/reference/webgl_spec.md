# Build ggWebGL Renderer Options

`webgl_spec()` creates a normalized renderer option list for
[`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md),
[`ggwebgl_spec()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_spec.md),
and downstream adapter code. It is a compact user-facing wrapper around
the same internal normalization used by
[`theme_webgl()`](https://fbertran.github.io/ggWebGL/reference/theme_webgl.md).

## Usage

``` r
webgl_spec(
  camera = c("panzoom", "orbit", "trackball"),
  projection = c("orthographic", "perspective"),
  dimension = NULL,
  depth_test = NULL,
  blend_mode = c("auto", "alpha", "additive", "premultiplied"),
  shader = NULL,
  interactions = NULL,
  view = NULL,
  selection = NULL,
  timeline = NULL,
  ...
)
```

## Arguments

- camera:

  Camera/controller mode. `"panzoom"` targets 2D scenes; `"orbit"` and
  `"trackball"` target 3D scenes.

- projection:

  Projection mode, `"orthographic"` or `"perspective"`.

- dimension:

  Optional renderer dimensionality. When omitted, `"orbit"` and
  `"trackball"` imply `"3d"` while `"panzoom"` implies `"2d"`.

- depth_test:

  Logical scalar. `NULL` enables depth testing for 3D scenes and
  disables it for 2D scenes.

- blend_mode:

  Primitive blending mode: `"auto"`, `"alpha"`, `"additive"`, or
  `"premultiplied"`.

- shader:

  Optional shader preset.

- interactions:

  Optional interaction mode vector.

- view:

  Optional
  [`ggwebgl_view()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_view.md)
  object. If supplied, it takes precedence over `camera`, `projection`,
  and `dimension`.

- selection:

  Optional
  [`ggwebgl_selection()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_selection.md)
  object.

- timeline:

  Optional
  [`ggwebgl_timeline()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_timeline.md)
  object.

- ...:

  Additional renderer options stored under `webgl$extra`.

## Value

A normalized renderer option list.

## Examples

``` r
webgl_spec(camera = "orbit", projection = "perspective")
#> $shader
#> [1] "default"
#> 
#> $antialias
#> [1] TRUE
#> 
#> $transparent
#> [1] TRUE
#> 
#> $buffer_size
#> [1] 65536
#> 
#> $interactions
#> [1] "pan"    "zoom"   "camera"
#> 
#> $interactions_spec
#> $hover
#> [1] FALSE
#> 
#> $click
#> [1] FALSE
#> 
#> $brush
#> [1] FALSE
#> 
#> $lasso
#> [1] FALSE
#> 
#> $camera
#> [1] TRUE
#> 
#> $shiny
#> [1] TRUE
#> 
#> $modes
#> [1] "camera"
#> 
#> attr(,"class")
#> [1] "ggwebgl_interactions" "list"                
#> 
#> $rendering
#> [1] "visualization"
#> 
#> $panel_overlay
#> [1] "auto"
#> 
#> $view
#> $view$dimension
#> [1] "3d"
#> 
#> $view$projection
#> [1] "perspective"
#> 
#> $view$controller
#> [1] "orbit"
#> 
#> $view$state
#> $view$state$yaw
#> [1] 0
#> 
#> $view$state$pitch
#> [1] 0
#> 
#> $view$state$distance
#> [1] 2.8
#> 
#> $view$state$target
#> [1] 0 0 0
#> 
#> $view$state$rotation
#> [1] 0 0 0 1
#> 
#> $view$state$up
#> [1] 0 1 0
#> 
#> $view$state$fov
#> [1] 45
#> 
#> $view$state$near
#> [1] 0.01
#> 
#> $view$state$far
#> [1] 1000
#> 
#> 
#> 
#> $selection
#> $selection$mode
#> [1] "none"
#> 
#> $selection$highlight
#> [1] TRUE
#> 
#> $selection$emit
#> [1] TRUE
#> 
#> 
#> $dimension
#> [1] "3d"
#> 
#> $camera
#> [1] "orbit"
#> 
#> $projection
#> [1] "perspective"
#> 
#> $camera_state
#> $camera_state$yaw
#> [1] 0
#> 
#> $camera_state$pitch
#> [1] 0
#> 
#> $camera_state$distance
#> [1] 2.8
#> 
#> $camera_state$target
#> [1] 0 0 0
#> 
#> $camera_state$rotation
#> [1] 0 0 0 1
#> 
#> $camera_state$up
#> [1] 0 1 0
#> 
#> $camera_state$fov
#> [1] 45
#> 
#> $camera_state$near
#> [1] 0.01
#> 
#> $camera_state$far
#> [1] 1000
#> 
#> 
#> $depth_test
#> [1] TRUE
#> 
#> $blend_mode
#> [1] "auto"
#> 
#> $line_mode
#> [1] "auto"
#> 
#> $line_join
#> [1] "bevel"
#> 
#> $line_cap
#> [1] "round"
#> 
#> $extra
#> list()
#> 
#> attr(,"explicit_fields")
#> [1] "view"       "depth_test" "blend_mode"
```
