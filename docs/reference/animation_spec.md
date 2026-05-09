# Build Animation Timeline Metadata

`animation_spec()` is a user-facing alias for
[`ggwebgl_timeline()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_timeline.md).
It keeps one canonical timeline contract while providing a concise name
for animation examples and adapter code.

## Usage

``` r
animation_spec(...)
```

## Value

A `ggwebgl_timeline` list.

## Examples

``` r
animation_spec(frames = 1:3, autoplay = FALSE)
#> $frames
#> [1] 1 2 3
#> 
#> $values
#> [1] 1 2 3
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
