# Convert Explicit Mesh Data to a ggWebGL Mesh Object

`as_mesh_webgl()` converts CRAN-safe explicit mesh inputs into a
lightweight helper object accepted by
[`ggwebgl_layer_mesh()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_mesh.md).
Core ggWebGL does not convert external mesh package classes in this
milestone.

## Usage

``` r
as_mesh_webgl(x, ...)
```

## Arguments

- x:

  Object to convert. Supported inputs are `ggwebgl_mesh` objects, lists
  with `vertices` and `triangles`, and data frames containing explicit
  `x`, `y`, `z`, `i`, `j`, and `k` columns.

- ...:

  Additional arguments passed to
  [`ggwebgl_mesh()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_mesh.md).

## Value

A `ggwebgl_mesh` object.

## Examples

``` r
vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0))
triangles <- data.frame(i = 1L, j = 2L, k = 3L)
as_mesh_webgl(list(vertices = vertices, triangles = triangles))
#> $vertices
#>   x y z
#> 1 0 0 0
#> 2 1 0 0
#> 3 0 1 0
#> 
#> $triangles
#>   i j k
#> 1 1 2 3
#> 
#> $x
#> [1] "x"
#> 
#> $y
#> [1] "y"
#> 
#> $z
#> [1] "z"
#> 
#> $i
#> [1] "i"
#> 
#> $j
#> [1] "j"
#> 
#> $k
#> [1] "k"
#> 
#> $scalar
#> NULL
#> 
#> $id
#> NULL
#> 
#> $normals
#> NULL
#> 
#> $colour
#> NULL
#> 
#> $rgba
#> NULL
#> 
#> $alpha
#> NULL
#> 
#> $pick_id
#> NULL
#> 
#> attr(,"class")
#> [1] "ggwebgl_mesh" "list"        
```
