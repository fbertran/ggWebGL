test_that("theme_webgl metadata is attached to ggplot objects", {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point() +
    theme_webgl(shader = "density", buffer_size = 2048L, interactions = c("pan", "hover"))

  expect_equal(plot$ggwebgl[["shader"]], "density_splat")
  expect_equal(plot$ggwebgl[["buffer_size"]], 2048L)
  expect_equal(plot$ggwebgl[["interactions"]], c("pan", "hover"))
  expect_equal(plot$ggwebgl[["rendering"]], "visualization")
  expect_equal(plot$ggwebgl[["panel_overlay"]], "auto")
})

test_that("theme_webgl normalizes renderer options and isolates unknown extras", {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point() +
    theme_webgl(
      shader = "trajectory_age_glow",
      line_mode = "native",
      line_join = "round",
      line_cap = "butt",
      demo_flag = "keep-me"
    )

  expect_equal(plot$ggwebgl[["shader"]], "trajectory_age_glow")
  expect_equal(plot$ggwebgl[["line_mode"]], "native")
  expect_equal(plot$ggwebgl[["line_join"]], "round")
  expect_equal(plot$ggwebgl[["line_cap"]], "butt")
  expect_equal(plot$ggwebgl[["extra"]], list(demo_flag = "keep-me"))
})

test_that("publication rendering defaults and explicit overrides are normalized", {
  base_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point()

  publication_plot <- base_plot + theme_webgl(rendering = "publication")
  explicit_plot <- base_plot + theme_webgl(
    rendering = "publication",
    interactions = "hover",
    transparent = TRUE,
    panel_overlay = "show"
  )
  merged_plot <- base_plot +
    theme_webgl(shader = "density") +
    theme_webgl(rendering = "publication")

  expect_equal(publication_plot$ggwebgl[["rendering"]], "publication")
  expect_equal(publication_plot$ggwebgl[["interactions"]], character())
  expect_false(publication_plot$ggwebgl[["transparent"]])
  expect_equal(publication_plot$ggwebgl[["panel_overlay"]], "auto")

  expect_equal(explicit_plot$ggwebgl[["interactions"]], "hover")
  expect_true(explicit_plot$ggwebgl[["transparent"]])
  expect_equal(explicit_plot$ggwebgl[["panel_overlay"]], "show")

  expect_equal(merged_plot$ggwebgl[["shader"]], "density_splat")
  expect_equal(merged_plot$ggwebgl[["rendering"]], "publication")
})

test_that("WebGL geoms use distinct geom classes", {
  point_layer <- geom_point_webgl()
  line_layer <- geom_line_webgl()
  path_layer <- geom_path_webgl()
  raster_layer <- geom_raster_webgl()

  expect_equal(class(point_layer$geom)[1], "GeomPointWebGL")
  expect_equal(class(line_layer$geom)[1], "GeomLineWebGL")
  expect_equal(class(path_layer$geom)[1], "GeomPathWebGL")
  expect_equal(class(raster_layer$geom)[1], "GeomRasterWebGL")
})

test_that("ggplot_webgl creates a canonical single-panel point payload", {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt, colour = factor(cyl))) +
    geom_point_webgl(size = 2) +
    theme_webgl(shader = "default")

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]
  panel <- render[["panels"]][[1]]

  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$x[["layer_count"]], 1L)
  expect_equal(widget$x[["webgl"]][["shader"]], "default")
  expect_equal(widget$x[["webgl"]][["rendering"]], "visualization")
  expect_equal(widget$x[["webgl"]][["panel_overlay"]], "auto")
  expect_true(all(c("labels", "webgl", "layer_count", "layers", "render") %in% names(widget$x)))
  expect_true(all(c(
    "mode", "grid", "panels", "primitives", "point_count",
    "line_vertex_count", "path_count", "raster_cell_count",
    "unsupported_layers", "messages", "panel", "viewport", "layers"
  ) %in% names(render)))
  expect_false("message" %in% names(render))
  expect_equal(render[["mode"]], "webgl")
  expect_equal(render[["primitives"]], "points")
  expect_equal(render[["point_count"]], nrow(mtcars))
  expect_equal(render[["raster_cell_count"]], 0L)
  expect_length(render[["panels"]], 1L)
  expect_true(all(c(
    "panel_id", "row", "col", "bounds", "viewport", "primitives",
    "point_count", "line_vertex_count", "path_count", "raster_cell_count", "layers"
  ) %in% names(panel)))
  expect_identical(render[["panel"]], panel[["panel_id"]])
  expect_identical(render[["viewport"]], panel[["viewport"]])
  expect_identical(render[["layers"]], panel[["layers"]])
  expect_length(render[["layers"]][[1]][["x"]], nrow(mtcars))
  expect_equal(render[["layers"]][[1]][["age"]], rep(1, nrow(mtcars)))
  expect_length(render[["layers"]][[1]][["rgba"]], nrow(mtcars) * 4L)
  expect_equal(widget$x[["layers"]][[1]][["geom"]], "GeomPointWebGL")
})

test_that("line layers are serialised into a WebGL render plan", {
  df <- data.frame(
    x = c(1, 2, 3, 1, 2, 3),
    y = c(1, 2, 1, 2, 3, 2),
    g = c("a", "a", "a", "b", "b", "b")
  )

  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = g, group = g)) +
    geom_line_webgl() +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]
  layer <- render[["layers"]][[1]]

  expect_equal(render[["mode"]], "webgl")
  expect_true("lines" %in% render[["primitives"]])
  expect_equal(render[["line_vertex_count"]], nrow(df))
  expect_equal(render[["path_count"]], 2L)
  expect_equal(layer[["type"]], "lines")
  expect_length(layer[["paths"]], 2L)
  expect_equal(range(layer[["paths"]][[1]][["age"]]), c(0, 1))
})

test_that("unsupported non-WebGL layers stay explicit in the render plan", {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_smooth(se = FALSE) +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]

  expect_equal(render[["mode"]], "metadata")
  expect_length(render[["unsupported_layers"]], 1L)
  expect_equal(render[["unsupported_layers"]][[1]][["geom"]], "GeomSmooth")
  expect_true("messages" %in% names(render))
  expect_false("message" %in% names(render))
})

test_that("raster-only plots render in WebGL mode", {
  grid <- expand.grid(x = 1:5, y = 1:4)
  grid$z <- with(grid, x * y)

  plot <- ggplot2::ggplot(grid, ggplot2::aes(x, y, fill = z)) +
    geom_raster_webgl(interpolate = TRUE) +
    ggplot2::scale_fill_gradient(low = "#000000", high = "#ffffff") +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]
  layer <- render[["layers"]][[1]]

  expect_equal(render[["mode"]], "webgl")
  expect_equal(render[["primitives"]], "raster")
  expect_equal(render[["raster_cell_count"]], nrow(grid))
  expect_length(render[["unsupported_layers"]], 0L)
  expect_equal(layer[["type"]], "raster")
  expect_equal(layer[["width"]], 5L)
  expect_equal(layer[["height"]], 4L)
  expect_true(layer[["interpolate"]])
  expect_equal(length(layer[["rgba"]]), nrow(grid) * 4L)
})

test_that("raster interpolate metadata is preserved", {
  grid <- expand.grid(x = 1:4, y = 1:3)
  grid$z <- with(grid, x + y)

  plot_linear <- ggplot2::ggplot(grid, ggplot2::aes(x, y, fill = z)) +
    geom_raster_webgl(interpolate = TRUE) +
    theme_webgl()
  plot_nearest <- ggplot2::ggplot(grid, ggplot2::aes(x, y, fill = z)) +
    geom_raster_webgl(interpolate = FALSE) +
    theme_webgl()

  widget_linear <- ggplot_webgl(plot_linear)
  widget_nearest <- ggplot_webgl(plot_nearest)

  expect_true(widget_linear$x[["render"]][["layers"]][[1]][["interpolate"]])
  expect_false(widget_nearest$x[["render"]][["layers"]][[1]][["interpolate"]])
})

test_that("mixed raster, line, and point layers preserve render order", {
  grid <- expand.grid(x = seq(-1, 1, length.out = 6), y = seq(-1, 1, length.out = 5))
  grid$z <- with(grid, x * y)
  curve <- data.frame(x = seq(-1, 1, length.out = 20))
  curve$y <- sin(curve$x * pi)
  points <- curve[seq(1, nrow(curve), by = 5), , drop = FALSE]

  plot <- ggplot2::ggplot() +
    geom_raster_webgl(
      data = grid,
      mapping = ggplot2::aes(x, y, fill = z),
      interpolate = FALSE
    ) +
    geom_line_webgl(
      data = curve,
      mapping = ggplot2::aes(x, y),
      colour = "#0f766e",
      linewidth = 1.2
    ) +
    geom_point_webgl(
      data = points,
      mapping = ggplot2::aes(x, y),
      colour = "#b45309",
      size = 2
    ) +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]

  expect_equal(
    vapply(render[["layers"]], function(layer) layer[["type"]], character(1)),
    c("raster", "lines", "points")
  )
})

test_that("facet_wrap creates a panel-aware render plan", {
  plot <- ggplot2::ggplot(transform(mtcars, cyl = factor(cyl)), ggplot2::aes(mpg, wt, colour = cyl)) +
    geom_point_webgl(size = 2) +
    ggplot2::facet_wrap(~cyl) +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]
  panel_points <- vapply(render[["panels"]], function(panel) panel[["point_count"]], integer(1))

  expect_equal(render[["mode"]], "webgl")
  expect_length(render[["panels"]], 3L)
  expect_equal(render[["grid"]][["rows"]], 1L)
  expect_equal(render[["grid"]][["cols"]], 3L)
  expect_equal(render[["point_count"]], sum(panel_points))
  expect_null(render[["layers"]])
  expect_null(render[["viewport"]])
  expect_equal(
    vapply(render[["panels"]], function(panel) {
      if (is.null(panel[["label"]])) {
        return("")
      }

      panel[["label"]]
    }, character(1)),
    c("cyl=4", "cyl=6", "cyl=8")
  )
})

test_that("facet_grid creates a panel-aware render plan", {
  df <- expand.grid(
    row_group = c("A", "B"),
    col_group = c("U", "V", "W"),
    id = seq_len(6)
  )
  df$x <- c(1, 2, 3, 4, 5, 6)
  df$y <- c(1, 3, 2, 4, 3, 5)

  plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = row_group)) +
    geom_point_webgl(size = 3) +
    ggplot2::facet_grid(row_group ~ col_group) +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]

  expect_equal(render[["mode"]], "webgl")
  expect_length(render[["panels"]], 6L)
  expect_equal(render[["grid"]][["rows"]], 2L)
  expect_equal(render[["grid"]][["cols"]], 3L)
  expect_equal(sum(vapply(render[["panels"]], function(panel) panel[["point_count"]], integer(1))), nrow(df))
})

test_that("free-scale facets use exact messages contract", {
  plot <- ggplot2::ggplot(transform(mtcars, cyl = factor(cyl)), ggplot2::aes(mpg, wt, colour = cyl)) +
    geom_point_webgl(size = 2) +
    ggplot2::facet_wrap(~cyl, scales = "free_x") +
    theme_webgl()

  widget <- ggplot_webgl(plot)
  render <- widget$x[["render"]]

  expect_equal(render[["mode"]], "metadata")
  expect_true("messages" %in% names(render))
  expect_false("message" %in% names(render))
  expect_length(render[["messages"]], 1L)
  expect_match(render[["messages"]][[1]], "fixed-scale facets")
  expect_length(render[["panels"]], 3L)
})
