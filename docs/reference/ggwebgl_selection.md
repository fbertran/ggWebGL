# Define ggWebGL Selection Behavior

Build a structured renderer-owned selection specification.

## Usage

``` r
ggwebgl_selection(
  mode = c("none", "brush", "lasso", "brush_lasso"),
  highlight = TRUE,
  emit = TRUE
)
```

## Arguments

- mode:

  Selection mode: `"none"`, `"brush"`, `"lasso"`, or `"brush_lasso"`.

- highlight:

  Whether selected primitives should be visibly highlighted.

- emit:

  Whether selection payloads should be emitted to Shiny/callbacks.

## Value

A `ggwebgl_selection` list.

## Examples

``` r
ggwebgl_selection("brush_lasso")
#> $mode
#> [1] "brush_lasso"
#> 
#> $highlight
#> [1] TRUE
#> 
#> $emit
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "ggwebgl_selection" "list"             
```
