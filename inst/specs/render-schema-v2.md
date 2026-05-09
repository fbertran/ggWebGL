# ggWebGL Render Schema v2

This document freezes the internal renderer-facing scene contract for the next
pipeline milestone. It is a schema target for `ggWebGL` itself and for optional
adapter packages that emit renderer-ready primitives. It is not a backend data
model and it does not assign semantic meaning to geometry, selections, or
animation states.

## Ownership

- `ggWebGL` owns browser rendering, htmlwidget and Shiny bindings, shaders,
  view/camera state, interaction state, timeline controls, and export surfaces.
- Adapter or companion packages own preprocessing, decimation, meshing, level of
  detail generation, diagnostics, and domain-specific semantics.
- The core package remains portable R plus browser WebGL. Native GPU or device
  preprocessing belongs in optional companion packages such as a future
  `ggWebGL.gpu`, not in the core render schema.

## Top-Level Scene

A v2 scene is a normalized list with these canonical fields:

- `labels`: title, subtitle, axis labels, and optional legend labels.
- `webgl`: renderer options after normalization.
- `layer_count`: number of source layers represented in debug metadata.
- `layers`: human/debug metadata only; renderer code reads panel-local layers.
- `render`: canonical render plan.

The v2 schema is compatible with current `ggwebgl_spec()` payloads. Existing
single-panel compatibility fields under `render$layers`, `render$viewport`, and
`render$panel` remain derived shims and must not become the canonical shape.

## Render Plan

`render` contains:

- `mode`: `"webgl"` or `"metadata"`.
- `coordinate_system`: `"cartesian2d"` or `"cartesian3d"`.
- `dimension`: compatibility field, `"2d"` or `"3d"`.
- `grid`: panel grid with `rows` and `cols`.
- `panels`: ordered panel contracts.
- aggregate counts: `point_count`, `line_vertex_count`, `path_count`,
  `raster_cell_count`, `vector_count`, `mesh_vertex_count`,
  `mesh_triangle_count`, `surface_vertex_count`, and
  `surface_triangle_count`.
- `primitives`: primitive kinds present in panel-local layers.
- `unsupported_layers`: unsupported source-layer metadata.
- `messages`: exact field name for renderer messages.
- optional `camera`, `selection`, `timeline`, `links`, and `legends`.
- render-state controls such as `depth_test` and `blend_mode`.

The compatibility rule is:

- if `coordinate_system` is absent and `dimension == "3d"`, consumers may infer
  `coordinate_system = "cartesian3d"`;
- otherwise consumers may infer `coordinate_system = "cartesian2d"`.

## Panels

Each `render$panels[[i]]` contains:

- `panel_id`, `row`, `col`, and optional `label`.
- `bounds`: normalized panel bounds inside the widget.
- `viewport`: panel-local coordinate ranges.
- `primitives`: primitive kinds in the panel.
- per-panel counts matching the aggregate fields.
- ordered `layers`: renderer-ready primitive layers.

Fixed-scale facets and multi-panel adapter specs use the same panel contract.
Free-scale behavior is outside this schema freeze unless represented by explicit
per-panel `viewport` ranges.

## Primitive Layers

Layer payloads are primitive-oriented and renderer-ready. They contain a
`type`, `geom`, `rows`, `panel_id`, styling, optional `frame` or `time`, and any
primitive-specific fields below.

### points

Fields: `x`, `y`, optional `z`, `size`, `age`, `rgba`, optional `label`, optional
stable `id`, optional `frame`, and optional `time`.

### lines

Fields: `path_count` and `paths`. Each path contains `group`, `x`, `y`,
optional `z`, `width`, `age`, `rgba`, optional `frame`, and optional `time`.

### path3d

Schema-level alias for grouped line paths with `z` coordinates in a
`cartesian3d` scene. Current runtime payloads may still use `type = "lines"`;
the alias exists so future API documentation can name 3D paths without adding a
separate runtime primitive in this milestone.

### raster

Fields: `width`, `height`, `xmin`, `xmax`, `ymin`, `ymax`, `interpolate`, and
texture-ready byte `rgba`.

### vectors

Fields: `x`, `y`, optional `z`, `xend`, `yend`, optional `zend`, `width`,
`head_size`, `rgba`, optional stable `id`, optional `frame`, and optional
`time`.

### mesh

Fields: vertex coordinates `x`, `y`, `z`, zero-based triangle `indices`,
optional vertex `normal`, per-vertex or per-face `rgba`, optional stable vertex
`id`, optional face `pick_id`, and optional `material`.

### surface

First-class structured-grid primitive for regular rectilinear surfaces. Fields:
flat `positions` (`x`, `y`, `z` triples), generated or supplied `normals`,
per-vertex `colors`, zero-based triangle `indices`, `bbox3d`,
`surface_meta`, and optional `wire_indices`, `contours`, and `uncertainty`.
Arbitrary triangle data remains `type = "mesh"`.

## Renderer Options

`webgl` owns normalized renderer options:

- shader mode or shader identifier.
- `rendering = "visualization"` or `"publication"`.
- `panel_overlay`.
- antialiasing, transparency, buffer size, line options, and unknown extras.
- `depth_test`, enabled by default for `cartesian3d` and disabled by default
  for `cartesian2d`.
- `blend_mode = "auto" | "alpha" | "additive" | "premultiplied"`.
- structured `view`, `selection`, and `timeline` options.

Unknown extras remain isolated in `webgl$extra` and are not a backend contract.

## Interaction, Animation, Shaders, And Legends

- Interaction metadata is renderer-owned. Selection payloads contain primitive
  ids and indices only; adapters map those ids back to domain objects.
- Animation metadata is renderer-owned and may be frame-based or time-based.
  `filter = "exact"` and `filter = "cumulative"` are the canonical timeline
  filters.
- Shader hints may be scene-level or layer-level. Unsupported shader hints must
  degrade to the current default shader with a renderer message.
- Legend metadata is optional. If present, it describes already-resolved labels
  and swatches; it must not require the renderer to interpret backend semantics.
