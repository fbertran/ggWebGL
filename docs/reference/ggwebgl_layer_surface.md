# Renderer-Ready Surface Layer

Build a triangulated surface from a regular z matrix.

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
  normals = "auto",
  material = ggwebgl_material(shading = "lambert"),
  pick_id = NULL,
  panel_id = 1L,
  geom = "adapter_surface",
  wireframe = NULL
)
```

## Arguments

- z:

  Numeric matrix of height values.

- x, y:

  Optional coordinate vectors. Defaults to matrix column and row
  indices.

- colour:

  Optional colour vector or column name. Ignored when `rgba` is
  supplied.

- rgba:

  Optional renderer-ready RGBA matrix/data frame with four columns, or
  vector of length `n * 4`, using values in `[0, 1]` or `[0, 255]`.

- alpha:

  Optional alpha vector or column name used with `colour`.

- palette:

  HCL palette name used when `colour` or `rgba` is omitted.

- normals:

  Normal-generation mode. `"auto"` computes vertex normals.

- material:

  Surface material created by
  [`ggwebgl_material()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_material.md).

- pick_id:

  Optional face picking ids.

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
ggwebgl_layer_surface(volcano[1:4, 1:4])
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "mesh"
#> 
#> $geom
#> [1] "adapter_surface"
#> 
#> $rows
#> [1] 18
#> 
#> $vertex_count
#> [1] 16
#> 
#> $triangle_count
#> [1] 18
#> 
#> $x
#>  [1] 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4
#> 
#> $y
#>  [1] 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4
#> 
#> $z
#>  [1] 100 100 101 101 101 101 102 102 102 102 103 103 103 103 104 104
#> 
#> $indices
#>  [1]  0  1  5  0  5  4  1  2  6  1  6  5  2  3  7  2  7  6  4  5  9  4  9  8  5
#> [26]  6 10  5 10  9  6  7 11  6 11 10  8  9 13  8 13 12  9 10 14  9 14 13 10 11
#> [51] 15 10 15 14
#> 
#> $normal
#>  [1]  0.0000000 -0.7071068  0.7071068 -0.4264014 -0.6396021  0.6396021
#>  [7] -0.2294157 -0.6882472  0.6882472  0.0000000 -0.7071068  0.7071068
#> [13]  0.0000000 -0.7071068  0.7071068 -0.3333333 -0.6666667  0.6666667
#> [19] -0.3333333 -0.6666667  0.6666667  0.0000000 -0.7071068  0.7071068
#> [25]  0.0000000 -0.7071068  0.7071068 -0.3333333 -0.6666667  0.6666667
#> [31] -0.3333333 -0.6666667  0.6666667  0.0000000 -0.7071068  0.7071068
#> [37]  0.0000000 -0.7071068  0.7071068 -0.2294157 -0.6882472  0.6882472
#> [43] -0.4264014 -0.6396021  0.6396021  0.0000000 -0.7071068  0.7071068
#> 
#> $rgba
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
```
