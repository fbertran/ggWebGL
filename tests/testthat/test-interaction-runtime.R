chromote_available <- function() {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    return(FALSE)
  }
  ok <- tryCatch({
    browser <- chromote::Chromote$new()
    on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
    session <- browser$new_session(width = 640, height = 420, wait_ = TRUE)
    try(session$close(), silent = TRUE)
    TRUE
  }, error = function(e) FALSE)
  isTRUE(ok)
}

locate_future_work_example_for_runtime <- function() {
  candidates <- c(
    file.path(getwd(), "inst", "examples", "htmlwidget", "future-work-gallery.R"),
    file.path(getwd(), "tests", "testthat", "..", "..", "inst", "examples", "htmlwidget", "future-work-gallery.R"),
    system.file("examples", "htmlwidget", "future-work-gallery.R", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    return(NA_character_)
  }
  found[[1L]]
}

with_widget_page <- function(widget, code, width = 760, height = 520) {
  output <- tempfile(fileext = ".html")
  libdir <- tempfile()
  htmlwidgets::saveWidget(widget, output, selfcontained = FALSE, libdir = libdir)

  browser <- chromote::Chromote$new()
  on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
  session <- browser$new_session(width = width, height = height, wait_ = TRUE)
  on.exit(try(session$close(), silent = TRUE), add = TRUE)
  session$Page$navigate(paste0("file://", normalizePath(output)), wait_ = TRUE)
  try(session$Page$loadEventFired(wait_ = TRUE), silent = TRUE)
  Sys.sleep(0.8)
  force(code)(session)
}

runtime_point <- function(session, expr) {
  session$Runtime$evaluate(expr, returnByValue = TRUE)$result$value
}

mouse_event <- function(session, type, x, y) {
  session$Input$dispatchMouseEvent(
    type = type,
    x = x,
    y = y,
    button = "left",
    buttons = if (identical(type, "mouseReleased")) 0L else 1L,
    clickCount = if (identical(type, "mousePressed")) 1L else 0L
  )
}

test_that("browser smoke visibly updates brush and lasso selection", {
  if (!chromote_available()) {
    skip("A browser session is unavailable for interaction runtime tests.")
  }

  example_path <- locate_future_work_example_for_runtime()
  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  example_env <- new.env(parent = globalenv())
  sys.source(example_path, envir = example_env)
  widget <- example_env$future_work_selection_demo(n = 500L)

  with_widget_page(widget, function(session) {
    pts <- runtime_point(session, paste(
      "(() => {",
      "const r = document.querySelector('.ggwebgl__stage').getBoundingClientRect();",
      "return {x0:r.left+r.width*0.20,y0:r.top+r.height*0.30,x1:r.left+r.width*0.62,y1:r.top+r.height*0.72};",
      "})()",
      sep = "\n"
    ))
    mouse_event(session, "mousePressed", pts$x0, pts$y0)
    mouse_event(session, "mouseMoved", pts$x1, pts$y1)
    mouse_event(session, "mouseReleased", pts$x1, pts$y1)
    Sys.sleep(0.2)
    brush <- runtime_point(session, paste(
      "(() => ({",
      "status: document.querySelector('.ggwebgl__selection-status').textContent,",
      "overlay: !!document.querySelector('.ggwebgl__selection-overlay svg'),",
      "brushPressed: document.querySelector('[data-mode=\"brush\"]').getAttribute('aria-pressed')",
      "}))()",
      sep = "\n"
    ))
    expect_true(brush$overlay)
    expect_equal(brush$brushPressed, "true")
    expect_match(brush$status, "[1-9][0-9]* selected")

    runtime_point(session, "document.querySelector('[data-mode=\"lasso\"]').click(); true")
    pts2 <- runtime_point(session, paste(
      "(() => {",
      "const r = document.querySelector('.ggwebgl__stage').getBoundingClientRect();",
      "return {a:{x:r.left+r.width*0.18,y:r.top+r.height*0.34},b:{x:r.left+r.width*0.76,y:r.top+r.height*0.38},c:{x:r.left+r.width*0.70,y:r.top+r.height*0.76},d:{x:r.left+r.width*0.18,y:r.top+r.height*0.76}};",
      "})()",
      sep = "\n"
    ))
    mouse_event(session, "mousePressed", pts2$a$x, pts2$a$y)
    mouse_event(session, "mouseMoved", pts2$b$x, pts2$b$y)
    mouse_event(session, "mouseMoved", pts2$c$x, pts2$c$y)
    mouse_event(session, "mouseMoved", pts2$d$x, pts2$d$y)
    mouse_event(session, "mouseReleased", pts2$d$x, pts2$d$y)
    Sys.sleep(0.2)
    lasso <- runtime_point(session, paste(
      "(() => ({",
      "status: document.querySelector('.ggwebgl__selection-status').textContent,",
      "lassoPressed: document.querySelector('[data-mode=\"lasso\"]').getAttribute('aria-pressed')",
      "}))()",
      sep = "\n"
    ))
    expect_equal(lasso$lassoPressed, "true")
    expect_match(lasso$status, "[1-9][0-9]* selected")
  })
})

test_that("browser smoke timeline scrub changes exact-frame rendering", {
  if (!chromote_available()) {
    skip("A browser session is unavailable for interaction runtime tests.")
  }

  example_path <- locate_future_work_example_for_runtime()
  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  example_env <- new.env(parent = globalenv())
  sys.source(example_path, envir = example_env)
  widget <- example_env$future_work_timeline_demo(frames = 4L, n = 80L)

  with_widget_page(widget, function(session) {
    before <- runtime_point(session, "document.querySelector('.ggWebGL').ggwebglTimelineFrame")
    runtime_point(session, paste(
      "(() => {",
      "const scrub = document.querySelector('.ggwebgl__timeline-scrub');",
      "scrub.value = scrub.max;",
      "scrub.dispatchEvent(new Event('input', {bubbles:true}));",
      "return true;",
      "})()",
      sep = "\n"
    ))
    Sys.sleep(0.3)
    after <- runtime_point(session, "document.querySelector('.ggWebGL').ggwebglTimelineFrame")
    max_value <- runtime_point(session, "Number(document.querySelector('.ggwebgl__timeline-scrub').max) + 1")
    expect_false(identical(before, after))
    expect_equal(after, max_value)
  })
})

test_that("browser smoke linked magnifier brush updates the target panel", {
  if (!chromote_available()) {
    skip("A browser session is unavailable for interaction runtime tests.")
  }

  dat <- data.frame(
    x = c(stats::rnorm(120, -1.2, 0.12), stats::rnorm(120, 1.2, 0.12)),
    y = c(stats::rnorm(120, 0.2, 0.12), stats::rnorm(120, 0.1, 0.12))
  )
  source <- ggwebgl_spec(
    layers = list(ggwebgl_layer_points(dat, x = "x", y = "y", colour = "#2563eb", alpha = 0.65, size = 3)),
    panels = list(list(panel_id = 1L, row = 1L, col = 1L, viewport = list(x = c(-2, 2), y = c(-1, 1)))),
    webgl = list(interactions = character())
  )
  widget <- ggWebGL(
    ggwebgl_magnify_region(
      source,
      region = list(x = c(-1.5, -0.8), y = c(-0.2, 0.6)),
      display = "panel",
      interactive = TRUE
    ),
    height = 420
  )

  with_widget_page(widget, function(session) {
    pts <- runtime_point(session, paste(
      "(() => {",
      "const r = document.querySelector('.ggwebgl__stage').getBoundingClientRect();",
      "return {x0:r.left+r.width*0.17,y0:r.top+r.height*0.32,x1:r.left+r.width*0.39,y1:r.top+r.height*0.69};",
      "})()",
      sep = "\n"
    ))
    mouse_event(session, "mousePressed", pts$x0, pts$y0)
    mouse_event(session, "mouseMoved", pts$x1, pts$y1)
    mouse_event(session, "mouseReleased", pts$x1, pts$y1)
    Sys.sleep(0.3)
    status <- runtime_point(session, "document.querySelector('.ggwebgl__selection-status').textContent")
    link <- runtime_point(session, "document.querySelector('.ggWebGL').ggwebglLastMagnifierRegion")
    expect_equal(link$source_panel, "global")
    expect_equal(link$target_panel, "local")
    expect_true(diff(unlist(link$region$x)) > 0)
    expect_true(diff(unlist(link$region$y)) > 0)
    expect_match(status, "selected")
  })
})

test_that("browser smoke orbit and trackball controllers update distinct camera state", {
  if (!chromote_available()) {
    skip("A browser session is unavailable for interaction runtime tests.")
  }

  make_camera_widget <- function(controller) {
    points <- data.frame(
      x = c(-0.4, 0, 0.4),
      y = c(0, 0.35, -0.2),
      z = c(-0.3, 0.2, 0.5),
      xend = c(0, 0.35, 0.7),
      yend = c(0.25, 0.1, 0.15),
      zend = c(0.1, 0.45, 0.8),
      id = paste0("v", 1:3)
    )
    ggWebGL(
      ggwebgl_spec(
        list(
          ggwebgl_layer_vectors(
            points,
            x = "x",
            y = "y",
            z = "z",
            xend = "xend",
            yend = "yend",
            zend = "zend",
            id = "id",
            colour = "#0f172a"
          )
        ),
        webgl = list(
          view = ggwebgl_view(
            dimension = "3d",
            projection = "perspective",
            controller = controller,
            state = list(distance = 3)
          ),
          selection = ggwebgl_selection("none"),
          interactions = c("pan", "zoom")
        )
      ),
      height = 360
    )
  }

  run_drag <- function(widget) {
    with_widget_page(widget, function(session) {
      pts <- runtime_point(session, paste(
        "(() => {",
        "const r = document.querySelector('.ggwebgl__stage').getBoundingClientRect();",
        "return {x0:r.left+r.width*0.45,y0:r.top+r.height*0.45,x1:r.left+r.width*0.63,y1:r.top+r.height*0.58};",
        "})()",
        sep = "\n"
      ))
      mouse_event(session, "mousePressed", pts$x0, pts$y0)
      mouse_event(session, "mouseMoved", pts$x1, pts$y1)
      mouse_event(session, "mouseReleased", pts$x1, pts$y1)
      Sys.sleep(0.2)
      runtime_point(session, "(() => { const el = document.querySelector('.ggWebGL'); return {controller: el.ggwebglLastCameraController, state: el.ggwebglLastCameraState}; })()")
    }, width = 620, height = 420)
  }

  orbit <- run_drag(make_camera_widget("orbit"))
  trackball <- run_drag(make_camera_widget("trackball"))
  expect_equal(orbit$controller, "orbit")
  expect_equal(trackball$controller, "trackball")
  expect_false(identical(orbit$state$rotation, trackball$state$rotation))
})

test_that("browser smoke mesh hover reports renderer-owned mesh vertex ids", {
  if (!chromote_available()) {
    skip("A browser session is unavailable for interaction runtime tests.")
  }

  widget <- ggWebGL(
    ggwebgl_spec(
      list(
        ggwebgl_layer_mesh(
          vertices = data.frame(x = c(0, 0.4, -0.4), y = c(0, -0.4, 0.4), z = c(0, 0, 0), id = c("center", "right", "left")),
          x = "x",
          y = "y",
          z = "z",
          id = "id",
          triangles = data.frame(i = 1L, j = 2L, k = 3L),
          material = ggwebgl_material(shading = "lambert", cull = "none"),
          pick_id = "face-main"
        )
      ),
      webgl = list(
        view = ggwebgl_view(dimension = "3d", controller = "trackball"),
        selection = ggwebgl_selection("none"),
        interactions = "hover"
      )
    ),
    height = 360
  )

  with_widget_page(widget, function(session) {
    center <- runtime_point(session, paste(
      "(() => {",
      "const r = document.querySelector('.ggwebgl__stage').getBoundingClientRect();",
      "return {x:r.left+r.width*0.5,y:r.top+r.height*0.5};",
      "})()",
      sep = "\n"
    ))
    session$Input$dispatchMouseEvent(
      type = "mouseMoved",
      x = center$x,
      y = center$y,
      button = "none",
      buttons = 0L
    )
    Sys.sleep(0.2)
    tooltip <- runtime_point(session, "document.querySelector('.ggwebgl__tooltip').textContent")
    expect_match(tooltip, "Mesh vertex")
    expect_match(tooltip, "center")
  }, width = 620, height = 420)
})
