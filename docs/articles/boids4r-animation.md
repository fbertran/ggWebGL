# Swarm Art in the Browser with boids4R

## Swarm Art in the Browser

This article documents an optional downstream bridge from `boids4R` into
`ggWebGL`. The creative use case is generative browser art: compact
schools, predator avoidance, obstacle corridors, murmurations, and
mixed-species swarms become animated point/vector timelines that can be
panned, zoomed, scrubbed, and inspected in WebGL.

The CRAN-built vignette is documentation-only. It does not load
`boids4R`, does not execute GitHub-only package code, and does not
require optional ecosystem packages to be installed. The runnable bridge
remains in the package example script named below.

## Boundary

The ownership split is deliberately narrow:

- `boids4R` owns simulation semantics: flocking state, rules, scenarios,
  and frame export.
- The optional downstream bridge translates simulation frames into
  renderer primitives when `boids4R` is installed separately.
- `ggWebGL` owns WebGL rendering: the htmlwidget, point and vector
  primitives, shader choice, timeline controls, hover, pan, zoom, and 3D
  orbit interaction.

This keeps the core `ggWebGL` package self-contained for CRAN while
preserving a clear optional integration path for development
installations.

## Runnable Optional Demo

The optional example script is:

``` text
inst/examples/htmlwidget/downstream-boids4r-animation.R
```

When `boids4R` is installed separately, the script builds two widgets:

- a 2D schooling scene rendered as exact-frame animated points and
  vectors
- a 3D murmuration scene rendered with the structured 3D view path

To run it in a development checkout or installed package, use:

``` text
source(system.file("examples", "htmlwidget", "downstream-boids4r-animation.R", package = "ggWebGL"))
widgets <- downstream_boids4r_widgets()
widgets$schooling_2d
widgets$murmuration_3d
```

The script is guarded: if `boids4R` is absent, it reports that the
optional demo was skipped instead of failing package checks.

## What To Inspect

The optional widgets are intended to demonstrate renderer capabilities
rather than package-specific simulation interpretation:

- point primitives carry boid positions for each frame
- vector primitives show local velocity direction
- exact timeline filtering makes each scrubbed frame visually distinct
- 3D view metadata enables the murmuration scene to use browser camera
  controls
- shader settings remain owned by `ggWebGL`, not by the simulation
  package

## CRAN Position

`boids4R` is an optional development ecosystem package. It is not listed
in `ggWebGL` dependencies and is not required for installation,
examples, tests, or vignettes. This article is retained as a
documentation entry so downstream packages can see the intended adapter
boundary without making CRAN checks depend on GitHub-only packages.
