# Custom boids4R Corridor Workflow

## Custom Corridor Workflow

This workflow builds a 2D corridor from low-level `boids4R`
constructors, then compares a baseline run with a stronger
obstacle/predator avoidance run. The visual encoding is the same as the
scenario pages: current boids are emphasized, recent trails are faint,
velocity vectors use species colours, and obstacles are shown as rings.

Live WebGL widgets are disabled during CRAN, package checks, and CI.
Rich local or pkgdown rendering requires
`GGWEBGL_EVAL_COVERAGE_VIGNETTE=true` and
`GGWEBGL_EVAL_LIVE_WIDGETS=true`.

``` r
if (!boids4r_available) {
  cat("boids4R is unavailable, so live custom corridor widgets are skipped.\n")
} else if (!ggwebgl_eval_widgets) {
  cat("boids4R is available, but live custom corridor widgets are skipped because live widget evaluation is disabled.\n")
} else {
  cat("boids4R is available; live custom corridor widgets will be rendered below.\n")
}
#> boids4R is available; live custom corridor widgets will be rendered below.
```

### Baseline Corridor

``` r
if (!boids4r_available) {
  cat("Baseline corridor widget skipped.\n")
} else {
  render_custom_corridor("baseline", stronger_avoidance = FALSE, seed = 221L)
}
```

### Stronger Avoidance Corridor

``` r
if (!boids4r_available) {
  cat("Stronger avoidance corridor widget skipped.\n")
} else {
  render_custom_corridor("stronger_avoidance", stronger_avoidance = TRUE, seed = 222L)
}
```
