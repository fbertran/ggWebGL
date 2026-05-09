# Renderer-Ready Structured Surface Layer

Build a first-class structured-grid surface layer from a numeric matrix
or
[`surface_matrix()`](https://fbertran.github.io/ggWebGL/reference/surface_matrix.md)
object.

## Usage

``` r
ggwebgl_layer_surface(
  z,
  x = NULL,
  y = NULL,
  colour = NULL,
  rgba = NULL,
  alpha = NULL,
  palette = "Terrain 2",
  shading = c("surface_lambert", "surface_flat", "surface_height_colormap",
    "surface_uncertainty_alpha"),
  normals = "auto",
  material = NULL,
  uncertainty = NULL,
  pick_id = NULL,
  panel_id = 1L,
  geom = "adapter_surface",
  wireframe = FALSE,
  contours = FALSE,
  contour_levels = NULL,
  contour_colour = "#1f2937",
  contour_width = 1
)
```

## Arguments

- z:

  Numeric matrix or `ggwebgl_surface_matrix` object.

- x, y:

  Optional coordinate vectors for matrix input.

- colour:

  Optional colour vector. Ignored when `rgba` is supplied.

- rgba:

  Optional renderer-ready RGBA matrix/data frame with four columns, or
  vector of length `vertex_count * 4`, using values in `[0, 1]` or
  `[0, 255]`.

- alpha:

  Optional alpha vector used with `colour`.

- palette:

  HCL palette used when neither `colour` nor `rgba` is supplied.

- shading:

  Surface shader mode.

- normals:

  Normal-generation mode. `"auto"` computes vertex normals.

- material:

  Surface material created by
  [`ggwebgl_material()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_material.md).

- uncertainty:

  Optional per-vertex uncertainty values in `[0, 1]`.

- pick_id:

  Optional triangle picking ids.

- panel_id:

  Scalar panel identifier.

- geom:

  Debug geom name recorded in the payload.

- wireframe:

  Whether to request a wireframe overlay.

- contours:

  Whether to generate contour-line overlays on the R side.

- contour_levels:

  Optional numeric contour levels.

- contour_colour:

  Contour line colour.

- contour_width:

  Contour line width in renderer pixels.

## Value

A normalized structured surface layer list.

## Examples

``` r
ggwebgl_layer_surface(volcano[1:4, 1:4])
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "surface"
#> 
#> $geom
#> [1] "adapter_surface"
#> 
#> $rows
#> [1] 16
#> 
#> $vertex_count
#> [1] 16
#> 
#> $triangle_count
#> [1] 18
#> 
#> $positions
#>  [1]   1   1 100   2   1 100   3   1 101   4   1 101   1   2 101   2   2 101   3
#> [20]   2 102   4   2 102   1   3 102   2   3 102   3   3 103   4   3 103   1   4
#> [39] 103   2   4 103   3   4 104   4   4 104
#> 
#> $normals
#>  [1]  0.0000000 -0.7071068  0.7071068 -0.4264014 -0.6396021  0.6396021
#>  [7] -0.2294157 -0.6882472  0.6882472  0.0000000 -0.7071068  0.7071068
#> [13]  0.0000000 -0.7071068  0.7071068 -0.3333333 -0.6666667  0.6666667
#> [19] -0.3333333 -0.6666667  0.6666667  0.0000000 -0.7071068  0.7071068
#> [25]  0.0000000 -0.7071068  0.7071068 -0.3333333 -0.6666667  0.6666667
#> [31] -0.3333333 -0.6666667  0.6666667  0.0000000 -0.7071068  0.7071068
#> [37]  0.0000000 -0.7071068  0.7071068 -0.2294157 -0.6882472  0.6882472
#> [43] -0.4264014 -0.6396021  0.6396021  0.0000000 -0.7071068  0.7071068
#> 
#> $colors
#>  [1] 0.007843137 0.486274510 0.117647059 1.000000000 0.007843137 0.486274510
#>  [7] 0.117647059 1.000000000 0.498039216 0.615686275 0.262745098 1.000000000
#> [13] 0.498039216 0.615686275 0.262745098 1.000000000 0.498039216 0.615686275
#> [19] 0.262745098 1.000000000 0.498039216 0.615686275 0.262745098 1.000000000
#> [25] 0.752941176 0.721568627 0.470588235 1.000000000 0.752941176 0.721568627
#> [31] 0.470588235 1.000000000 0.752941176 0.721568627 0.470588235 1.000000000
#> [37] 0.752941176 0.721568627 0.470588235 1.000000000 0.909803922 0.803921569
#> [43] 0.678431373 1.000000000 0.909803922 0.803921569 0.678431373 1.000000000
#> [49] 0.909803922 0.803921569 0.678431373 1.000000000 0.909803922 0.803921569
#> [55] 0.678431373 1.000000000 0.886274510 0.886274510 0.886274510 1.000000000
#> [61] 0.886274510 0.886274510 0.886274510 1.000000000
#> 
#> $indices
#>  [1]  0  1  5  0  5  4  4  5  9  4  9  8  8  9 13  8 13 12  1  2  6  1  6  5  5
#> [26]  6 10  5 10  9  9 10 14  9 14 13  2  3  7  2  7  6  6  7 11  6 11 10 10 11
#> [51] 15 10 15 14
#> 
#> $wire_indices
#>  [1]  0  1  1  2  2  3  4  5  5  6  6  7  8  9  9 10 10 11 12 13 13 14 14 15  0
#> [26]  4  1  5  2  6  3  7  4  8  5  9  6 10  7 11  8 12  9 13 10 14 11 15
#> 
#> $material
#> $material$shading
#> [1] "lambert"
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
#> [1] 1
#> 
#> $bbox3d$xmax
#> [1] 4
#> 
#> $bbox3d$ymin
#> [1] 1
#> 
#> $bbox3d$ymax
#> [1] 4
#> 
#> $bbox3d$zmin
#> [1] 100
#> 
#> $bbox3d$zmax
#> [1] 104
#> 
#> 
#> $surface_meta
#> $surface_meta$nrow
#> [1] 4
#> 
#> $surface_meta$ncol
#> [1] 4
#> 
#> $surface_meta$x
#> [1] 1 2 3 4
#> 
#> $surface_meta$y
#> [1] 1 2 3 4
#> 
#> $surface_meta$z_range
#> [1] 100 104
#> 
#> $surface_meta$shading
#> [1] "surface_lambert"
#> 
#> $surface_meta$triangulation
#> [1] "regular_grid"
#> 
#> 
```
