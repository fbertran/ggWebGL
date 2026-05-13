# Surface and mesh rendering with ggWebGL

## Purpose

`ggWebGL` separates structured surfaces from unstructured meshes.
Structured surfaces are rectilinear grids that can carry height
colormaps, normals, wireframes, and optional contour overlays. Meshes
are indexed triangle geometry with scalar coloring, wireframe edges, and
renderer-owned face or vertex ids.

Both examples below use small deterministic in-memory data. They are
intended to show the renderer contracts, not to report performance
numbers.

## Structured Surface

The `volcano` matrix is converted with
[`surface_matrix()`](https://fbertran.github.io/ggWebGL/reference/surface_matrix.md)
and rendered as a first-class surface primitive. The widget uses a
perspective orbit view and the `surface_height_colormap` shader.

``` r
surface_gallery_volcano_widget(height = 460)
```

## Unstructured Mesh

The mesh example uses explicit vertices and triangle indices. Scalar
values are stored on vertices and displayed with `mesh_scalar_colormap`;
face ids remain available to the renderer for hover or selection
payloads.

``` r
surface_gallery_mesh_widget(height = 460)
```

## Notes

The core package keeps rendering in the browser through WebGL. Any
expensive terrain preprocessing, mesh simplification, or device-specific
acceleration is left to upstream analysis code or optional companion
tooling.
