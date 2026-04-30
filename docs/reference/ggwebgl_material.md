# Define ggWebGL Mesh Material

Build a renderer material specification for mesh and surface layers.

## Usage

``` r
ggwebgl_material(
  shading = c("flat", "lambert"),
  ambient = 0.35,
  diffuse = 0.75,
  specular = 0,
  light_dir = c(0.35, 0.45, 0.82),
  wireframe = FALSE,
  cull = c("back", "none")
)
```

## Arguments

- shading:

  Shading model, `"flat"` or `"lambert"`.

- ambient, diffuse, specular:

  Lighting coefficients.

- light_dir:

  Directional light vector.

- wireframe:

  Whether to request a wireframe overlay.

- cull:

  Face-culling mode, `"back"` or `"none"`.

## Value

A `ggwebgl_material` list.

## Examples

``` r
ggwebgl_material(shading = "lambert", wireframe = TRUE)
#> $shading
#> [1] "lambert"
#> 
#> $ambient
#> [1] 0.35
#> 
#> $diffuse
#> [1] 0.75
#> 
#> $specular
#> [1] 0
#> 
#> $light_dir
#> [1] 0.35 0.45 0.82
#> 
#> $wireframe
#> [1] TRUE
#> 
#> $cull
#> [1] "back"
#> 
#> attr(,"class")
#> [1] "ggwebgl_material" "list"            
```
