# Define ggWebGL Mesh Material

Build a renderer material specification for mesh and surface layers.

## Usage

``` r
ggwebgl_material(
  shading = c("flat", "lambert", "mesh_flat", "mesh_lambert", "mesh_phong_simple",
    "mesh_scalar_colormap", "mesh_selection_highlight", "surface_flat",
    "surface_lambert", "surface_height_colormap", "surface_uncertainty_alpha"),
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

  Shading model. `"flat"` and `"lambert"` are the stable material
  aliases; mesh shader aliases such as `"mesh_lambert"` and
  `"mesh_scalar_colormap"` and surface shader aliases such as
  `"surface_lambert"` and `"surface_height_colormap"` are accepted by
  their respective layer families.

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
