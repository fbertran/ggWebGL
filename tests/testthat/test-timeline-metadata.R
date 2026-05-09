timeline_widget <- function(plot) {
  ggplot_webgl(plot)$x
}

test_that("animation_spec is equivalent to ggwebgl_timeline", {
  timeline <- ggwebgl_timeline(frames = c(3L, 1L, 2L), speed = 1.25, filter = "cumulative")
  animation <- animation_spec(frames = c(3L, 1L, 2L), speed = 1.25, filter = "cumulative")

  expect_equal(animation, timeline)
})

test_that("scale_time_webgl attaches frame and time metadata to a ggplot", {
  frame_plot <- ggplot2::ggplot(
    data.frame(x = 1:2, y = 2:1, frame = 1:2),
    ggplot2::aes(x, y, frame = frame)
  ) +
    geom_point_webgl() +
    scale_time_webgl(source = "frame")

  time_plot <- ggplot2::ggplot(
    data.frame(x = 1:2, y = 2:1, time = c(0.1, 0.2)),
    ggplot2::aes(x, y, time = time)
  ) +
    geom_point_webgl() +
    scale_time_webgl(source = "time")

  expect_s3_class(frame_plot$ggwebgl$time_scale, "ggwebgl_time_scale")
  expect_equal(frame_plot$ggwebgl$time_scale$source, "frame")
  expect_s3_class(time_plot$ggwebgl$time_scale, "ggwebgl_time_scale")
  expect_equal(time_plot$ggwebgl$time_scale$source, "time")
})

test_that("scale_time_webgl auto source prefers time over frame", {
  data <- data.frame(
    x = 1:4,
    y = c(1, 3, 2, 4),
    frame = c(2L, 1L, 2L, 3L),
    time = c(0.2, 0.1, 0.2, 0.4)
  )

  widget <- timeline_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, frame = frame, time = time)) +
      geom_point_webgl() +
      scale_time_webgl(source = "auto")
  )

  expect_equal(widget$render$timeline$source, "time")
  expect_equal(widget$render$timeline$time, c(0.1, 0.2, 0.4))
})

test_that("timeline values are derived from built frame columns", {
  data <- data.frame(
    x = 1:5,
    y = c(1, 2, 3, 2, 1),
    frame = c(3L, 1L, 2L, 2L, 3L)
  )

  widget <- timeline_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, frame = frame)) +
      geom_point_webgl()
  )

  expect_equal(widget$render$timeline$source, "frame")
  expect_equal(widget$render$timeline$frames, 1:3)
  expect_identical(widget$render$timeline, widget$webgl$timeline)
})

test_that("timeline values are derived from built time columns", {
  data <- data.frame(
    x = 1:4,
    y = c(1, 4, 2, 3),
    time = c(0.5, 0, 0.25, 0.5)
  )

  widget <- timeline_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, time = time)) +
      geom_point_webgl()
  )

  expect_equal(widget$render$timeline$source, "time")
  expect_equal(widget$render$timeline$time, c(0, 0.25, 0.5))
})

test_that("explicit timeline values are not overridden by built data", {
  data <- data.frame(
    x = 1:4,
    y = c(2, 1, 3, 4),
    frame = 1:4,
    time = c(0, 0.5, 1, 1.5)
  )

  frame_widget <- timeline_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, frame = frame)) +
      geom_point_webgl() +
      theme_webgl(timeline = ggwebgl_timeline(frames = c(10L, 20L), filter = "exact"))
  )
  time_widget <- timeline_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, time = time)) +
      geom_point_webgl() +
      theme_webgl(timeline = animation_spec(values = c(2.5, 3.5), source = "time"))
  )

  expect_equal(frame_widget$render$timeline$frames, c(10L, 20L))
  expect_equal(time_widget$render$timeline$time, c(2.5, 3.5))
})

test_that("explicit scale_time_webgl values are not overridden by built data", {
  data <- data.frame(x = 1:4, y = c(1, 3, 2, 4), frame = 1:4)

  widget <- timeline_widget(
    ggplot2::ggplot(data, ggplot2::aes(x, y, frame = frame)) +
      geom_point_webgl() +
      scale_time_webgl(source = "frame", values = c(8L, 6L), mode = "cumulative")
  )

  expect_equal(widget$render$timeline$frames, c(6L, 8L))
  expect_equal(widget$render$timeline$filter, "cumulative")
})

test_that("invalid timeline metadata errors clearly", {
  expect_error(scale_time_webgl(source = "bad"), "source")
  expect_error(scale_time_webgl(mode = "bad"), "filter|mode")
  expect_error(scale_time_webgl(speed = 0), "speed")
  expect_error(ggwebgl_timeline(speed = NA_real_), "speed")
  expect_error(ggwebgl_timeline(filter = "later"), "filter|mode")
})

test_that("plots without frame or time keep existing behavior", {
  widget <- timeline_widget(
    ggplot2::ggplot(data.frame(x = 1:2, y = 2:1), ggplot2::aes(x, y)) +
      geom_point_webgl()
  )

  expect_null(widget$render$timeline)
})

test_that("adapter specs derive render timeline from layer frame and time fields", {
  frame_layer <- ggwebgl_layer_points(
    data.frame(x = 1:3, y = c(1, 2, 1), frame = c(3L, 1L, 2L)),
    x = "x",
    y = "y",
    frame = "frame"
  )
  time_layer <- ggwebgl_layer_lines(
    data.frame(x = 1:3, y = c(0, 1, 0), time = c(0, 0.5, 1)),
    x = "x",
    y = "y",
    time = "time"
  )

  frame_spec <- ggwebgl_spec(list(frame_layer))
  time_spec <- ggwebgl_spec(list(time_layer), timeline = ggwebgl_timeline(speed = 1.5))

  expect_equal(frame_spec$render$timeline$frames, 1:3)
  expect_equal(time_spec$render$timeline$time, c(0, 0.5, 1))
  expect_equal(time_spec$render$timeline$speed, 1.5)
})
