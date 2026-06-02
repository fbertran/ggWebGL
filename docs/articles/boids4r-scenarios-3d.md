# 3D Swarm Scenarios with boids4R

## 3D Swarm Scenarios

These examples use 3D `boids4R` simulations with `ggWebGL` orbit-camera
rendering. Current boids are emphasized, velocity arrows follow species
colours, and recent trails remain faint so current flock state stays
readable.

Live WebGL widgets are disabled during CRAN, package checks, and CI.
Rich local or pkgdown rendering requires
`GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` and
`GGWEBGL_EVAL_LIVE_WIDGETS=true`.

``` r
if (!boids4r_available) {
  cat("boids4R is unavailable, so live 3D boids widgets are skipped.\n")
} else if (!ggwebgl_eval_widgets) {
  cat("boids4R is available, but live 3D boids widgets are skipped because live widget evaluation is disabled.\n")
} else {
  cat("boids4R is available; live 3D boids widgets will be rendered below.\n")
}
#> boids4R is available; live 3D boids widgets will be rendered below.
```

### Murmuration 3D

``` r
if (!boids4r_available) {
  cat("Murmuration widget skipped.\n")
} else {
  render_3d_boids_scenario("murmuration_3d", n = 240L, seed = 114L)
}
```

### Mixed Species 3D

``` r
if (!boids4r_available) {
  cat("Mixed-species widget skipped.\n")
} else {
  render_3d_boids_scenario("mixed_species_3d", n = 210L, seed = 115L)
}
```
