## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
} else if (file.exists("../DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all("..", export_all = FALSE, helpers = FALSE, quiet = TRUE)
} else {
  library(ggWebGL)
}

benchmark_candidates <- c(
  "inst/benchmarks/benchmark-scene-types.R",
  file.path("..", "inst", "benchmarks", "benchmark-scene-types.R"),
  system.file("benchmarks", "benchmark-scene-types.R", package = "ggWebGL")
)
benchmark_candidates <- benchmark_candidates[nzchar(benchmark_candidates) & file.exists(benchmark_candidates)]
if (!length(benchmark_candidates)) {
  stop("Could not find benchmark-scene-types.R")
}
sys.source(benchmark_candidates[[1L]], envir = knitr::knit_global())

workflow_candidates <- c(
  "inst/examples/htmlwidget/workflow-comparison.R",
  file.path("..", "inst", "examples", "htmlwidget", "workflow-comparison.R"),
  system.file("examples", "htmlwidget", "workflow-comparison.R", package = "ggWebGL")
)
workflow_candidates <- workflow_candidates[nzchar(workflow_candidates) & file.exists(workflow_candidates)]
if (!length(workflow_candidates)) {
  stop("Could not find workflow-comparison.R")
}
sys.source(workflow_candidates[[1L]], envir = knitr::knit_global())

## ----benchmark-columns--------------------------------------------------------
benchmark_scene_columns()

## ----dense-benchmark-command, eval = FALSE------------------------------------
# source(system.file("examples", "htmlwidget", "million-point-embedding.R", package = "ggWebGL"))
# run_manual_million_point_embedding()

## ----scene-type-command, eval = FALSE-----------------------------------------
# source(system.file("benchmarks", "benchmark-scene-types.R", package = "ggWebGL"))
# metrics <- benchmark_scene_types(
#   output_dir = tempdir(),
#   scenes = c("embedding", "trajectories", "surface_mesh", "workflow"),
#   point_count = 1000000L,
#   include_browser = FALSE
# )
# metrics[, c("scene_id", "serialized_bytes", "artifact_bytes", "status")]

## ----workflow-static, fig.width=6, fig.height=4-------------------------------
workflow_comparison_plot(800L)

## ----workflow-webgl, out.width='100%'-----------------------------------------
workflow_comparison_widget(800L, height = 360)

