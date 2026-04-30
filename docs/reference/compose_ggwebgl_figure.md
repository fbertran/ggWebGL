# Compose a Publication Figure from ggWebGL Panels

Capture one or more ggWebGL scenes and assemble them into a single clean
publication image.

## Usage

``` r
compose_ggwebgl_figure(
  panels,
  file,
  width = 1800L,
  height = 1200L,
  format = NULL,
  dpi = 300,
  background = "white",
  layout = c("single", "row", "grid"),
  labels = NULL,
  inset = NULL,
  annotations = NULL,
  preset = c("clean", "publication"),
  selfcontained = FALSE,
  wait_seconds = 3,
  nrow = NULL,
  ncol = NULL,
  elementId = NULL
)
```

## Arguments

- panels:

  A list of panel sources. Each element may be a `ggplot`, `ggWebGL`
  widget, `ggwebgl_spec`, raw renderer payload, image path, or a list
  with `source` plus optional `wait_seconds`, `show_panel_overlay`, and
  `preset` overrides.

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

- layout:

  One of `"single"`, `"row"`, or `"grid"`.

- labels:

  Optional character vector of panel labels drawn in the top-left corner
  of each occupied panel cell.

- inset:

  Optional list with a panel `source`, fractional `left`, `top`,
  `width`, `height`, and optional `border`, `border_colour`, and
  `border_alpha`.

- annotations:

  Optional list of text annotations. Each entry should contain `text`
  plus fractional `x` and `y`, with optional `size`, `colour`, `font`,
  `hjust`, and `vjust`.

- preset:

  Export preset. `"publication"` adds subtle panel borders and muted
  label styling.

- selfcontained:

  Passed through to
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html)
  for temporary widget captures.

- wait_seconds:

  Default render delay before capture.

- nrow, ncol:

  Optional grid dimensions used when `layout = "grid"`.

- elementId:

  Optional DOM element id passed when panel sources must first be turned
  into widgets.

## Value

The normalized output file path, invisibly.

## Examples

``` r
old <- options(ggwebgl.reset_processx_supervisor = TRUE)
on.exit(options(old), add = TRUE)

point_spec <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(
      data.frame(x = c(0.15, 0.48, 0.82), y = c(0.22, 0.76, 0.38)),
      x = "x",
      y = "y",
      colour = c("#0f766e", "#f97316", "#2563eb"),
      alpha = 0.8,
      size = 5
    )
  ),
  webgl = list(shader = "default", interactions = character())
)
line_spec <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_lines(
      data.frame(x = c(0.1, 0.45, 0.8), y = c(0.25, 0.75, 0.35)),
      x = "x",
      y = "y",
      colour = "#334155",
      alpha = 0.9,
      width = 2
    )
  ),
  webgl = list(shader = "default", interactions = character())
)

out <- tempfile(fileext = ".jpg")
compose_ggwebgl_figure(
  panels = list(
    point_spec,
    line_spec
  ),
  file = out,
  layout = "row",
  labels = c("points", "lines"),
  width = 480,
  height = 240,
  format = "jpeg",
  preset = "clean",
  wait_seconds = 0.25
)
file.exists(out)
#> [1] TRUE
```
