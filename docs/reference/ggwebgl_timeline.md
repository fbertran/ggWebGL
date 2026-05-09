# ggWebGL Timeline Controls

Build a lightweight runtime timeline specification for animated ggWebGL
scenes. Layers can opt into timeline filtering with `frame` or `time`
fields.

## Usage

``` r
ggwebgl_timeline(
  frames = NULL,
  time = NULL,
  duration = NULL,
  loop = TRUE,
  autoplay = FALSE,
  speed = 1,
  controls = TRUE,
  filter = c("exact", "cumulative"),
  values = NULL,
  source = c("auto", "frame", "time"),
  mode = NULL,
  fps = NULL
)
```

## Arguments

- frames:

  Optional integer frame values.

- time:

  Optional numeric time values.

- duration:

  Optional playback duration in seconds.

- loop:

  Whether playback should loop.

- autoplay:

  Whether playback should start automatically.

- speed:

  Playback speed multiplier.

- controls:

  Whether the widget should show timeline controls.

- filter:

  Timeline visibility mode. `"exact"` shows only samples matching the
  current frame or time. `"cumulative"` keeps samples up to the current
  frame or time.

- values:

  Optional frame or time values. Use `source` to choose whether they
  populate the frame or time axis.

- source:

  Timeline value source for `values`. `"auto"` uses frame values unless
  `time` is supplied.

- mode:

  Optional alias for `filter`.

- fps:

  Optional frames-per-second metadata for downstream controls.

## Value

A `ggwebgl_timeline` list.

## Examples

``` r
ggwebgl_timeline(frames = 1:4, autoplay = FALSE)
#> $frames
#> [1] 1 2 3 4
#> 
#> $values
#> [1] 1 2 3 4
#> 
#> $source
#> [1] "frame"
#> 
#> $loop
#> [1] TRUE
#> 
#> $autoplay
#> [1] FALSE
#> 
#> $speed
#> [1] 1
#> 
#> $controls
#> [1] TRUE
#> 
#> $filter
#> [1] "exact"
#> 
#> $mode
#> [1] "exact"
#> 
#> attr(,"class")
#> [1] "ggwebgl_timeline" "list"            
```
