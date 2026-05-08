# Optional XGeoRTR Bridge

## Boundary

This vignette demonstrates an optional downstream bridge from `XGeoRTR`
into `ggWebGL`.

The ownership split stays fixed:

- `XGeoRTR` owns `xgeo_state`, embeddings, and explainable-geometry
  semantics
- the bridge example resolves that backend state into renderer-ready
  payloads
- `ggWebGL` owns widget construction, shaders, panel layout, hover, pan,
  and zoom

No `XGeoRTR` code is modified here. The bridge lives entirely inside the
`ggWebGL` example layer.

The representative and multiscale scenes show how optional XGeoRTR-style
renderer inputs can combine coloured explanation-state points with
sparse contribution-direction arrows. Those arrows are true
[`ggwebgl_layer_vectors()`](https://fbertran.github.io/ggWebGL/reference/ggwebgl_layer_vectors.md)
primitives rather than line segments plus decorative anchors, so the
vignette exercises the same renderer-owned vector path that downstream
packages can target.

## Optional Dependency

`XGeoRTR` is a suggested package for `ggWebGL`. When it is unavailable,
the package still builds and this vignette degrades to
documentation-only mode.

``` r
if (!bridge_available) {
  cat("XGeoRTR is unavailable, so the live bridge widgets are skipped in this vignette.\n")
} else {
  cat("XGeoRTR bridge widgets are available.\n")
}
#> XGeoRTR bridge widgets are available.
```

## Representative Scene

This scene demonstrates class-coloured explanation points with sparse
vector arrows summarising local contribution direction.

``` r
if (!bridge_available) {
  cat("Representative widget skipped.\n")
} else {
  bridge_widgets$representative
}
```

## Multiscale Scene

This two-panel view keeps the same vector grammar while contrasting the
global embedding with a local explanation panel whose viewport is the
exact data-coordinate zoom of the rectangle marked in the global panel.

``` r
if (!bridge_available) {
  cat("Multiscale widget skipped.\n")
} else {
  bridge_widgets$multiscale
}
```

## Attribution Scene

``` r
if (!bridge_available) {
  cat("Attribution widget skipped.\n")
} else {
  bridge_widgets$attribution
}
```

## Structure Scene

``` r
if (!bridge_available) {
  cat("Structure widget skipped.\n")
} else {
  bridge_widgets$structure
}
```

## Regeneration

The example source for these widgets lives at:

``` r
source(system.file("examples", "htmlwidget", "xgeortr-bridge-gallery.R", package = "ggWebGL"))
```
