# Update a ggWebGL Timeline from Shiny

Send a timeline update message to a rendered ggWebGL widget. The browser
applies the update to the widget identified by `outputId` and emits the
updated state back as `input$<outputId>_timeline`.

## Usage

``` r
updateGgWebGLTimeline(
  session,
  outputId,
  value = NULL,
  index = NULL,
  playing = NULL,
  speed = NULL,
  loop = NULL
)
```

## Arguments

- session:

  A Shiny session object.

- outputId:

  Output id passed to
  [`ggWebGLOutput()`](https://fbertran.github.io/ggWebGL/reference/ggWebGLOutput.md).
  Inside Shiny modules, pass the un-namespaced id; `session$ns()` is
  applied by this helper.

- value:

  Optional frame or time value to select.

- index:

  Optional 1-based timeline index to select. Exactly one of `value` or
  `index` may be supplied.

- playing:

  Optional logical scalar controlling playback.

- speed:

  Optional positive playback-speed multiplier.

- loop:

  Optional logical scalar controlling loop playback.

## Value

`NULL`, invisibly.

## Examples

``` r
if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
  server <- function(input, output, session) {
    shiny::observeEvent(input$next_frame, {
      updateGgWebGLTimeline(session, "plot", index = 2)
    })
  }
}
```
