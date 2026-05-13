test_that("htmlwidget output carries the ggWebGL stylesheet dependency", {
  plot <- ggplot2::ggplot(
    data.frame(x = c(0, 1, 2), y = c(2, 1, 0)),
    ggplot2::aes(x, y)
  ) +
    geom_point_webgl() +
    theme_webgl()

  widget <- ggplot_webgl(plot, height = 320)
  output <- tempfile(fileext = ".html")
  libdir <- tempfile()

  htmlwidgets::saveWidget(widget, output, selfcontained = FALSE, libdir = libdir)

  html <- paste(readLines(output, warn = FALSE), collapse = "\n")
  dependencies <- list.files(libdir, recursive = TRUE)

  expect_true(grepl("ggWebGL.css", html, fixed = TRUE))
  expect_true(any(basename(dependencies) == "ggWebGL.css"))
})

test_that("widget JavaScript keeps canvases contained in their local stage", {
  js_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js")
  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }

  expect_true(file.exists(js_path))

  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")

  expect_match(js, "function ensureWidgetLayout\\(")
  expect_match(js, "state\\.root\\.style\\.position = \"relative\"")
  expect_match(js, "state\\.stage\\.style\\.position = \"relative\"")
  expect_match(js, "state\\.stage\\.style\\.overflow = \"hidden\"")
  expect_match(js, "state\\.canvas\\.style\\.position = \"absolute\"")
  expect_match(js, "state\\.canvas\\.style\\.inset = \"0\"")
  expect_match(js, "state\\.canvas\\.style\\.display = \"block\"")
  expect_false(grepl("RESIZE METRICS|CANVAS FINAL SIZE|DRAW SCENE INPUT", js))
})

test_that("timeline controls reserve visible space in compact widgets", {
  js_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.js")
  css_path <- testthat::test_path("..", "..", "inst", "htmlwidgets", "ggWebGL.css")
  if (!file.exists(js_path)) {
    js_path <- system.file("htmlwidgets", "ggWebGL.js", package = "ggWebGL")
  }
  if (!file.exists(css_path)) {
    css_path <- system.file("htmlwidgets", "ggWebGL.css", package = "ggWebGL")
  }

  expect_true(file.exists(js_path))
  expect_true(file.exists(css_path))

  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  css <- paste(readLines(css_path, warn = FALSE), collapse = "\n")

  expect_match(
    js,
    "root\\.appendChild\\(header\\);[[:space:]]+root\\.appendChild\\(timeline\\);[[:space:]]+root\\.appendChild\\(stage\\);",
    perl = TRUE
  )
  expect_match(js, "var STAGE_MIN_DEFAULT = 260;", fixed = TRUE)
  expect_match(js, "var STAGE_MIN_CONTROLS = 300;", fixed = TRUE)
  expect_match(js, "var STAGE_MIN_MULTIPANEL = 320;", fixed = TRUE)
  expect_match(js, "function recalculateWidgetChromeLayout", fixed = TRUE)
  expect_match(js, "ggwebgl--timeline-visible", fixed = TRUE)
  expect_match(js, "ggwebgl--selection-controls-visible", fixed = TRUE)
  expect_match(js, "ggwebgl--selection-status-visible", fixed = TRUE)
  expect_match(js, "requestedHeight", fixed = TRUE)
  expect_match(js, "var layoutHeight = Math.max\\(requestedHeight, requiredHeight\\);")
  expect_match(js, "auto auto auto auto auto auto auto")
  expect_match(js, "state.stage.style.minHeight = publication ? \"0px\" : STAGE_MIN_DEFAULT + \"px\";", fixed = TRUE)
  expect_match(js, "if (state.stage.style.height !== nextHeight)", fixed = TRUE)
  expect_false(grepl("el.style.height = requiredHeight", js, fixed = TRUE))
  expect_false(grepl("function widgetPixelHeight", js, fixed = TRUE))
  expect_false(grepl("state.stage.style.minHeight = publication ? \"0px\" : \"120px\";", js, fixed = TRUE))
  expect_match(css, "grid-template-rows: auto auto auto auto auto auto auto;")
  expect_match(css, "font-size: 0.95rem;", fixed = TRUE)
  expect_match(css, "min-height: 260px;", fixed = TRUE)
  expect_match(css, "min-height: 1.8rem;", fixed = TRUE)
  expect_false(grepl("min-height: 120px;", css, fixed = TRUE))
})

test_that("generated real-data article keeps widget stylesheet and flow heights when present", {
  article <- testthat::test_path("..", "..", "docs", "articles", "real-data-evidence.html")
  if (!file.exists(article)) {
    skip("Generated pkgdown article is not available in this checkout.")
  }

  html <- paste(readLines(article, warn = FALSE), collapse = "\n")
  widget_tags <- regmatches(
    html,
    gregexpr(
      "<div id=\"htmlwidget-[^\"]+\" style=\"[^\"]*\" class=\"ggWebGL html-widget\"></div>",
      html,
      perl = TRUE
    )
  )[[1]]

  expect_true(grepl("ggWebGL.css", html, fixed = TRUE))
  expect_gt(length(widget_tags), 0L)
  expect_true(all(grepl("height:[0-9]+px", widget_tags)))
})

test_that("browser layout keeps each canvas inside its widget stage", {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    skip("chromote is not installed.")
  }

  browser_ok <- tryCatch({
    browser <- chromote::Chromote$new()
    on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
    session <- browser$new_session(width = 640, height = 420, wait_ = TRUE)
    try(session$close(), silent = TRUE)
    TRUE
  }, error = function(e) FALSE)

  if (!browser_ok) {
    skip("A browser session is unavailable for widget layout tests.")
  }

  plot <- ggplot2::ggplot(
    data.frame(x = c(0, 1, 2), y = c(2, 1, 0)),
    ggplot2::aes(x, y)
  ) +
    geom_point_webgl() +
    theme_webgl()

  output <- tempfile(fileext = ".html")
  libdir <- tempfile()
  htmlwidgets::saveWidget(
    ggplot_webgl(plot, height = 320),
    output,
    selfcontained = FALSE,
    libdir = libdir
  )

  browser <- chromote::Chromote$new()
  on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
  session <- browser$new_session(width = 800, height = 600, wait_ = TRUE)
  on.exit(try(session$close(), silent = TRUE), add = TRUE)

  session$Page$navigate(paste0("file://", normalizePath(output)), wait_ = TRUE)
  wait_for_widget_ready(session, timeout_seconds = 5, settle_seconds = 0.35)

  result <- session$Runtime$evaluate(
    paste(
      "(() => {",
      "const hosts = Array.from(document.querySelectorAll('.ggWebGL.html-widget'));",
      "const details = hosts.map((host) => {",
      "const stage = host.querySelector('.ggwebgl__stage');",
      "const canvas = host.querySelector('canvas');",
      "const stageRect = stage && stage.getBoundingClientRect();",
      "const canvasRect = canvas && canvas.getBoundingClientRect();",
      "return {",
      "stagePosition: stage ? getComputedStyle(stage).position : null,",
      "stageOverflow: stage ? getComputedStyle(stage).overflow : null,",
      "canvasPosition: canvas ? getComputedStyle(canvas).position : null,",
      "offsetParent: canvas && canvas.offsetParent ? String(canvas.offsetParent.className) : null,",
      "contained: !!(stageRect && canvasRect) &&",
      "canvasRect.top >= stageRect.top && canvasRect.left >= stageRect.left &&",
      "canvasRect.bottom <= stageRect.bottom + 1 && canvasRect.right <= stageRect.right + 1",
      "};",
      "});",
      "return {count: hosts.length, ok: details.length > 0 && details.every((x) =>",
      "x.stagePosition === 'relative' && x.stageOverflow === 'hidden' &&",
      "x.canvasPosition === 'absolute' && x.offsetParent.indexOf('ggwebgl__stage') !== -1 && x.contained), details};",
      "})()",
      sep = "\n"
    ),
    returnByValue = TRUE
  )$result$value

  expect_gt(result$count, 0L)
  expect_true(result$ok, info = paste(utils::capture.output(str(result$details)), collapse = "\n"))
})

test_that("browser layout keeps stage below chrome and stable after interactions", {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    skip("chromote is not installed.")
  }

  browser_ok <- tryCatch({
    browser <- chromote::Chromote$new()
    on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
    session <- browser$new_session(width = 640, height = 420, wait_ = TRUE)
    try(session$close(), silent = TRUE)
    TRUE
  }, error = function(e) FALSE)

  if (!browser_ok) {
    skip("A browser session is unavailable for widget layout tests.")
  }

  browser <- chromote::Chromote$new()
  on.exit(try(browser$close(wait = TRUE), silent = TRUE), add = TRUE)
  session <- browser$new_session(width = 960, height = 760, wait_ = TRUE)
  on.exit(try(session$close(), silent = TRUE), add = TRUE)

  open_widget <- function(widget) {
    output <- tempfile(fileext = ".html")
    libdir <- tempfile()
    htmlwidgets::saveWidget(widget, output, selfcontained = FALSE, libdir = libdir)
    session$Page$navigate(paste0("file://", normalizePath(output)), wait_ = TRUE)
    wait_for_widget_ready(session, timeout_seconds = 5, settle_seconds = 0.35)
  }

  probe <- function() {
    session$Runtime$evaluate(
      paste(
        "(() => {",
        "const root = document.querySelector('.ggWebGL.html-widget .ggwebgl');",
        "const stage = root && root.querySelector('.ggwebgl__stage');",
        "const header = root && root.querySelector('.ggwebgl__header');",
        "const timeline = root && root.querySelector('.ggwebgl__timeline');",
        "const controls = root && root.querySelector('.ggwebgl__selection-controls');",
        "const status = root && root.querySelector('.ggwebgl__selection-status');",
        "const axes = root && root.querySelector('.ggwebgl__axes');",
        "const notes = root && root.querySelector('.ggwebgl__notes');",
        "function shown(node) { return !!node && getComputedStyle(node).display !== 'none'; }",
        "function rect(node) { return node ? node.getBoundingClientRect() : { top: 0, bottom: 0, height: 0 }; }",
        "const stageRect = rect(stage);",
        "const chrome = [header, timeline, controls, status, axes, notes].filter(shown).map(rect);",
        "const maxChromeBottom = chrome.length ? Math.max.apply(null, chrome.map((x) => x.bottom)) : 0;",
        "return {",
        "stageHeight: stageRect.height,",
        "stageTop: stageRect.top,",
        "headerBottom: rect(header).bottom,",
        "timelineVisible: shown(timeline),",
        "controlsVisible: shown(controls),",
        "statusVisible: shown(status),",
        "stageBelowHeader: stageRect.top >= rect(header).bottom - 1,",
        "stageNotOverChrome: stageRect.top < maxChromeBottom ? stageRect.bottom <= Math.min.apply(null, chrome.map((x) => x.top)) + 1 : true",
        "};",
        "})()",
        sep = "\n"
      ),
      returnByValue = TRUE
    )$result$value
  }

  click_stage <- function() {
    session$Runtime$evaluate(
      paste(
        "(() => {",
        "const stage = document.querySelector('.ggwebgl__stage');",
        "const r = stage.getBoundingClientRect();",
        "stage.dispatchEvent(new MouseEvent('click', {",
        "clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, bubbles: true",
        "}));",
        "return true;",
        "})()",
        sep = "\n"
      ),
      returnByValue = TRUE
    )
    Sys.sleep(0.2)
  }

  tiny <- data.frame(x = c(0, 1, 2), y = c(2, 1, 0))
  normal <- ggplot_webgl(
    ggplot2::ggplot(tiny, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      theme_webgl(interactions = c("pan", "zoom", "hover")),
    height = 360
  )
  open_widget(normal)
  before <- probe()
  click_stage()
  after <- probe()
  expect_true(before$stageBelowHeader)
  expect_gte(before$stageHeight, 260)
  expect_equal(after$stageHeight, before$stageHeight, tolerance = 1)

  timeline_data <- data.frame(
    x = rep(1:4, 3),
    y = rep(c(1, 2, 1), each = 4),
    frame = rep(1:3, each = 4)
  )
  timeline <- ggplot_webgl(
    ggplot2::ggplot(timeline_data, ggplot2::aes(x, y, frame = frame)) +
      geom_point_webgl() +
      theme_webgl(timeline = ggwebgl_timeline(frames = 1:3, controls = TRUE)),
    height = 360
  )
  open_widget(timeline)
  before <- probe()
  session$Runtime$evaluate(
    "const s = document.querySelector('.ggwebgl__timeline-scrub'); s.value = '1'; s.dispatchEvent(new Event('input', { bubbles: true })); true",
    returnByValue = TRUE
  )
  Sys.sleep(0.2)
  after <- probe()
  expect_true(before$timelineVisible)
  expect_true(before$stageBelowHeader)
  expect_gte(before$stageHeight, 300)
  expect_equal(after$stageHeight, before$stageHeight, tolerance = 1)

  brush_only <- ggplot_webgl(
    ggplot2::ggplot(tiny, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      theme_webgl(interactions_spec = ggwebgl_interactions(brush = TRUE, lasso = FALSE)),
    height = 360
  )
  open_widget(brush_only)
  before <- probe()
  click_stage()
  after <- probe()
  expect_false(before$controlsVisible)
  expect_true(before$statusVisible)
  expect_gte(before$stageHeight, 300)
  expect_equal(after$stageHeight, before$stageHeight, tolerance = 1)

  brush_lasso <- ggplot_webgl(
    ggplot2::ggplot(tiny, ggplot2::aes(x, y)) +
      geom_point_webgl() +
      theme_webgl(interactions_spec = ggwebgl_interactions(brush = TRUE, lasso = TRUE)),
    height = 380
  )
  open_widget(brush_lasso)
  before <- probe()
  session$Runtime$evaluate("document.querySelector('[data-mode=\"lasso\"]').click(); true", returnByValue = TRUE)
  Sys.sleep(0.2)
  after <- probe()
  expect_true(before$controlsVisible)
  expect_true(before$statusVisible)
  expect_gte(before$stageHeight, 300)
  expect_equal(after$stageHeight, before$stageHeight, tolerance = 1)

  zoom_data <- data.frame(
    x = c(-2, -1.5, -1, 1, 1.5, 2),
    y = c(0, 0.2, -0.1, 0.8, 1, 0.9)
  )
  source <- ggwebgl_spec(
    list(ggwebgl_layer_points(zoom_data, x = "x", y = "y", colour = "#2563eb")),
    webgl = list(interactions_spec = ggwebgl_interactions(brush = TRUE))
  )
  linked <- ggWebGL(
    ggwebgl_magnify_region(
      source,
      region = list(x = c(0.8, 2.1), y = c(0.7, 1.1)),
      display = "panel",
      interactive = TRUE
    ),
    height = 430
  )
  open_widget(linked)
  before <- probe()
  click_stage()
  after <- probe()
  expect_true(before$stageBelowHeader)
  expect_gte(before$stageHeight, 320)
  expect_equal(after$stageHeight, before$stageHeight, tolerance = 1)
})
