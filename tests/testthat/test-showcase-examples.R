locate_example_script <- function(path_parts, installed_parts = path_parts[-1L]) {
  candidates <- c(
    do.call(file.path, as.list(path_parts)),
    do.call(file.path, c("tests", "testthat", "..", "..", as.list(path_parts))),
    do.call(system.file, c(as.list(installed_parts), package = "ggWebGL"))
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    return(NA_character_)
  }

  found[[1]]
}

test_that("showcase presets produce the expected scenarios and heavier render plans", {
  helper_env <- new.env(parent = globalenv())
  helper_path <- locate_example_script(
    path_parts = c("inst", "examples", "showcase", "showcase-helpers.R"),
    installed_parts = c("examples", "showcase", "showcase-helpers.R")
  )

  expect_false(
    is.na(helper_path),
    info = "Could not locate inst/examples/showcase/showcase-helpers.R"
  )
  if (is.na(helper_path)) {
    return(invisible())
  }

  sys.source(helper_path, envir = helper_env)

  standard_plots <- helper_env$showcase_plots(seed = 42L, detail = "standard")
  high_detail_plots <- helper_env$showcase_plots(seed = 42L, detail = "high_detail")

  expect_named(
    standard_plots,
    c("latent_cloud", "diffusion_paths", "phase_portrait", "loss_landscape")
  )
  expect_named(high_detail_plots, names(standard_plots))
  expect_true(all(vapply(standard_plots, inherits, logical(1), what = "ggplot")))
  expect_true(all(vapply(high_detail_plots, inherits, logical(1), what = "ggplot")))

  standard_widgets <- lapply(standard_plots, ggplot_webgl)
  high_detail_widgets <- lapply(high_detail_plots, ggplot_webgl)

  expect_true(all(vapply(standard_widgets, inherits, logical(1), what = "htmlwidget")))
  expect_true(all(vapply(high_detail_widgets, inherits, logical(1), what = "htmlwidget")))
  expect_true(all(vapply(standard_widgets, function(x) x$x$render$mode == "webgl", logical(1))))
  expect_true(all(vapply(high_detail_widgets, function(x) x$x$render$mode == "webgl", logical(1))))
  expect_equal(standard_widgets$latent_cloud$x$webgl$shader, "density_splat")
  expect_equal(standard_widgets$diffusion_paths$x$webgl$shader, "trajectory_age")
  expect_equal(standard_widgets$phase_portrait$x$webgl$shader, "trajectory_age")
  expect_equal(standard_widgets$loss_landscape$x$webgl$shader, "density_splat")

  expect_gt(
    high_detail_widgets$latent_cloud$x$render$point_count,
    standard_widgets$latent_cloud$x$render$point_count
  )
  expect_gt(
    high_detail_widgets$diffusion_paths$x$render$line_vertex_count,
    standard_widgets$diffusion_paths$x$render$line_vertex_count
  )
  expect_gt(
    high_detail_widgets$diffusion_paths$x$render$path_count,
    standard_widgets$diffusion_paths$x$render$path_count
  )
  expect_gt(
    high_detail_widgets$phase_portrait$x$render$line_vertex_count,
    standard_widgets$phase_portrait$x$render$line_vertex_count
  )
  expect_gt(
    high_detail_widgets$phase_portrait$x$render$path_count,
    standard_widgets$phase_portrait$x$render$path_count
  )
  expect_gt(
    high_detail_widgets$loss_landscape$x$render$point_count,
    standard_widgets$loss_landscape$x$render$point_count
  )
  expect_gt(
    high_detail_widgets$loss_landscape$x$render$path_count,
    standard_widgets$loss_landscape$x$render$path_count
  )
})

test_that("high-detail showcase gallery exports all html files", {
  gallery_env <- new.env(parent = globalenv())
  gallery_path <- locate_example_script(
    path_parts = c("inst", "examples", "htmlwidget", "renderer-showcase-gallery.R"),
    installed_parts = c("examples", "htmlwidget", "renderer-showcase-gallery.R")
  )

  expect_false(
    is.na(gallery_path),
    info = "Could not locate inst/examples/htmlwidget/renderer-showcase-gallery.R"
  )
  if (is.na(gallery_path)) {
    return(invisible())
  }

  sys.source(gallery_path, envir = gallery_env)

  output_dir <- tempfile("ggwebgl-showcase-test-")
  files <- gallery_env$export_renderer_showcase_gallery(
    output_dir = output_dir,
    selfcontained = FALSE,
    detail = "high_detail"
  )
  index_path <- attr(files, "index")

  expect_length(files, 4L)
  expect_named(files, c("latent_cloud", "diffusion_paths", "phase_portrait", "loss_landscape"))
  expect_true(all(file.exists(unname(files))))
  expect_true(is.character(index_path) && length(index_path) == 1L)
  expect_true(file.exists(index_path))

  index_lines <- readLines(index_path, warn = FALSE)
  expect_true(any(grepl("Renderer Showcase Exports", index_lines, fixed = TRUE)))
  expect_true(any(grepl("latent_cloud.html", index_lines, fixed = TRUE)))
  expect_true(any(grepl("diffusion_paths.html", index_lines, fixed = TRUE)))
  expect_true(any(grepl("phase_portrait.html", index_lines, fixed = TRUE)))
  expect_true(any(grepl("loss_landscape.html", index_lines, fixed = TRUE)))
})
