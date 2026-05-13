## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
} else if (file.exists("../DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all("..", export_all = FALSE, helpers = FALSE, quiet = TRUE)
} else {
  library(ggWebGL)
}

example_candidates <- c(
  "inst/examples/htmlwidget/surface-gallery.R",
  file.path("..", "inst", "examples", "htmlwidget", "surface-gallery.R"),
  system.file("examples", "htmlwidget", "surface-gallery.R", package = "ggWebGL")
)
example_candidates <- example_candidates[nzchar(example_candidates) & file.exists(example_candidates)]
if (!length(example_candidates)) {
  stop("Could not find surface-gallery.R")
}
sys.source(example_candidates[[1L]], envir = knitr::knit_global())

## ----volcano-surface, out.width='100%'----------------------------------------
surface_gallery_volcano_widget(height = 460)

## ----scalar-mesh, out.width='100%'--------------------------------------------
surface_gallery_mesh_widget(height = 460)

