# Changelog

## ggWebGL 0.4.0

- Froze the experimental renderer API around structured
  [`ggwebgl_view()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_view.md),
  [`ggwebgl_selection()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_selection.md),
  and
  [`ggwebgl_material()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_material.md)
  contracts.
- Extended vector layers to support 3D `z`/`zend` coordinates while
  preserving renderer-owned ids, frame/time metadata, and browser
  selection behavior.
- Added distinct orbit and trackball camera control paths with
  normalized rotation-based camera state.
- Upgraded mesh and surface payloads with generated normals, Lambert
  material metadata, picking ids, wireframe/culling controls, and GPU
  payload caching hooks.
- Expanded the interaction-frame benchmark artifact schema so fixed
  frame-rate performance statements require device, browser, GPU,
  commit, primitive-count, and artifact metadata.
- Added a guarded optional downstream `boids4R` animation vignette and
  htmlwidget example that render renderer-neutral swarm frames as
  exact-timeline point and vector primitives. The examples keep
  `boids4R` as an optional development ecosystem package and avoid
  attaching its namespace during ggWebGL tests.
- Reframed the optional `boids4R` documentation as browser-native swarm
  art, clarifying that `boids4R` owns simulation semantics while
  `ggWebGL` owns WebGL rendering and timeline interaction.
- Prepared CRAN self-containment by removing GitHub-only ecosystem
  packages from `DESCRIPTION`, gating live optional bridge vignettes
  behind an explicit development environment variable, and documenting
  that `XGeoRTR`, `boids4R`, and `shapViz3D` are optional integrations
  rather than installation requirements.

## ggWebGL 0.3.0

- Added exported ggwebgl_magnify_region() in R/magnify-region.R, with
  panel and inset modes driven by an exact data-coordinate rectangle.
- Added experimental vector-arrow rendering through
  [`geom_vector_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_vector_webgl.md)
  and
  [`ggwebgl_layer_vectors()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_vectors.md),
  using renderer-ready shafts and triangle arrowheads without
  backend-specific semantics.
- Added experimental brush and lasso interaction modes that emit
  selected primitive ids through Shiny inputs or optional JavaScript
  callbacks.
- Added experimental timeline controls with frame/time filtering for
  primitive layers plus play, scrub, speed, and reset UI controls.
- Added experimental opt-in 3D camera state, 3D point/line support,
  indexed mesh payloads,
  [`geom_mesh_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_mesh_webgl.md),
  [`geom_surface_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_surface_webgl.md),
  [`ggwebgl_layer_mesh()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_mesh.md),
  and
  [`ggwebgl_layer_surface()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_surface.md).
- Added a renderer-generic future-work gallery and contract tests
  covering the new vector, selection, timeline, camera, mesh, and
  surface paths.
- Added an interaction-frame benchmark schema for frame-rate statements.
  Fixed performance numbers remain future-facing until generated
  benchmark artifacts exist for a named target machine.

## ggWebGL 0.2.0

- Promoted the package from the long-running development scaffold to the
  `0.2.0` release line.
- Added large-scene demo support: persistent point buffers for stable
  large point-cloud interaction, deterministic count-aware density
  splats, generic hover labels for point primitives, and a reproducible
  renderer gallery.
- Added generic downstream adapter helpers for renderer-ready point,
  line, and raster primitive specs, including exported
  `ggwebgl_layer_*()` constructors and
  [`ggwebgl_spec()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_spec.md).
- Added package-owned static export surfaces through
  [`snapshot_ggwebgl()`](https://fbertran.github.io/ggWebGL/reference/snapshot_ggwebgl.md)
  and
  [`compose_ggwebgl_figure()`](https://fbertran.github.io/ggWebGL/reference/compose_ggwebgl_figure.md),
  so publication-style PNG/JPEG captures and simple figure composition
  can be driven from the package API instead of ad hoc scripts.
- Added project evidence documentation and machine-readable evidence
  summaries for internal release validation.
- Added vignette-local figure copies for website articles that need
  images without referencing files outside pkgdown’s allowed article
  asset paths.
- Tightened the browser-backed static export path around dedicated
  `chromote` browser ownership, lighter examples, and explicit optional
  dependency declarations for export and vignette tooling.
- Fixed pkgdown/htmlwidget layout containment by restoring the widget
  CSS dependency and adding inline canvas-stage safeguards, preventing
  WebGL canvases from stacking at the top of article pages.

## ggWebGL 0.1.0

- Expanded the core renderer beyond the initial scaffold with reusable
  showcase helpers, manual htmlwidget and Shiny smoke tests, and a
  stronger pkgdown-facing documentation surface.
- Implemented and stabilized the main point shader modes: `default`,
  `density_splat`, `trajectory_age`, and `trajectory_age_glow`.
- Added hover-based sample inspection on top of the existing pan and
  zoom interactions.
- Added texture-backed raster rendering for
  [`geom_raster_webgl()`](https://fbertran.github.io/ggWebGL/reference/geom_raster_webgl.md).
- Added fixed-scale
  [`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
  and
  [`facet_grid()`](https://ggplot2.tidyverse.org/reference/facet_grid.html)
  support through a panel-aware render specification and panel-local
  interaction state.
- Added packaged real-data evidence examples covering raster fields,
  storm trajectories, and dense embeddings.
- Added a reproducible evaluation suite against `ggplot2` and `plotly`,
  including machine-readable metrics and benchmark figure scripts under
  `inst/benchmarks/`.
- Froze the XGeoRTR/ggWebGL renderer boundary in `RENDERER_CONTRACT.md`
  and added the first
  [`as_ggwebgl_spec.xgeo_state()`](https://fbertran.github.io/ggWebGL/reference/as_ggwebgl_spec.xgeo_state.md)
  adapter plus renderer contract tests.

## ggWebGL 0.0.0.9000

- Reset package metadata and top-level documentation from the copied
  scaffold to the `ggWebGL` package identity.
- Rewrote the package README, citation, and pkgdown configuration around
  the intended `ggplot2` plus WebGL rendering workflow and
  companion-package split.
- Removed imported carryover benchmark content from the copied package
  tree.
- Added the first real
  [`ggplot_webgl()`](https://fbertran.github.io/ggWebGL/reference/ggplot_webgl.md)
  renderer path for point and line layers, backed by a minimal WebGL
  htmlwidget.
- Added the initial showcase vignette and gallery, including dense
  latent-space, diffusion-trajectory, phase-portrait, and
  optimization-path examples.
- Added reusable `standard` and `high_detail` showcase presets for the
  gallery and demo surfaces.
