# Build a ggWebGL Mesh Helper Object

Build a lightweight unstructured mesh object from explicit vertex and
triangle tables.

## Usage

``` r
ggwebgl_mesh(
  vertices,
  triangles,
  x = "x",
  y = "y",
  z = "z",
  i = "i",
  j = "j",
  k = "k",
  scalar = NULL,
  id = NULL,
  normals = NULL,
  colour = NULL,
  rgba = NULL,
  alpha = NULL,
  pick_id = NULL
)
```

## Arguments

- vertices:

  Data frame with vertex coordinates.

- triangles:

  Data frame with one-based triangle indices.

- x, y, z:

  Vertex coordinate column names.

- i, j, k:

  Triangle index column names.

- scalar:

  Optional scalar column name or vector for per-vertex scalar colouring.

- id:

  Optional vertex id column name or vector.

- normals:

  Optional normal matrix/data frame/vector or column triplet named `nx`,
  `ny`, `nz` in `vertices`.

- colour, rgba, alpha:

  Optional vertex colour inputs passed through to
  [`ggwebgl_layer_mesh()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_mesh.md).

- pick_id:

  Optional face picking ids.

## Value

A `ggwebgl_mesh` object.

## Examples

``` r
vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0))
triangles <- data.frame(i = 1L, j = 2L, k = 3L)
ggwebgl_mesh(vertices, triangles)
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
