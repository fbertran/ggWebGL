# ggWebGL, Browser-Native ‘WebGL’ Rendering for R Graphics ![logo ggWebGL](reference/figures/logo_ggWebGL.png)

## Frédéric Bertrand

`ggWebGL` is an R package for browser-native `WebGL` rendering of R
graphics through `htmlwidgets`. It supports grammar-style graphics
workflows and renderer-ready specifications for dense analytical and
scientific scenes. The stable current scope covers point, line,
trajectory, raster, fixed-scale facet, shader, pan/zoom/hover, `Shiny`,
and publication-oriented static export paths. Vector, mesh, surface,
timeline, brush/lasso, and structured 3D view support are implemented
`ggWebGL` public APIs and optional GeoXGL extension classes.

The package keeps rendering in the browser and avoids any mandatory
`CUDA`, `Metal`, or `OpenCL` toolchain. Heavier preprocessing,
large-data preparation, and device-specific acceleration are left to
companion packages.

Suggested integrations extend this renderer boundary without becoming
core requirements: `XGeoRTR` can provide explainable-geometry state that
is adapted to renderer-ready primitives, and `boids4R` can provide swarm
simulation frames rendered as animated point/vector timelines. These
packages own their domain semantics; `ggWebGL` owns the browser renderer
and widget behavior.

## Scope

`ggWebGL` provides two complementary interfaces:

- grammar-style layers for selected `ggplot2` workflows;
- renderer-ready layer and specification helpers for downstream packages
  or custom visualization pipelines.

The package provides browser-native rendering, widget construction,
renderer-ready specifications, shader modes, interaction contracts,
optional extension classes, and static export surfaces. It does not
implement downstream scientific, simulation, topological,
model-explanation, or domain-specific semantics. Those semantics should
enter `ggWebGL` through explicit adapter boundaries such as
backend-neutral tables, renderer-ready primitive layers, or
`ggwebgl_spec` payloads.

## Stable current scope

The current implementation supports:

| Feature | Current status |
|----|----|
| [`geom_point_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_point_webgl.md) | Rendered in `WebGL` |
| [`geom_line_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_line_webgl.md) | Rendered in `WebGL` |
| [`geom_raster_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_raster_webgl.md) | Rendered in `WebGL` |
| Renderer-ready stable layers | Points, lines, and rasters through `ggwebgl_layer_*()` helpers |
| Renderer specification | [`ggwebgl_spec()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_spec.md) and [`as_ggwebgl_spec()`](https://fbertran.github.io/ggWebGL/reference/as_ggwebgl_spec.md) adapter boundaries |
| Shader modes | `default`, `density_splat`, `trajectory_age`, `trajectory_age_glow`, `trajectory_velocity`, `trajectory_direction` |
| Interaction | `pan`, `zoom`, and `hover` |
| Output targets | R Markdown / Quarto HTML, `Shiny`, and static image export helpers |
| `ggplot2` compatibility | Focused grammar-preserving paths for dense scenes and fixed-scale facets |
| Unsupported facet mode | Free x/y scales fall back to metadata |

## Implemented optional extension classes

These are implemented `ggWebGL` public APIs and are covered by package
tests, examples, or vignettes. They are optional GeoXGL extension
classes rather than requirements of the minimal stable GeoXGL scene
contract.

| Feature | Evidence |
|----|----|
| [`geom_vector_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_vector_webgl.md) and [`ggwebgl_layer_vectors()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_vectors.md) for vector-arrow layers | `tests/testthat/test-future-work-roadmap.R`, `vignettes/renderer-capabilities.Rmd` |
| [`geom_mesh_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_mesh_webgl.md), [`geom_surface_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_surface_webgl.md), [`ggwebgl_layer_mesh()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_mesh.md), and [`ggwebgl_layer_surface()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_surface.md) for mesh/surface payloads | `tests/testthat/test-future-work-roadmap.R`, `tests/testthat/test-interaction-runtime.R`, `vignettes/renderer-capabilities.Rmd` |
| [`ggwebgl_timeline()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_timeline.md) for exact/cumulative frame controls and timeline-aware trajectories | `tests/testthat/test-future-work-roadmap.R`, `tests/testthat/test-interaction-runtime.R`, `tests/testthat/test-timeline-metadata.R`, `vignettes/renderer-capabilities.Rmd`, `vignettes/temporal-trajectories.Rmd` |
| [`ggwebgl_selection()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_selection.md) for brush/lasso selection metadata and browser interaction | `tests/testthat/test-future-work-roadmap.R`, `tests/testthat/test-interaction-runtime.R`, `vignettes/renderer-capabilities.Rmd` |
| [`ggwebgl_view()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_view.md) for structured 2D/3D view and camera metadata | `tests/testthat/test-future-work-roadmap.R`, `tests/testthat/test-interaction-runtime.R`, `vignettes/renderer-capabilities.Rmd` |

`ggWebGL` is not a full replacement for `ggplot2`. It is a
browser-native `WebGL` rendering backend with both grammar-style front
ends and explicit renderer-ready adapter boundaries.

## Installation

``` r
install.packages("ggWebGL")
```

For the development version:

``` r
# install.packages("remotes")
remotes::install_github("fbertran/ggWebGL")
```

## Basic use

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

## Renderer-ready specifications

`ggWebGL` can also render explicit primitive layers without requiring
the input to originate from a `ggplot2` object.

``` r
library(ggWebGL)

points <- ggwebgl_layer_points(
  data.frame(
    x = c(0, 1, 2),
    y = c(2, 1, 0),
    colour = c("#0f766e", "#f97316", "#2563eb")
  ),
  x = "x",
  y = "y",
  colour = "colour",
  size = 4
)

spec <- ggwebgl_spec(
  layers = list(points),
  labels = list(title = "Renderer-ready point layer")
)

ggWebGL(spec, height = 420)
```

## Architecture

1.  Parse stable grammar-style point, line, raster, and fixed-scale
    facet layers.
2.  Normalize parsed layers into a renderer-scene contract.
3.  Accept renderer-ready primitive payloads from explicit adapter
    boundaries.
4.  Accept implemented optional extension classes for vectors, meshes,
    surfaces, timelines, selection metadata, and structured views when
    callers opt in.
5.  Resolve raster fills and styling metadata on the R side.
6.  Bind panel-local payloads to browser-side `WebGL` buffers, textures,
    attributes, and shader modes.
7.  Render interactively through an `htmlwidgets` widget.
8.  Reuse the same widget in `Shiny`.

For static capture and publication workflows, `ggWebGL` exposes:

- [`snapshot_ggwebgl()`](https://fbertran.github.io/ggWebGL/reference/snapshot_ggwebgl.md)
  for PNG/JPEG captures;
- [`compose_ggwebgl_figure()`](https://fbertran.github.io/ggWebGL/reference/compose_ggwebgl_figure.md)
  for figure assembly, labels, and lightweight annotations.
