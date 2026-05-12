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
  "inst/examples/htmlwidget/future-work-gallery.R",
  file.path("..", "inst", "examples", "htmlwidget", "future-work-gallery.R"),
  system.file("examples", "htmlwidget", "future-work-gallery.R", package = "ggWebGL")
)
example_candidates <- example_candidates[nzchar(example_candidates) & file.exists(example_candidates)]
if (!length(example_candidates)) {
  stop("Could not find future-work-gallery.R")
}
sys.source(example_candidates[[1L]], envir = knitr::knit_global())

renderer_capability_widgets <- future_work_demo_widgets()

## ----vector-arrows, out.width='100%'------------------------------------------
renderer_capability_widgets$vectors

## ----selection-ids, out.width='100%'------------------------------------------
renderer_capability_widgets$selection

## ----linked-zoom-setup--------------------------------------------------------
set.seed(2031)
linked_zoom_points <- data.frame(
  x = c(rnorm(900, -0.7, 0.28), rnorm(700, 0.85, 0.2), rnorm(600, 0.1, 0.18)),
  y = c(rnorm(900, 0.0, 0.2), rnorm(700, 0.55, 0.16), rnorm(600, -0.7, 0.12)),
  group = rep(c("global", "local", "bridge"), c(900, 700, 600))
)

linked_zoom_source <- ggwebgl_spec(
  layers = list(
    ggwebgl_layer_points(
      linked_zoom_points,
      x = "x",
      y = "y",
      colour = c("#2563eb", "#f97316", "#0f766e")[match(linked_zoom_points$group, c("global", "local", "bridge"))],
      alpha = 0.36,
      size = 2.2
    )
  ),
  labels = list(title = "Interactive linked zoom"),
  webgl = list(shader = "density_splat", interactions = character())
)

linked_zoom_spec <- ggwebgl_magnify_region(
  linked_zoom_source,
  region = list(x = c(0.48, 1.25), y = c(0.25, 0.82)),
  display = "panel",
  interactive = TRUE,
  global_label = "Global view",
  zoom_label = "Brush-driven zoom"
)

linked_zoom_spec$render$links$magnifiers[[1L]]

## ----linked-zoom-widget, out.width='100%'-------------------------------------
ggWebGL(linked_zoom_spec, height = 430)

## ----timeline-controls, out.width='100%'--------------------------------------
renderer_capability_widgets$timeline

## ----camera-3d, out.width='100%'----------------------------------------------
renderer_capability_widgets$camera_3d

## ----mesh-surface, out.width='100%'-------------------------------------------
renderer_capability_widgets$mesh_surface

## ----eval = FALSE-------------------------------------------------------------
# source(system.file("examples", "htmlwidget", "future-work-gallery.R", package = "ggWebGL"))
# export_future_work_gallery()

