# Getting Started with ggWebGL

## Overview

`ggWebGL` currently provides a browser-native WebGL backend for a
focused subset of `ggplot2`.

## Current capabilities

The current implementation provides:

- WebGL rendering for point, line, and raster layers
- four point shader modes: `default`, `density_splat`, `trajectory_age`,
  and `trajectory_age_glow`
- interactive `pan`, `zoom`, and optional `hover` inspection
- fixed-scale
  [`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
  and
  [`facet_grid()`](https://ggplot2.tidyverse.org/reference/facet_grid.html)
  layouts
- [`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md)
  for htmlwidget conversion
- Shiny bindings and manual smoke-test examples under `inst/examples/`
- packaged real-data evidence examples and an evaluation suite under
  `inst/benchmarks/`

## Example

``` r
library(ggplot2)
library(ggWebGL)

plot <- ggplot(diamonds, aes(carat, price, colour = cut)) +
  geom_point_webgl(size = 1.1, alpha = 0.18) +
  theme_webgl(
    shader = "density_splat",
    interactions = c("pan", "zoom", "hover")
  )

ggplot_webgl(plot, height = 520)
```
