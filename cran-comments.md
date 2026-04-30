## Test environments

- Local macOS Darwin 23.6.0 arm64, R 4.5.2
- macOS builder
- win-builder R-devel


## R CMD check results

- Local `LC_ALL=C devtools::check(args = "--as-cran")`: 0 errors, 0 warnings,
  1 note.
- macOS builder Status: OK.
- 

The remaining local NOTE is:

- `checking for future file timestamps ... NOTE`: unable to verify current time.
  This is a local check-environment issue.

## Optional ecosystem packages

`XGeoRTR`, `boids4R`, and `shapViz3D` are optional development ecosystem
packages that will also be uploaded on CRAN after ggWebGL. These are not
required for installation, examples, tests, or vignettes.
All optional bridge code is guarded and skipped when those packages are not
installed.

## Package size

Heavyweight project-only article sources and figure copies are kept in the
GitHub repository for the website workflow, but are excluded from the CRAN
source tarball via `.Rbuildignore`. The CRAN package keeps the lightweight
vignettes needed for package orientation and optional-bridge documentation while
avoiding large installed `doc/` artifacts.

## Optional external toolchains

The package does not require 'CUDA', 'Metal', or 'OpenCL'. All examples, tests,
and vignettes run without device-specific acceleration.
