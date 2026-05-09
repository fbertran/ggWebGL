# Structured Surface Matrix

Create a structured surface-grid object from a numeric matrix. Rows map
to `y`, columns map to `x`, and the matrix values map to `z`.

## Usage

``` r
surface_matrix(z, x = NULL, y = NULL)
```

## Arguments

- z:

  Numeric matrix of height values.

- x:

  Optional x-coordinate vector with one value per matrix column.

- y:

  Optional y-coordinate vector with one value per matrix row.

## Value

A `ggwebgl_surface_matrix` object accepted by
[`ggwebgl_layer_surface()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_surface.md).

## Examples

``` r
surface_matrix(volcano[1:3, 1:3])
#> $z
#>      [,1] [,2] [,3]
#> [1,]  100  100  101
#> [2,]  101  101  102
#> [3,]  102  102  103
#> 
#> $x
#> [1] 1 2 3
#> 
#> $y
#> [1] 1 2 3
#> 
#> $nrow
#> [1] 3
#> 
#> $ncol
#> [1] 3
#> 
#> attr(,"class")
#> [1] "ggwebgl_surface_matrix" "list"                  
```
