test_that("geom_bar_webgl serializes discrete count bars from ggplot2 stats", {
  bars <- data.frame(group = c("a", "a", "b", "c", "c", "c"))
  plot <- ggplot2::ggplot(bars, ggplot2::aes(group)) +
    geom_bar_webgl(fill = "#2563eb") +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$type, "rects")
  expect_equal(layer$geom, "GeomBarWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(layer$count, built$count)
  expect_null(layer$density)
})

test_that("geom_bar_webgl preserves stacked bar rectangles", {
  bars <- data.frame(
    group = c("a", "a", "a", "b", "b"),
    fill = c("u", "v", "u", "u", "v")
  )
  plot <- ggplot2::ggplot(bars, ggplot2::aes(group, fill = fill)) +
    geom_bar_webgl(position = "stack") +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(layer$count, built$count)
  expect_true(any(layer$ymin > 0))
})

test_that("geom_bar_webgl preserves dodged bar rectangles", {
  bars <- data.frame(
    group = c("a", "a", "b", "b", "b", "b"),
    fill = c("u", "v", "u", "v", "u", "v")
  )
  plot <- ggplot2::ggplot(bars, ggplot2::aes(group, fill = fill)) +
    geom_bar_webgl(position = "dodge") +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_true(length(unique(round(layer$xmin, 6))) > length(unique(bars$group)))
})

test_that("geom_histogram_webgl serializes stat_bin rectangles with binwidth", {
  values <- data.frame(x = c(0.1, 0.2, 0.7, 1.2, 1.6, 2.1, 2.2, 2.8))
  plot <- ggplot2::ggplot(values, ggplot2::aes(x)) +
    geom_histogram_webgl(binwidth = 1, boundary = 0, fill = "#0f766e") +
    theme_webgl()

  built <- ggplot2::ggplot_build(plot)$data[[1L]]
  layer <- ggplot_webgl(plot)$x$render$layers[[1L]]

  expect_equal(layer$type, "rects")
  expect_equal(layer$geom, "GeomBarWebGL")
  expect_equal(layer$rows, nrow(built))
  expect_equal(layer$xmin, built$xmin)
  expect_equal(layer$xmax, built$xmax)
  expect_equal(layer$ymin, built$ymin)
  expect_equal(layer$ymax, built$ymax)
  expect_equal(layer$count, built$count)
  expect_equal(layer$density, built$density)
  expect_true(all(diff(layer$xmin) >= 0))
})

test_that("bar and histogram rects split across fixed-scale facets", {
  bars <- data.frame(
    group = c("a", "a", "b", "a", "b", "b"),
    panel = c("left", "left", "left", "right", "right", "right")
  )
  plot <- ggplot2::ggplot(bars, ggplot2::aes(group)) +
    geom_bar_webgl(fill = "#38bdf8") +
    ggplot2::facet_wrap(~panel) +
    theme_webgl()

  render <- ggplot_webgl(plot)$x$render
  built <- ggplot2::ggplot_build(plot)$data[[1L]]

  expect_equal(render$mode, "webgl")
  expect_equal(render$rect_count, nrow(built))
  expect_equal(unname(vapply(render$panels, `[[`, integer(1), "rect_count")), c(2L, 2L))
  expect_true(all(vapply(render$panels, function(panel) {
    identical(panel$primitives, "rects")
  }, logical(1))))
})
