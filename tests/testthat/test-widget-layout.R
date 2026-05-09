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
  expect_match(js, "auto auto minmax\\(0, 1fr\\) auto auto auto")
  expect_match(js, "state.stage.style.minHeight = publication ? \"0px\" : \"120px\";", fixed = TRUE)
  expect_match(css, "grid-template-rows: auto auto minmax\\(0, 1fr\\) auto auto auto;")
  expect_match(css, "font-size: 0.95rem;", fixed = TRUE)
  expect_match(css, "min-height: 120px;", fixed = TRUE)
  expect_match(css, "min-height: 1.8rem;", fixed = TRUE)
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
  try(session$Page$loadEventFired(wait_ = TRUE), silent = TRUE)
  Sys.sleep(0.5)

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
