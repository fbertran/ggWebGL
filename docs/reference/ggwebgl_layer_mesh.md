# Renderer-Ready Mesh Layer

Build an indexed triangle mesh layer for downstream adapters. Triangle
indices are supplied as one-based R indices and normalized to zero-based
WebGL indices in the returned payload.

## Usage

``` r
ggwebgl_layer_mesh(
  vertices,
  x = NULL,
  y = NULL,
  z = NULL,
  triangles = NULL,
  i = NULL,
  j = NULL,
  k = NULL,
  colour = NULL,
  rgba = NULL,
  alpha = NULL,
  id = NULL,
  scalar = NULL,
  normals = NULL,
  material = ggwebgl_material(),
  shading = NULL,
  pick_id = NULL,
  panel_id = 1L,
  geom = "adapter_mesh",
  wireframe = NULL
)
```

## Arguments

- vertices:

  Data frame, `ggwebgl_mesh` object, or list accepted by
  [`as_mesh_webgl()`](https://fbertran.github.io/ggWebGL/reference/as_mesh_webgl.md).

- x, y:

  Coordinate vectors or column names in `data`.

- z:

  Optional z coordinate vector or column name. Defaults to zero.

- triangles:

  Optional data frame supplying triangle index columns.

- i, j, k:

  One-based triangle index vectors or column names.

- colour:

  Optional colour vector or column name. Ignored when `rgba` is
  supplied.

- rgba:

  Optional renderer-ready RGBA matrix/data frame with four columns, or
  vector of length `n * 4`, using values in `[0, 1]` or `[0, 255]`.

- alpha:

  Optional alpha vector or column name used with `colour`.

- id:

  Optional stable primitive id vector or column name for selection.

- scalar:

  Optional per-vertex scalar vector or column name.

- normals:

  Optional vertex-normal matrix/data frame/vector or `"auto"`.

- material:

  Mesh material created by
  [`ggwebgl_material()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_material.md).

- shading:

  Optional mesh shader mode overriding `material$shading`.

- pick_id:

  Optional face picking ids. Length must be one or the number of
  triangles.

- panel_id:

  Scalar panel identifier for this layer.

- geom:

  Debug geom name recorded in the payload.

- wireframe:

  Legacy shortcut for `material$wireframe`.

## Value

A normalized mesh layer list.

## Examples

``` r
vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0))
triangles <- data.frame(i = 1L, j = 2L, k = 3L)
ggwebgl_layer_mesh(vertices, x = "x", y = "y", z = "z", triangles = triangles)
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "mesh"
#> 
#> $geom
#> [1] "adapter_mesh"
#> 
#> $rows
#> [1] 1
#> 
#> $vertex_count
#> [1] 3
#> 
#> $triangle_count
#> [1] 1
#> 
#> $x
#> [1] 0 1 0
#> 
#> $y
#> [1] 0 0 1
#> 
#> $z
#> [1] 0 0 0
#> 
#> $indices
#> [1] 0 1 2
#> 
#> $wire_indices
#> [1] 0 1 1 2 0 2
#> 
#> $normal
#> [1] 0 0 1 0 0 1 0 0 1
#> 
#> $rgba
#>  [1] 0.1725490 0.2431373 0.3137255 1.0000000 0.1725490 0.2431373 0.3137255
#>  [8] 1.0000000 0.1725490 0.2431373 0.3137255 1.0000000
#> 
#> $material
#> $material$shading
#> [1] "mesh_flat"
#> 
#> $material$ambient
#> [1] 0.35
#> 
#> $material$diffuse
#> [1] 0.75
#> 
#> $material$specular
#> [1] 0
#> 
#> $material$light_dir
#> [1] 0.35 0.45 0.82
#> 
#> $material$wireframe
#> [1] FALSE
#> 
#> $material$cull
#> [1] "back"
#> 
#> 
#> $wireframe
#> [1] FALSE
#> 
#> $bbox3d
#> $bbox3d$xmin
#> [1] 0
#> 
#> $bbox3d$xmax
#> [1] 1
#> 
#> $bbox3d$ymin
#> [1] 0
#> 
#> $bbox3d$ymax
#> [1] 1
#> 
#> $bbox3d$zmin
#> [1] 0
#> 
#> $bbox3d$zmax
#> [1] 0
#> 
#> 
```
