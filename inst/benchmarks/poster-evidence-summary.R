poster_evidence_claims <- function() {
  data.frame(
    claim_id = c(
      "dense_points_large_cloud",
      "density_splat_shader",
      "trajectory_rendering",
      "raster_field_rendering",
      "fixed_scale_facets",
      "hover_labeled_selection",
      "downstream_adapter_contract",
      "downstream_boids4r_animation",
      "real_data_examples",
      "quantitative_benchmark_suite",
      "benchmark_figure_pipeline",
      "optional_browser_and_plotly_metrics",
      "vector_arrows",
      "brushing_lasso",
      "animation_runtime",
      "3d_camera",
      "mesh_surface",
      "future_fps_claims"
    ),
    claim = c(
      "ggWebGL can export dense six-figure 2D point-cloud scenes through the current WebGL point renderer.",
      "The density_splat shader is a supported point-rendering mode with a reproducible regression gallery.",
      "Line and trajectory bundles are supported for generative-style and scientific path examples.",
      "geom_raster_webgl() renders texture-ready raster fields rather than reporting them as unsupported placeholders.",
      "Fixed-scale facet layouts render as panel-aware WebGL scenes.",
      "Generic hover labels can make selected samples inspectable without backend-specific semantics.",
      "Downstream packages can render by emitting normalized point, line, raster, vector, or mesh primitive specs.",
      "An optional development boids4R simulation package can hand renderer-neutral swarm-art frames to ggWebGL as animated point and vector timelines when installed separately.",
      "The package includes offline real-data evidence for raster, trajectory, dense embedding, and faceted embedding cases.",
      "A reproducible benchmark suite measures build cost, transport cost, and optional browser first-render cost.",
      "Benchmark metrics can be converted into a poster-ready summary table and overview figure.",
      "plotly and chromote comparisons are supported when optional dependencies are installed and degrade gracefully otherwise.",
      "Vector-arrow primitives render through the WebGL primitive pipeline.",
      "Brushing and lasso selection report selected primitive ids.",
      "Runtime controls filter primitive layers by frame or time.",
      "3D camera controls render opt-in point, line, and mesh scenes.",
      "Meshes and triangulated surfaces render as triangle geometry.",
      "Fixed FPS claims remain future work until a generated benchmark artifact exists."
    ),
    status = c(
      "real_now",
      "real_now",
      "real_now",
      "real_now",
      "real_now",
      "real_now",
      "real_now",
      "optional_dependency",
      "real_now",
      "benchmark_available",
      "benchmark_available",
      "optional_dependency",
      "real_now",
      "real_now",
      "real_now",
      "real_now",
      "real_now",
      "future_work"
    ),
    evidence_type = c(
      "gallery",
      "gallery",
      "gallery",
      "gallery",
      "gallery",
      "gallery",
      "adapter_example",
      "adapter_example",
      "vignette",
      "benchmark_script",
      "figure_pipeline",
      "benchmark_script",
      "gallery",
      "gallery",
      "gallery",
      "gallery",
      "gallery",
      "scope_note"
    ),
    source_path = c(
      "inst/examples/htmlwidget/siggraph-milestone3-gallery.R",
      "inst/examples/htmlwidget/point-shader-modes.R",
      "inst/examples/htmlwidget/siggraph-showcase-gallery.R",
      "inst/examples/htmlwidget/real-data-gallery.R",
      "inst/examples/htmlwidget/real-data-gallery.R",
      "inst/examples/htmlwidget/siggraph-milestone3-gallery.R",
      "inst/examples/htmlwidget/downstream-adapter-interfaces.R",
      "inst/examples/htmlwidget/downstream-boids4r-animation.R",
      "vignettes/real-data-evidence.Rmd",
      "inst/benchmarks/benchmark-render-pipeline.R",
      "inst/benchmarks/plot-benchmark-results.R",
      "inst/benchmarks/benchmark-suite.R",
      "inst/examples/htmlwidget/future-work-gallery.R",
      "inst/examples/htmlwidget/future-work-gallery.R",
      "inst/examples/htmlwidget/future-work-gallery.R",
      "inst/examples/htmlwidget/future-work-gallery.R",
      "inst/examples/htmlwidget/future-work-gallery.R",
      "inst/benchmarks/benchmark-interaction-fps.R"
    ),
    command = c(
      "source('inst/examples/htmlwidget/siggraph-milestone3-gallery.R'); export_siggraph_milestone3_gallery(point_count = 120000L)",
      "source('inst/examples/htmlwidget/point-shader-modes.R'); export_point_shader_mode_gallery()",
      "source('inst/examples/htmlwidget/siggraph-showcase-gallery.R'); export_siggraph_showcase_gallery(detail = 'high_detail')",
      "source('inst/examples/htmlwidget/real-data-gallery.R'); export_real_data_gallery()",
      "source('inst/examples/htmlwidget/real-data-gallery.R'); export_real_data_gallery()",
      "source('inst/examples/htmlwidget/siggraph-milestone3-gallery.R'); export_siggraph_milestone3_gallery()",
      "source('inst/examples/htmlwidget/downstream-adapter-interfaces.R'); export_downstream_adapter_gallery()",
      "source('inst/examples/htmlwidget/downstream-boids4r-animation.R'); export_downstream_boids4r_gallery()",
      "rmarkdown::render('vignettes/real-data-evidence.Rmd', output_dir = tempdir())",
      "source('inst/benchmarks/benchmark-render-pipeline.R'); benchmark_render_pipeline(include_browser = FALSE)",
      "Rscript inst/benchmarks/plot-benchmark-results.R benchmark_metrics.csv benchmark_overview.png",
      "source('inst/benchmarks/benchmark-suite.R'); benchmark_render_suite(engines = c('ggwebgl', 'plotly', 'ggplot2'))",
      "source('inst/examples/htmlwidget/future-work-gallery.R'); future_work_vector_field_demo()",
      "source('inst/examples/htmlwidget/future-work-gallery.R'); future_work_selection_demo()",
      "source('inst/examples/htmlwidget/future-work-gallery.R'); future_work_timeline_demo()",
      "source('inst/examples/htmlwidget/future-work-gallery.R'); future_work_3d_camera_demo()",
      "source('inst/examples/htmlwidget/future-work-gallery.R'); future_work_mesh_surface_demo()",
      "source('inst/benchmarks/benchmark-interaction-fps.R'); fps_claim_metrics_template()"
    ),
    artifact = c(
      "large_point_cloud.html",
      "density_splat.html",
      "diffusion_paths.html; phase_portrait.html",
      "volcano_dem.html",
      "faceted_embedding.html",
      "hover_selection.html",
      "embedding_table.html; path_bundle.html; raster_field.html",
      "schooling_2d.html; murmuration_3d.html",
      "real-data-evidence.html",
      "benchmark_metrics.csv",
      "benchmark_overview.png; benchmark_overview_summary.csv",
      "benchmark_metrics.csv",
      "vectors.html",
      "selection.html",
      "timeline.html",
      "camera_3d.html",
      "mesh_surface.html",
      "ggwebgl_interaction_frame_times.csv"
    ),
    poster_use = c(
      "Figure: large point-cloud stability",
      "Figure: density splatting versus default scatter",
      "Figure: generative and scientific trajectory bundles",
      "Figure: real topographic raster field",
      "Figure: multi-panel dense embedding comparison",
      "Demo: inspectable selected samples",
      "Architecture inset: package-neutral adapter boundary",
      "Demo: browser swarm art through exact timeline primitives",
      "Evidence panel: real data instead of only synthetic scenes",
      "Evaluation panel: build and transport metrics",
      "Evaluation figure: reproducible benchmark overview",
      "Evaluation extension: optional interactive baseline and browser timing",
      "Demo: generic vector-arrow primitive",
      "Demo: renderer-owned selection id reporting",
      "Demo: timeline playback control",
      "Demo: opt-in 3D camera path",
      "Demo: mesh and triangulated surface primitive",
      "Scope note: FPS claims require benchmark evidence"
    ),
    stringsAsFactors = FALSE
  )
}

poster_evidence_locate <- function(path) {
  candidates <- c(
    path,
    file.path(getwd(), path),
    file.path(getwd(), "..", "..", path)
  )
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  found <- candidates[file.exists(candidates)]

  if (length(found)) {
    return(found[[1L]])
  }

  parts <- strsplit(path, "/", fixed = TRUE)[[1L]]
  if (identical(parts[[1L]], "inst")) {
    installed_parts <- as.list(parts[-1L])
    installed <- do.call(system.file, c(installed_parts, list(package = "ggWebGL")))
    if (nzchar(installed)) {
      return(installed)
    }
  }

  path
}

poster_evidence_source <- function(path, envir = parent.frame()) {
  resolved <- poster_evidence_locate(path)
  if (!file.exists(resolved)) {
    stop("Could not find evidence source: ", path, call. = FALSE)
  }
  sys.source(resolved, envir = envir)
  invisible(resolved)
}

export_poster_evidence_bundle <- function(output_dir = tempfile("ggwebgl-poster-evidence-"),
                                          run_benchmarks = FALSE,
                                          export_galleries = FALSE,
                                          include_browser = FALSE,
                                          selfcontained = FALSE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  claims <- poster_evidence_claims()
  claims_path <- file.path(output_dir, "poster_claims.csv")
  utils::write.csv(claims, claims_path, row.names = FALSE)

  artifacts <- list(poster_claims = claims_path)

  if (isTRUE(export_galleries)) {
    gallery_dir <- file.path(output_dir, "galleries")
    dir.create(gallery_dir, recursive = TRUE, showWarnings = FALSE)

    gallery_env <- new.env(parent = globalenv())
    poster_evidence_source("inst/examples/htmlwidget/point-shader-modes.R", gallery_env)
    poster_evidence_source("inst/examples/htmlwidget/real-data-gallery.R", gallery_env)
    poster_evidence_source("inst/examples/htmlwidget/siggraph-showcase-gallery.R", gallery_env)
    poster_evidence_source("inst/examples/htmlwidget/siggraph-milestone3-gallery.R", gallery_env)
    poster_evidence_source("inst/examples/htmlwidget/downstream-adapter-interfaces.R", gallery_env)

    artifacts$point_shader_modes <- gallery_env$export_point_shader_mode_gallery(
      output_dir = file.path(gallery_dir, "point-shader-modes"),
      selfcontained = selfcontained
    )
    artifacts$real_data <- gallery_env$export_real_data_gallery(
      output_dir = file.path(gallery_dir, "real-data"),
      selfcontained = selfcontained
    )
    artifacts$showcase <- gallery_env$export_siggraph_showcase_gallery(
      output_dir = file.path(gallery_dir, "showcase"),
      selfcontained = selfcontained
    )
    artifacts$milestone3 <- gallery_env$export_siggraph_milestone3_gallery(
      output_dir = file.path(gallery_dir, "milestone3"),
      selfcontained = selfcontained
    )
    artifacts$adapters <- gallery_env$export_downstream_adapter_gallery(
      output_dir = file.path(gallery_dir, "adapters"),
      selfcontained = selfcontained
    )
  }

  if (isTRUE(run_benchmarks)) {
    benchmark_dir <- file.path(output_dir, "benchmarks")
    benchmark_env <- new.env(parent = globalenv())
    plot_env <- new.env(parent = globalenv())

    poster_evidence_source("inst/benchmarks/benchmark-render-pipeline.R", benchmark_env)
    metrics <- benchmark_env$benchmark_render_pipeline(
      output_dir = benchmark_dir,
      selfcontained = selfcontained,
      include_browser = include_browser
    )
    artifacts$benchmark_metrics <- attr(metrics, "metrics_path")

    poster_evidence_source("inst/benchmarks/plot-benchmark-results.R", plot_env)
    overview <- file.path(benchmark_dir, "benchmark_overview.png")
    plot_env$plot_benchmark_results(metrics, output_file = overview)
    artifacts$benchmark_overview <- overview
  }

  result <- list(
    output_dir = normalizePath(output_dir, winslash = "/", mustWork = FALSE),
    claims = claims,
    artifacts = artifacts
  )

  invisible(result)
}

if (sys.nframe() == 0L) {
  result <- export_poster_evidence_bundle()
  message("Poster evidence claims written to: ", result$artifacts$poster_claims)
}
