# Renderer-Ready Raster Layer

Build a normalized raster layer from RGBA byte payloads.

## Usage

``` r
ggwebgl_layer_raster(
  rgba,
  width,
  height,
  xmin,
  xmax,
  ymin,
  ymax,
  interpolate = FALSE,
  panel_id = 1L,
  geom = "adapter_raster"
)
```

## Arguments

- rgba:

  Integer or numeric vector of length `width * height * 4`, using byte
  values in `[0, 255]`.

- width, height:

  Raster dimensions in cells.

- xmin, xmax, ymin, ymax:

  Raster extent.

- interpolate:

  Whether the WebGL texture should use linear filtering.

- panel_id:

  Scalar panel identifier for this layer.

- geom:

  Debug geom name recorded in the payload.

## Value

A normalized raster layer list.

## Examples

``` r
ggwebgl_layer_raster(
  rgba = rep(c(15L, 23L, 42L, 255L), 4L),
  width = 2L,
  height = 2L,
  xmin = 0,
  xmax = 1,
  ymin = 0,
  ymax = 1,
  interpolate = TRUE
)
#> $panel_id
#> [1] 1
#> 
#> $type
#> [1] "raster"
#> 
#> $geom
#> [1] "adapter_raster"
#> 
#> $rows
#> [1] 4
#> 
#> $width
#> [1] 2
#> 
#> $height
#> [1] 2
#> 
#> $xmin
#> [1] 0
#> 
#> $xmax
#> [1] 1
#> 
#> $ymin
#> [1] 0
#> 
#> $ymax
#> [1] 1
#> 
#> $interpolate
#> [1] TRUE
#> 
#> $rgba
#>  [1]  15  23  42 255  15  23  42 255  15  23  42 255  15  23  42 255
#> 
```
