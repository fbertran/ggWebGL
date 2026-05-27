# ggplot-like geom coverage in ggWebGL

This overview links to the smaller coverage vignettes. The live applets
are split across multiple pages to keep browser WebGL context use
moderate and to make the article navigation readable.

## Coverage Articles

- [Core ggplot-like WebGL
  layers](https://fbertran.github.io/ggWebGL/articles/ggplot-coverage-core.md):
  grammar-style workflow, renderer-ready specifications, core
  two-dimensional layers, rectangles, tiles, and bins.
- [Statistical and annotation WebGL
  layers](https://fbertran.github.io/ggWebGL/articles/ggplot-coverage-summaries.md):
  curves, contours, range summaries, filled regions, raster grids,
  annotation overlays, and fixed-scale facets.
- [Experimental 3D, mesh, and surface WebGL
  layers](https://fbertran.github.io/ggWebGL/articles/ggplot-coverage-3d.md):
  3D paths, structured-grid surfaces, unstructured meshes, and camera
  notes.

## Status Labels

The split vignettes use conservative status labels:

- `Stable`: core two-dimensional APIs with mature tests and renderer
  contracts.
- `Experimental`: exported and tested APIs whose rendering contract or
  interaction details may still evolve.
- `Metadata-only`: metadata serialization without a claim of full
  runtime parity.

These labels reflect API maturity, test coverage, and rendering-contract
stability; they are not simply an export list.
