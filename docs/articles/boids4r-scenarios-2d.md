# 2D Swarm Scenarios with boids4R

## 2D Swarm Scenarios

These examples use `boids4R` scenario builders and render current boids,
species-aware velocity arrows, faint recent trails, and obstacle or
predator context rings through `ggWebGL`.

Code examples are shown by default. Live WebGL widgets are disabled
during CRAN, package checks, and CI. Rich local or pkgdown rendering
requires `GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` and
`GGWEBGL_EVAL_LIVE_WIDGETS=true`.

``` r
if (!boids4r_available) {
  cat("boids4R is unavailable, so live 2D boids widgets are skipped.\n")
} else if (!ggwebgl_eval_widgets) {
  cat("boids4R is available, but live 2D boids widgets are skipped because live widget evaluation is disabled.\n")
} else {
  cat("boids4R is available; live 2D boids widgets will be rendered below.\n")
}
#> boids4R is available; live 2D boids widgets will be rendered below.
```

### Schooling 2D

``` r
if (!boids4r_available) {
  cat("Schooling widget skipped.\n")
} else {
  render_2d_boids_scenario("schooling_2d", n = 180L, seed = 111L)
}
```

### Obstacle Corridor 2D

``` r
if (!boids4r_available) {
  cat("Obstacle corridor widget skipped.\n")
} else {
  render_2d_boids_scenario("obstacle_corridor_2d", n = 160L, seed = 112L)
}
```

### Predator Avoidance 2D

``` r
if (!boids4r_available) {
  cat("Predator avoidance widget skipped.\n")
} else {
  render_2d_boids_scenario("predator_avoidance_2d", n = 170L, seed = 113L)
}
```
