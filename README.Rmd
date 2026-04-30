---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->

# ggWebGL, Browser-Native 'WebGL' Rendering for R Graphics <img src="man/figures/logo_ggWebGL.png" align="right" width="200"/>
## Frédéric Bertrand

`ggWebGL` is an R package for browser-native `WebGL` rendering of R graphics
through `htmlwidgets`. It supports grammar-style graphics workflows and
renderer-ready specifications for dense analytical and scientific scenes,
including point, line, trajectory, raster, vector, mesh, and surface layers,
shader-driven display modes, timeline controls, structured views, selection
metadata, `Shiny` output, and publication-oriented static export helpers.

The package keeps rendering in the browser and avoids any mandatory `CUDA`,
`Metal`, or `OpenCL` toolchain. Heavier preprocessing, large-data preparation,
and device-specific acceleration are left to companion packages.

## Scope

`ggWebGL` provides two complementary interfaces:

- grammar-style layers for selected `ggplot2` workflows;
- renderer-ready layer and specification helpers for downstream packages or
  custom visualization pipelines.

The package provides browser-native rendering, widget construction,
renderer-ready specifications, shader modes, interaction contracts, structured
views, timelines, and static export surfaces. It does not implement downstream
scientific, simulation, topological, model-explanation, or domain-specific
semantics. Those semantics should enter `ggWebGL` through explicit adapter
boundaries such as backend-neutral tables, renderer-ready primitive layers, or
`ggwebgl_spec` payloads.

## Status

The current implementation supports:

| Feature | Current status |
| --- | --- |
| `geom_point_webgl()` | Rendered in `WebGL` |
| `geom_line_webgl()` | Rendered in `WebGL` |
| `geom_raster_webgl()` | Rendered in `WebGL` |
| `geom_vector_webgl()` | Renderer path for vector-arrow layers |
| `geom_mesh_webgl()` | Renderer path for indexed mesh layers |
| `geom_surface_webgl()` | Renderer path for triangulated surface layers |
| Renderer-ready layers | Points, lines, vectors, rasters, meshes, and surfaces through `ggwebgl_layer_*()` helpers |
| Renderer specification | `ggwebgl_spec()` and `as_ggwebgl_spec()` adapter boundaries |
| Shader modes | `default`, `density_splat`, `trajectory_age`, `trajectory_age_glow` |
| Interaction | `pan`, `zoom`, `hover`; visible `brush` and `lasso` selection through `ggwebgl_selection()` |
| Runtime controls | Exact/cumulative timeline controls through `ggwebgl_timeline()` |
| View contract | Structured 2D/3D view and camera metadata through `ggwebgl_view()` |
| Output targets | R Markdown / Quarto HTML, `Shiny`, and static image export helpers |
| `ggplot2` compatibility | Focused grammar-preserving paths for dense scenes and fixed-scale facets |
| Unsupported facet mode | Free x/y scales fall back to metadata |

`ggWebGL` is not a full replacement for `ggplot2`. It is a browser-native
`WebGL` rendering backend with both grammar-style front ends and explicit
renderer-ready adapter boundaries.

## Installation

```r
install.packages("ggWebGL")
```

For the development version:

```r
# install.packages("remotes")
remotes::install_github("fbertran/ggWebGL")
```

## Basic use

```r
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

`ggWebGL` can also render explicit primitive layers without requiring the input
to originate from a `ggplot2` object.

```r
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

1. Parse supported grammar-style point, line, raster, vector, mesh, surface, and
   fixed-scale facet layers.
2. Normalize parsed layers into a renderer-scene contract.
3. Accept renderer-ready primitive payloads from explicit adapter boundaries.
4. Resolve raster fills and styling metadata on the R side.
5. Bind panel-local payloads to browser-side `WebGL` buffers, textures,
   attributes, and shader modes.
6. Render interactively through an `htmlwidgets` widget.
7. Reuse the same widget in `Shiny`.

For static capture and publication workflows, `ggWebGL` exposes:

- `snapshot_ggwebgl()` for PNG/JPEG captures;
- `compose_ggwebgl_figure()` for figure assembly, labels, and lightweight
  annotations.
