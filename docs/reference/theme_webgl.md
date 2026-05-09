# Add WebGL Rendering Options to a ggplot

Attach WebGL-specific rendering metadata to a `ggplot` object. The
returned object is consumed by
[`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md)
and stored on the plot as `plot$ggwebgl`.

## Usage

``` r
theme_webgl(
  shader = "default",
  antialias = TRUE,
  transparent = TRUE,
  buffer_size = 65536L,
  interactions = c("pan", "zoom"),
  rendering = "visualization",
  panel_overlay = "auto",
  view = NULL,
  selection = NULL,
  dimension = "2d",
  camera = "orbit",
  projection = "orthographic",
  camera_state = list(),
  depth_test = NULL,
  blend_mode = "auto",
  timeline = NULL,
  ...
)
```

## Arguments

- shader:

  Shader preset name or path identifier. Built-in modes are `"default"`,
  `"density_splat"`, `"trajectory_age"`, and `"trajectory_age_glow"`,
  `"trajectory_velocity"`, and `"trajectory_direction"`.

- antialias:

  Logical scalar; whether antialiasing should be requested.

- transparent:

  Logical scalar; whether the drawing surface should allow transparency.

- buffer_size:

  Integer scalar giving the initial buffer allocation used by the
  eventual renderer.

- interactions:

  Legacy character vector of interaction modes to enable. New code
  should use `selection = ggwebgl_selection(...)` for brush/lasso
  behavior.

- rendering:

  Rendering contract mode. `"visualization"` keeps the current
  interactive widget chrome. `"publication"` suppresses presentation
  chrome by default and is intended for clean figure capture.

- panel_overlay:

  Panel overlay display mode. `"auto"` shows panel strips and frames for
  faceted plots, `"show"` forces them on, and `"hide"` removes them.

- view:

  Optional
  [`ggwebgl_view()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_view.md)
  object. This is the preferred structured view/camera contract.

- selection:

  Optional
  [`ggwebgl_selection()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_selection.md)
  object. This is the preferred selection contract.

- dimension, camera, projection, camera_state:

  Legacy view fields retained as an internal migration shim.

- depth_test:

  Logical scalar. `NULL` uses the renderer default: disabled for 2D
  scenes and enabled for 3D scenes. Set explicitly to override.

- blend_mode:

  Primitive blending mode: `"auto"`, `"alpha"`, `"additive"`, or
  `"premultiplied"`.

- timeline:

  Optional
  [`ggwebgl_timeline()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_timeline.md)
  specification for runtime playback controls.

- ...:

  Reserved for future backend-specific options.

## Value

An object that can be added to a `ggplot`.

## Examples

``` r
plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt, colour = factor(cyl))) +
  ggplot2::geom_point() +
  theme_webgl(
    shader = "density_splat",
    selection = ggwebgl_selection("none")
  )

plot$ggwebgl
#> $shader
#> [1] "density_splat"
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
#> [1] "pan"  "zoom"
#> 
#> $rendering
#> [1] "visualization"
#> 
#> $panel_overlay
#> [1] "auto"
#> 
#> $view
#> $view$dimension
#> [1] "2d"
#> 
#> $view$projection
#> [1] "orthographic"
#> 
#> $view$controller
#> [1] "panzoom"
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
#> [1] "2d"
#> 
#> $camera
#> [1] "orbit"
#> 
#> $projection
#> [1] "orthographic"
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
#> [1] FALSE
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
#> [1] "shader"    "selection"
```
