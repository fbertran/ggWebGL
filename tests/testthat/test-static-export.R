skip_if_no_static_export_support <- function() {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    skip("chromote is not installed.")
  }
  if (!requireNamespace("magick", quietly = TRUE)) {
    skip("magick is not installed.")
  }

  browser_ok <- tryCatch({
    had_default <- chromote::has_default_chromote_object()
    browser <- chromote::Chromote$new()
    session <- NULL
    on.exit(
      {
        if (!is.null(session)) {
          try(session$close(), silent = TRUE)
        }
        try(browser$close(wait = TRUE), silent = TRUE)
        if (!had_default && chromote::has_default_chromote_object()) {
          default_chromote_object <- get0(
            "default_chromote_object",
            envir = asNamespace("chromote"),
            inherits = FALSE
          )
          if (is.function(default_chromote_object)) {
            try(default_chromote_object()$close(wait = TRUE), silent = TRUE)
          }
        }
      },
      add = TRUE
    )
    session <- browser$new_session(width = 320, height = 220, wait_ = TRUE)
    TRUE
  }, error = function(e) FALSE)

  if (!browser_ok) {
    skip("A browser session is unavailable for static export tests.")
  }
}

static_export_plot <- function() {
  ggplot2::ggplot(
    data.frame(
      x = c(0, 1, 2, 3),
      y = c(0, 1, 0.4, 1.3),
      group = factor(c("A", "A", "B", "B"))
    ),
    ggplot2::aes(x, y, colour = group)
  ) +
    geom_point_webgl(size = 2.2, alpha = 0.55) +
    ggplot2::scale_colour_manual(values = c(A = "#0f766e", B = "#f97316"), guide = "none") +
    ggplot2::theme_void() +
    theme_webgl(shader = "density_splat", interactions = character(), transparent = FALSE)
}

count_supervisor_connections <- function() {
  connections <- showConnections(all = TRUE)
  if (is.null(connections) || !nrow(connections)) {
    return(0L)
  }

  sum(grepl("supervisor_(stdin|stdout)", connections[, "description"]))
}

test_that("snapshot_ggwebgl writes static images from ggplot, widget, and spec inputs", {
  skip_if_no_static_export_support()

  plot <- static_export_plot()
  widget <- ggplot_webgl(plot, width = 480, height = 320)
  spec <- ggwebgl_spec(
    layers = list(
      ggwebgl_layer_points(
        data.frame(x = c(0.1, 0.5, 0.9), y = c(0.2, 0.8, 0.4)),
        x = "x",
        y = "y",
        colour = "#2563eb",
        alpha = 0.8,
        size = 3
      )
    ),
    webgl = list(shader = "default", interactions = character())
  )

  files <- c(
    ggplot = tempfile(fileext = ".jpg"),
    widget = tempfile(fileext = ".png"),
    spec = tempfile(fileext = ".jpg")
  )

  snapshot_ggwebgl(plot, files[["ggplot"]], width = 640, height = 420, format = "jpeg", wait_seconds = 0.6)
  snapshot_ggwebgl(widget, files[["widget"]], width = 640, height = 420, format = "png", wait_seconds = 0.6)
  snapshot_ggwebgl(spec, files[["spec"]], width = 640, height = 420, format = "jpeg", wait_seconds = 0.6)

  expect_true(all(file.exists(files)))

  infos <- lapply(files, function(path) magick::image_info(magick::image_read(path)))
  expect_equal(infos$ggplot$format[[1L]], "JPEG")
  expect_equal(infos$widget$format[[1L]], "PNG")
  expect_equal(infos$spec$format[[1L]], "JPEG")
  expect_true(all(vapply(infos, function(info) info$width[[1L]], integer(1)) == 640L))
  expect_true(all(vapply(infos, function(info) info$height[[1L]], integer(1)) == 420L))
})

test_that("snapshot_ggwebgl writes static images from publication figures", {
  skip_if_no_static_export_support()

  figure <- ggwebgl_publication_figure(
    panels = list(
      ggwebgl_spec(
        layers = list(
          ggwebgl_layer_points(
            data.frame(x = c(0.15, 0.52, 0.84), y = c(0.20, 0.78, 0.42)),
            x = "x",
            y = "y",
            colour = c("#0f766e", "#f97316", "#2563eb"),
            alpha = 0.8,
            size = 5
          )
        )
      )
    ),
    annotations = list(list(
      text = "publication",
      x = 0.96,
      y = 0.93,
      hjust = 1,
      size = 18,
      colour = "#64748b"
    )),
    width = 420,
    height = 260,
    preset = "publication"
  )
  output <- tempfile(fileext = ".jpg")

  snapshot_ggwebgl(figure, output, format = "jpeg", wait_seconds = 0.6)

  expect_true(file.exists(output))
  info <- magick::image_info(magick::image_read(output))
  expect_equal(info$format[[1L]], "JPEG")
  expect_equal(info$width[[1L]], 420L)
  expect_equal(info$height[[1L]], 260L)
})

test_that("compose_ggwebgl_figure assembles row figures with labels and annotations", {
  skip_if_no_static_export_support()

  plot <- static_export_plot()
  output <- tempfile(fileext = ".jpg")

  compose_ggwebgl_figure(
    panels = list(
      plot + theme_webgl(shader = "default", interactions = character(), transparent = FALSE),
      plot
    ),
    file = output,
    width = 720,
    height = 320,
    format = "jpeg",
    layout = "row",
    labels = c("raw", "density"),
    annotations = list(list(
      text = "demo",
      x = 0.96,
      y = 0.94,
      hjust = 1,
      size = 20,
      colour = "#64748b"
    )),
    preset = "publication",
    wait_seconds = 0.6
  )

  expect_true(file.exists(output))
  info <- magick::image_info(magick::image_read(output))
  expect_equal(info$format[[1L]], "JPEG")
  expect_equal(info$width[[1L]], 720L)
  expect_equal(info$height[[1L]], 320L)
})

test_that("snapshot_ggwebgl can run twice with private browser cleanup", {
  skip_if_no_static_export_support()

  plot <- static_export_plot()
  files <- c(tempfile(fileext = ".png"), tempfile(fileext = ".png"))

  snapshot_ggwebgl(plot, files[[1L]], width = 360, height = 240, format = "png", wait_seconds = 0.25)
  snapshot_ggwebgl(plot, files[[2L]], width = 360, height = 240, format = "png", wait_seconds = 0.25)

  expect_true(all(file.exists(files)))
  infos <- lapply(files, function(path) magick::image_info(magick::image_read(path)))
  expect_true(all(vapply(infos, function(info) identical(info$format[[1L]], "PNG"), logical(1))))
  expect_true(all(vapply(infos, function(info) info$width[[1L]], integer(1)) == 360L))
  expect_true(all(vapply(infos, function(info) info$height[[1L]], integer(1)) == 240L))
})

test_that("static export can clear processx supervisor connections when requested", {
  skip_if_no_static_export_support()
  old <- options(ggwebgl.reset_processx_supervisor = TRUE)
  on.exit(options(old), add = TRUE)

  plot <- static_export_plot()
  output <- tempfile(fileext = ".jpg")

  compose_ggwebgl_figure(
    panels = list(plot),
    file = output,
    width = 480,
    height = 320,
    format = "jpeg",
    layout = "single",
    preset = "clean",
    wait_seconds = 0.25
  )

  expect_true(file.exists(output))
  expect_equal(count_supervisor_connections(), 0L)
})

test_that("compose_ggwebgl_figure supports inset composition and format validation", {
  skip_if_no_static_export_support()

  plot <- static_export_plot()
  output <- tempfile(fileext = ".png")

  compose_ggwebgl_figure(
    panels = list(plot),
    file = output,
    width = 900,
    height = 600,
    format = "png",
    layout = "single",
    inset = list(
      source = plot,
      left = 0.68,
      top = 0.08,
      width = 0.26,
      height = 0.26,
      border = TRUE
    ),
    preset = "publication",
    wait_seconds = 0.6
  )

  expect_true(file.exists(output))
  info <- magick::image_info(magick::image_read(output))
  expect_equal(info$format[[1L]], "PNG")
  expect_equal(info$width[[1L]], 900L)
  expect_equal(info$height[[1L]], 600L)

  expect_error(
    snapshot_ggwebgl(plot, tempfile(fileext = ".bmp"), format = "bmp"),
    "format"
  )
})
