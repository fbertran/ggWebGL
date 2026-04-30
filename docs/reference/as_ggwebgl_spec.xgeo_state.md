# Convert an `xgeo_state` object to a ggWebGL renderer specification

Convert an `xgeo_state` object to a ggWebGL renderer specification

## Usage

``` r
# S3 method for class 'xgeo_state'
as_ggwebgl_spec(
  x,
  embedding = NULL,
  primitive = c("points", "density", "surface"),
  lod = NULL,
  webgl = list(),
  labels = list(),
  point_size = 4,
  alpha = 0.85,
  ...
)
```

## Arguments

- x:

  An `xgeo_state` object.

- embedding:

  Optional embedding name. Defaults to the active embedding.

- primitive:

  Primitive family to project to renderer payloads.

- lod:

  Optional LOD selector for `primitive = "density"`. Accepts `NULL`, a
  single bundle name, a `bundle/level` string, or a list with `name` and
  optional `level`.

- webgl:

  Renderer options passed through `normalise_webgl_options()`.

- labels:

  Optional labels list (`title`, `subtitle`, `x`, `y`) that overrides
  metadata-derived defaults.

- point_size:

  Point size used for point payloads.

- alpha:

  Alpha used for generated payload colors.

- ...:

  Reserved for future adapters.

## Value

A normalized ggWebGL renderer specification.

## Examples

``` r
toy_state <- list(
  attributes = list(
    embeddings = list(
      active = "toy",
      items = list(
        toy = list(
          coords = data.frame(
            point_id = paste0("p", 1:4),
            dim1 = c(0, 1, 0, 1),
            dim2 = c(0, 0, 1, 1)
          )
        )
      )
    ),
    explanations = data.frame(
      point_id = paste0("p", 1:4),
      value = c(0.2, 0.4, 0.8, 0.5)
    )
  ),
  metadata = list(title = "Toy backend state")
)
class(toy_state) <- "xgeo_state"

xgeo_spec <- as_ggwebgl_spec(toy_state, primitive = "points")
xgeo_spec$render$primitives
#> [1] "points"
```
