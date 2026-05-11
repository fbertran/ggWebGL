# Define ggWebGL Runtime Interactions

Build a structured interaction specification for widget-owned hover,
click, brush/lasso, camera, and Shiny event behavior. Existing character
`interactions` vectors remain supported; this helper is the normalized
contract for new code.

## Usage

``` r
ggwebgl_interactions(
  hover = TRUE,
  click = TRUE,
  brush = FALSE,
  lasso = FALSE,
  camera = TRUE,
  shiny = TRUE
)
```

## Arguments

- hover:

  Enable hover picking and tooltip/event emission.

- click:

  Enable click picking and event emission.

- brush:

  Enable rectangular brush selection.

- lasso:

  Enable lasso selection.

- camera:

  Enable camera-state event emission for 3D interactions.

- shiny:

  Enable Shiny event emission when a Shiny runtime is present.

## Value

A `ggwebgl_interactions` list.

## Examples

``` r
ggwebgl_interactions(brush = TRUE)
#> $hover
#> [1] TRUE
#> 
#> $click
#> [1] TRUE
#> 
#> $brush
#> [1] TRUE
#> 
#> $lasso
#> [1] FALSE
#> 
#> $camera
#> [1] TRUE
#> 
#> $shiny
#> [1] TRUE
#> 
#> $modes
#> [1] "hover"  "click"  "brush"  "camera"
#> 
#> attr(,"class")
#> [1] "ggwebgl_interactions" "list"                
```
