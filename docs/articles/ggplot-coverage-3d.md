# Experimental 3D, mesh, and surface WebGL layers

The 3D and indexed-geometry APIs are exported for browser-side WebGL
rendering, but they remain experimental because camera, picking, and
material behavior may still evolve. Evaluation is disabled during CRAN,
package checks, and CI unless explicitly enabled with
`GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` or `NOT_CRAN=true`. Live WebGL
widgets are additionally disabled unless
`GGWEBGL_EVAL_LIVE_WIDGETS=true` is set. Rich local or pkgdown builds
should set both `GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` and
`GGWEBGL_EVAL_LIVE_WIDGETS=true`.

## Experimental 3D, Mesh, and Surface Layers

Use
[`coord_webgl_3d()`](https://fbertran.github.io/ggWebGL/reference/coord_webgl_3d.md)
to opt into a 3D camera path for grammar-style plots. The same scene
contract can also be produced through renderer-ready mesh and surface
helpers.

### Applet: 3D helix path

``` r
helix_t <- seq(0, 4 * pi, length.out = 80)
helix <- data.frame(
  x = cos(helix_t),
  y = sin(helix_t),
  z = helix_t / max(helix_t),
  time = helix_t,
  group = "helix"
)

p <- ggplot(helix, aes(x, y, z = z, group = group, time = time)) +
  geom_path3d_webgl(colour = "#2563eb") +
  coord_webgl_3d() +
  labs(title = "3D helix path")

ggplot_webgl(p, height = 420)
```

### Applet: Structured surface

Structured surfaces use a regular grid.

``` r
surface_grid <- expand.grid(
  x = seq(-1, 1, length.out = 12),
  y = seq(-1, 1, length.out = 12),
  KEEP.OUT.ATTRS = FALSE
)
surface_grid$z <- with(surface_grid, exp(-(x^2 + y^2)))

p <- ggplot(surface_grid, aes(x, y, z = z, fill = z)) +
  geom_surface_webgl(shading = "surface_height_colormap") +
  coord_webgl_3d() +
  labs(title = "Structured surface")

ggplot_webgl(p, height = 420)
```

### Applet: Unstructured mesh

Unstructured meshes can be supplied with explicit vertices and triangle
indices.

``` r
mesh_vertices <- data.frame(
  x = c(0, 1, 0, 0),
  y = c(0, 0, 1, 0),
  z = c(0, 0, 0, 1),
  scalar = c(0, 1, 1, 0.5),
  i = c(1, 1, 1, 2),
  j = c(2, 2, 3, 3),
  k = c(3, 4, 4, 4)
)

p <- ggplot(mesh_vertices, aes(x, y, z = z, i = i, j = j, k = k, scalar = scalar)) +
  geom_mesh_webgl(shading = "mesh_scalar_colormap") +
  coord_webgl_3d() +
  labs(title = "Unstructured mesh")

ggplot_webgl(p, height = 420)
```

## 3D View and Camera Notes

- [`coord_webgl_3d()`](https://fbertran.github.io/ggWebGL/reference/coord_webgl_3d.md)
  requests a 3D coordinate system and an orbit-style camera.
- Surface layers are structured-grid primitives; arbitrary triangle data
  belongs in mesh layers.
- The 3D APIs are experimental and should be treated as browser-side
  rendering paths, not as native GPU preprocessing pipelines.
