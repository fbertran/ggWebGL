if (file.exists("inst/benchmarks/benchmark-suite.R")) {
  source("inst/benchmarks/benchmark-suite.R", local = TRUE)
} else {
  source(system.file("benchmarks", "benchmark-suite.R", package = "ggWebGL"), local = TRUE)
}

benchmark_render_pipeline <- function(output_dir = tempfile("ggwebgl-benchmark-run-"),
                                      families = c("dense_points", "raster_field", "faceted_dense_points"),
                                      engines = c("ggwebgl", "plotly", "ggplot2"),
                                      reps = 1L,
                                      selfcontained = FALSE,
                                      include_browser = TRUE) {
  benchmark_render_suite(
    output_dir = output_dir,
    families = families,
    engines = engines,
    reps = reps,
    selfcontained = selfcontained,
    include_browser = include_browser
  )
}

if (sys.nframe() == 0L) {
  print(benchmark_render_pipeline())
}
