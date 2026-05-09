# Add Timeline Metadata to a ggplot

`scale_time_webgl()` is not a visual ggplot2 scale. It records timeline
metadata for
[`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md)
so frame or time values can be normalized into `render$timeline`.

## Usage

``` r
scale_time_webgl(
  source = c("auto", "frame", "time"),
  values = NULL,
  mode = c("exact", "cumulative"),
  fps = NULL,
  speed = 1,
  loop = FALSE,
  label = NULL,
  format = NULL
)
```

## Arguments

- source:

  Timeline column source. `"auto"` prefers a built `time` column when
  present and otherwise uses `frame`.

- values:

  Optional explicit timeline values. When omitted, values are derived
  from built layer `time` or `frame` columns.

- mode:

  Timeline filtering intent: `"exact"` or `"cumulative"`.

- fps:

  Optional frames-per-second metadata.

- speed:

  Positive playback-speed multiplier.

- loop:

  Whether future playback controls should loop.

- label:

  Optional timeline label metadata.

- format:

  Optional display-format metadata.

## Value

An object that can be added to a `ggplot`.

## Examples

``` r
df <- data.frame(x = c(0, 1, 2), y = c(0, 1, 0), frame = 1:3)
plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, frame = frame)) +
  geom_point_webgl() +
  scale_time_webgl(source = "frame", mode = "exact")
plot$ggwebgl$time_scale$source
#> [1] "frame"
```
