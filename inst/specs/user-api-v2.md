# ggWebGL User API v2 Direction

This note describes the intended user-facing direction for APIs that target
Render Schema v2. It is a planning contract, not a promise that every listed
surface is mature in the current release.

## Current Stable Entry Points

- `ggplot_webgl()` converts supported `ggplot2` layers into normalized renderer
  scenes.
- `ggWebGL()` renders normalized scenes, adapter specs, widgets, and compatible
  raw payloads.
- `ggwebgl_spec()` assembles renderer-ready primitive layers without requiring a
  `ggplot2` object.
- `theme_webgl()` carries renderer options for grammar-style workflows.

## Current Primitive APIs

The current core already accepts these renderer-ready layer helpers:

- `ggwebgl_layer_points()`
- `ggwebgl_layer_lines()`
- `ggwebgl_layer_raster()`
- `ggwebgl_layer_vectors()`
- `ggwebgl_layer_mesh()`
- `ggwebgl_layer_surface()`, which emits first-class structured-grid surface payloads

The current grammar-style geoms include:

- `geom_point_webgl()`
- `geom_line_webgl()`
- `geom_raster_webgl()`
- `geom_vector_webgl()`
- `geom_mesh_webgl()`
- `geom_surface_webgl()`

## v2 API Direction

The v2 API direction is to make these concepts explicit without adding
backend-specific semantics:

- 2D and 3D coordinate systems through structured view metadata.
- 3D path support as grouped lines with `z` coordinates.
- Shader selection as renderer hints, not backend compute instructions.
- Timeline controls as renderer-owned frame or time filters.
- Brush, lasso, hover, and linked magnification as renderer-owned interaction
  events that report primitive ids.
- Mesh and surface rendering as browser WebGL primitives with material and
  picking metadata.

The shorthand API shape is:

```r
ggplot_webgl(
  plot,
  webgl = webgl_spec(
    camera = "orbit",
    shader = "density_splat",
    interactions = c("pan", "zoom", "hover", "brush", "select"),
    timeline = ggwebgl_timeline(frames = 1:10, autoplay = FALSE)
  )
)
```

Current code may use `webgl_spec()` for compact renderer options or the more
structured `theme_webgl()`, `ggwebgl_view()`, `ggwebgl_selection()`, and
`ggwebgl_timeline()` helpers when composing ggplot objects incrementally.

## Companion Package Boundary

Core `ggWebGL` must stay portable and browser-side. Heavy preprocessing belongs
outside the core package, including:

- Native GPU acceleration, including any future `ggWebGL.gpu` companion;
- CUDA, Metal, OpenCL, or device-specific kernels;
- large-data decimation and level-of-detail generation;
- expensive meshing or triangulation pipelines;
- domain-specific state, diagnostics, explanations, or simulations.

Optional companion packages may produce renderer-ready `ggwebgl_spec()` payloads
or implement `as_ggwebgl_spec.<class>()` methods. The core renderer should never
need to understand companion-package semantics to draw the scene.
