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
  filter = c("exact", "cumulative")
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

## Value

A `ggwebgl_timeline` list.

## Examples

``` r
ggwebgl_timeline(frames = 1:4, autoplay = FALSE)
#> $frames
#> [1] 1 2 3 4
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
#> attr(,"class")
#> [1] "ggwebgl_timeline" "list"            
```
