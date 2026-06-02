# Swarm Art in the Browser with boids4R

## Swarm Art in the Browser

`ggWebGL` can render swarm art in the browser from renderer-neutral
`boids4R` simulations. Compact schools, predator avoidance, obstacle
corridors, murmurations, and mixed-species flocks become animated
point/vector timelines that can be panned, zoomed, scrubbed, and
inspected in WebGL.

The live examples are split across smaller articles so the generated
pkgdown HTML files stay below repository hosting limits. The examples
remain opt-in: live WebGL widgets are disabled during CRAN, package
checks, and CI. Rich local or pkgdown rendering requires both
`GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` and
`GGWEBGL_EVAL_LIVE_WIDGETS=true`.

## Boundary

The ownership split is deliberately narrow:

- `boids4R` owns simulation semantics: flocking state, rules, scenarios,
  and frame export.
- [`boids4R::as_ggwebgl_spec()`](https://fbertran.github.io/boids4R/reference/as_ggwebgl_spec.html)
  translates simulation frames into renderer primitives and owns boid
  display defaults.
- `ggWebGL` owns WebGL rendering: the htmlwidget, point and vector
  primitives, shader choice, timeline controls, hover, pan, zoom, and 3D
  orbit interaction.

`boids4R` is a suggested package for `ggWebGL`. When it is unavailable,
the split articles still build and report that live animation widgets
were skipped.

``` r
boids4r_available <- requireNamespace("boids4R", quietly = TRUE)
if (!boids4r_available) {
  cat("boids4R is unavailable, so live boids animations are skipped.\n")
}
```

## Split Articles

- [2D swarm
  scenarios](https://fbertran.github.io/ggWebGL/articles/boids4r-scenarios-2d.md):
  schooling, obstacle corridor, and predator avoidance examples.
- [3D swarm
  scenarios](https://fbertran.github.io/ggWebGL/articles/boids4r-scenarios-3d.md):
  murmuration and mixed-species 3D examples with orbit camera
  interaction.
- [Custom corridor
  workflow](https://fbertran.github.io/ggWebGL/articles/boids4r-custom-workflow.md):
  a low-level `boids4R` construction comparing baseline and stronger
  avoidance parameters.

## Regeneration

The same pattern can be used from an installed package:

``` r
sim <- boids4R::boids_scenario("mixed_species_3d", n = 210, steps = 240, seed = 115)
spec <- ggWebGL:::ggwebgl_boids_display_spec(
  sim,
  vector_mode = "current",
  vector_colour_mode = "species",
  obstacle_mode = "ring",
  trail = "recent",
  trail_length = 32,
  shader = "default"
)
ggWebGL::ggWebGL(spec, height = 540)
```
