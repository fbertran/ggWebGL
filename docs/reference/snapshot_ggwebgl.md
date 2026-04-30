# Capture a ggWebGL Scene as a Static Image

Build a `ggWebGL` widget if needed, hide interactive chrome for export,
and capture a clean static image through the browser-backed widget path.

## Usage

``` r
snapshot_ggwebgl(
  x,
  file,
  width = 1800L,
  height = 1200L,
  format = NULL,
  dpi = 300,
  background = "white",
  preset = c("clean", "publication"),
  selfcontained = FALSE,
  wait_seconds = 3,
  show_panel_overlay = FALSE,
  elementId = NULL
)
```

## Arguments

- x:

  A `ggplot`, `ggWebGL` htmlwidget, `ggwebgl_spec`, raw renderer payload
  accepted by
  [`ggWebGL()`](https://fbertran.github.io/ggWebGL/reference/ggWebGL.md),
  or a
  [`ggwebgl_publication_figure()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_publication_figure.md).

- file:

  Output file path.

- width, height:

  Output size in pixels.

- format:

  Optional image format. When omitted, it is inferred from `file`.

- dpi:

  Output density metadata used when writing the image.

- background:

  Background colour used for the final flattened image.

- preset:

  Export preset. `"clean"` removes UI chrome; `"publication"` also
  applies subtle panel-strip and panel-frame styling for publication
  capture.

- selfcontained:

  Passed through to
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html)
  for the temporary export widget.

- wait_seconds:

  Delay before capture to allow the widget to finish rendering.

- show_panel_overlay:

  Whether facet/panel overlays should remain visible in the captured
  output.

- elementId:

  Optional DOM element id passed when `x` must first be turned into a
  widget.

## Value

The normalized output file path, invisibly.

## Examples

``` r
old <- options(ggwebgl.reset_processx_supervisor = TRUE)
on.exit(options(old), add = TRUE)

tiny_spec <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(
      data.frame(x = c(0.15, 0.5, 0.82), y = c(0.25, 0.78, 0.4)),
      x = "x",
      y = "y",
      colour = c("#0f766e", "#f97316", "#2563eb"),
      alpha = 0.8,
      size = 5
    )
  ),
  webgl = list(shader = "default", interactions = character())
)

out <- tempfile(fileext = ".jpg")
snapshot_ggwebgl(
  tiny_spec,
  out,
  width = 320,
  height = 220,
  format = "jpeg",
  preset = "clean",
  wait_seconds = 0.25
)
file.exists(out)
#> [1] TRUE
```
