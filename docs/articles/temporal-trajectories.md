# Temporal and 3D trajectories with ggWebGL

## Purpose

`ggWebGL` can render ordered trajectory/path layers with timeline
metadata. The examples below use deterministic in-memory data and
browser-side WebGL through `htmlwidgets`; they do not download data or
report performance numbers. The widgets autoplay by default and can be
paused, scrubbed, or reset with the timeline controls. If a browser
throttles a background tab, pressing **Play** resumes the timeline.

**Status.** Trajectory paths, trajectory shader encodings,
exact/cumulative timeline controls, and Shiny timeline messages are
`Experimental` public APIs. They are suitable for renderer evaluation
and small examples, but should not be described as stable performance or
animation guarantees.

The relevant renderer pieces are:

- [`geom_path3d_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_path3d_webgl.md)
  for ordered paths with optional `z`, `frame`, and `time` aesthetics.
- [`animation_spec()`](https://fbertran.github.io/ggWebGL/reference/animation_spec.md)
  /
  [`ggwebgl_timeline()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_timeline.md)
  for exact or cumulative timeline metadata.
- `trajectory_age`, `trajectory_velocity`, and `trajectory_direction`
  shader modes for renderer-side trajectory visual encodings.
- `input$<outputId>_timeline` and
  [`updateGgWebGLTimeline()`](https://fbertran.github.io/ggWebGL/reference/updateGgWebGLTimeline.md)
  for Shiny timeline integration.

## 2D Cumulative Trajectory

This spiral is rendered as an ordered path with `frame` metadata and
cumulative timeline filtering. The `trajectory_age` shader makes the
time prefix visible as the timeline is scrubbed.

``` r
temporal_spiral_widget(height = 460)
```

## 3D Trajectory

The helix uses the same path contract, but supplies `z` and `time`
values. The view is opt-in 3D with an orbit camera.

``` r
temporal_helix_widget(height = 460)
```

## Velocity and Direction Encodings

Trajectory velocity and direction are renderer-side visual encodings
computed from the serialized path coordinates and timeline values. They
do not add application semantics to the data.

``` r
temporal_velocity_widget(height = 460)
```

``` r
temporal_direction_widget(height = 460)
```

## Exact Frame Samples

Exact filtering is useful for point-like animated samples. This example
shows only the samples whose `frame` equals the selected timeline value.

``` r
temporal_exact_particles_widget(height = 460)
```

## Shiny Timeline Integration

In Shiny, the browser emits the current timeline state as
`input$<outputId>_timeline`. Server code can update the browser-side
timeline with
[`updateGgWebGLTimeline()`](https://fbertran.github.io/ggWebGL/reference/updateGgWebGLTimeline.md).

``` r
library(shiny)
library(ggWebGL)

ui <- fluidPage(
  actionButton("restart", "Reset"),
  ggWebGLOutput("plot", height = "420px"),
  verbatimTextOutput("timeline_state")
)

server <- function(input, output, session) {
  output$plot <- renderGgWebGL({
    temporal_helix_widget(height = 460)
  })

  observeEvent(input$restart, {
    updateGgWebGLTimeline(session, "plot", index = 1L, playing = FALSE)
  })

  output$timeline_state <- renderPrint({
    input$plot_timeline
  })
}

if (interactive()) {
  shinyApp(ui, server)
}
```

The repository also includes a compact optional app at
`inst/examples/shiny/timeline-control-demo.R`.

## Limitations

Missing values and group boundaries break paths. Cumulative timeline
filtering draws complete visible prefixes; exact path filtering does not
interpolate partial hidden segments. Velocity and direction are
renderer-side visual encodings. Shiny timeline events report renderer
time/frame state; downstream applications remain responsible for
interpreting those values.
