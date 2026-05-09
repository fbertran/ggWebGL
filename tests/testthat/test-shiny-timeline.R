fake_timeline_session <- function(prefix = "") {
  store <- new.env(parent = emptyenv())
  store$messages <- list()
  session <- list(
    ns = function(id) paste0(prefix, id),
    sendCustomMessage = function(type, message) {
      store$messages[[length(store$messages) + 1L]] <- list(type = type, message = message)
    }
  )
  list(
    session = session,
    messages = function() store$messages
  )
}

locate_shiny_timeline_js <- function() {
  candidates <- c(
    file.path(getwd(), "inst/htmlwidgets/ggWebGL.js"),
    file.path(testthat::test_path(), "..", "..", "inst/htmlwidgets/ggWebGL.js"),
    system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    skip("ggWebGL.js is unavailable in this test context.")
  }
  found[[1L]]
}

read_shiny_timeline_js <- function() {
  paste(readLines(locate_shiny_timeline_js(), warn = FALSE), collapse = "\n")
}

test_that("updateGgWebGLTimeline is exported", {
  expect_true("updateGgWebGLTimeline" %in% getNamespaceExports("ggWebGL"))
})

test_that("updateGgWebGLTimeline sends a namespaced custom message", {
  fake <- fake_timeline_session("module-")

  result <- updateGgWebGLTimeline(
    fake$session,
    "plot",
    index = 2L,
    playing = TRUE,
    speed = 1.5,
    loop = FALSE
  )

  expect_null(result)
  messages <- fake$messages()
  expect_length(messages, 1L)
  expect_equal(messages[[1L]]$type, "ggWebGL:updateTimeline")
  expect_equal(messages[[1L]]$message$id, "module-plot")
  expect_equal(messages[[1L]]$message$outputId, "module-plot")
  expect_equal(messages[[1L]]$message$index, 2L)
  expect_true(messages[[1L]]$message$playing)
  expect_equal(messages[[1L]]$message$speed, 1.5)
  expect_false(messages[[1L]]$message$loop)
  expect_false("value" %in% names(messages[[1L]]$message))
})

test_that("updateGgWebGLTimeline can send a value-only update", {
  fake <- fake_timeline_session()

  updateGgWebGLTimeline(fake$session, "plot", value = 3.25)

  message <- fake$messages()[[1L]]$message
  expect_equal(message$id, "plot")
  expect_equal(message$value, 3.25)
  expect_false("index" %in% names(message))
})

test_that("updateGgWebGLTimeline validates update inputs", {
  fake <- fake_timeline_session()

  expect_error(updateGgWebGLTimeline(fake$session, "plot", value = 1, index = 1), "one of `value` or `index`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", index = 0), "`index`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", index = 1.5), "`index`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", index = NA_real_), "`index`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", speed = 0), "`speed`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", speed = NA_real_), "`speed`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", playing = NA), "`playing`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", playing = c(TRUE, FALSE)), "`playing`")
  expect_error(updateGgWebGLTimeline(fake$session, "plot", loop = NA), "`loop`")
  expect_error(updateGgWebGLTimeline(list(), "plot"), "`session`")
})

test_that("JavaScript emits timeline state through Shiny input events", {
  js <- read_shiny_timeline_js()

  expect_match(js, "function emitTimelineState(el, state, reason)", fixed = TRUE)
  expect_match(js, "window.Shiny.setInputValue(el.id + \"_timeline\"", fixed = TRUE)
  expect_match(js, "{ priority: \"event\" }", fixed = TRUE)
  expect_match(js, "payload.reason = String(reason);", fixed = TRUE)
  expect_match(js, "emitTimelineState(el, state, state.timeline.playing ? \"play\" : \"pause\")", fixed = TRUE)
  expect_match(js, "emitTimelineState(el, state, \"scrub\")", fixed = TRUE)
  expect_match(js, "emitTimelineState(el, state, \"reset\")", fixed = TRUE)
  expect_match(js, "emitTimelineState(el, state, \"tick\")", fixed = TRUE)
})

test_that("JavaScript handles Shiny timeline update messages", {
  js <- read_shiny_timeline_js()

  expect_match(js, "ggWebGL:updateTimeline", fixed = TRUE)
  expect_match(js, "window.Shiny.addCustomMessageHandler(TIMELINE_UPDATE_MESSAGE_TYPE", fixed = TRUE)
  expect_match(js, "function applyTimelineUpdate(message)", fixed = TRUE)
  expect_match(js, "registerShinyTimelineHandler()", fixed = TRUE)
  expect_match(js, "Number(incoming.index) - 1", fixed = TRUE)
  expect_match(js, "setTimelineValue(state.timeline, incoming.value)", fixed = TRUE)
  expect_match(js, "emitTimelineState(el, state, \"update\")", fixed = TRUE)
})

test_that("Shiny timeline integration preserves renderer feature boundaries", {
  js <- read_shiny_timeline_js()

  expect_match(js, "function createTimelineState(spec, previous)", fixed = TRUE)
  expect_match(js, "function pathSegmentVisible(path, i0, i1, x)", fixed = TRUE)
  expect_match(js, "trajectory_velocity", fixed = TRUE)
  expect_match(js, "trajectory_direction", fixed = TRUE)
  expect_false(grepl("trajectory_acceleration", js, fixed = TRUE))
  expect_false(grepl("trajectory_curvature", js, fixed = TRUE))
})
