library(htmlwidgets)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

helper_path <- if (file.exists("inst/examples/showcase/showcase-helpers.R")) {
  "inst/examples/showcase/showcase-helpers.R"
} else {
  system.file("examples", "showcase", "showcase-helpers.R", package = "ggWebGL")
}

source(helper_path, local = TRUE)

html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  gsub("'", "&#39;", x, fixed = TRUE)
}

write_renderer_showcase_index <- function(output_dir, files, detail) {
  metadata <- showcase_metadata()
  items <- vapply(names(files), function(name) {
    info <- metadata[[name]]
    href <- basename(files[[name]])

    paste0(
      "<a class=\"gallery-card\" href=\"", html_escape(href), "\">",
      "<span class=\"gallery-card__name\">", html_escape(info$title), "</span>",
      "<span class=\"gallery-card__subtitle\">", html_escape(info$subtitle), "</span>",
      "<span class=\"gallery-card__hint\">", html_escape(info$reading_hint), "</span>",
      "</a>"
    )
  }, character(1))

  lines <- c(
    "<!DOCTYPE html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>ggWebGL Showcase Gallery</title>",
    "  <style>",
    "    :root { color-scheme: light; }",
    "    body {",
    "      margin: 0;",
    "      font-family: \"Source Sans 3\", \"Helvetica Neue\", sans-serif;",
    "      color: #102a43;",
    "      background: linear-gradient(180deg, #f3f7fb, #eef3f8);",
    "    }",
    "    .page {",
    "      max-width: 1080px;",
    "      margin: 0 auto;",
    "      padding: 2.5rem 1.5rem 3rem;",
    "    }",
    "    .eyebrow {",
    "      margin: 0 0 0.8rem;",
    "      font-size: 0.84rem;",
    "      font-weight: 700;",
    "      letter-spacing: 0.08em;",
    "      text-transform: uppercase;",
    "      color: #486581;",
    "    }",
    "    h1 {",
    "      margin: 0 0 0.7rem;",
    "      font-family: \"Space Grotesk\", \"Helvetica Neue\", sans-serif;",
    "      font-size: clamp(2rem, 4vw, 3.2rem);",
    "      line-height: 1.05;",
    "    }",
    "    .summary {",
    "      max-width: 58rem;",
    "      margin: 0 0 1.4rem;",
    "      font-size: 1.1rem;",
    "      line-height: 1.5;",
    "      color: #334e68;",
    "    }",
    "    .pill {",
    "      display: inline-block;",
    "      margin-bottom: 1.6rem;",
    "      padding: 0.42rem 0.8rem;",
    "      border-radius: 999px;",
    "      background: #d9e7f5;",
    "      color: #1f3f5b;",
    "      font-size: 0.95rem;",
    "      font-weight: 600;",
    "    }",
    "    .grid {",
    "      display: grid;",
    "      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));",
    "      gap: 1rem;",
    "    }",
    "    .gallery-card {",
    "      display: flex;",
    "      flex-direction: column;",
    "      gap: 0.55rem;",
    "      min-height: 12rem;",
    "      padding: 1.2rem 1.1rem;",
    "      border: 1px solid #c9d6e3;",
    "      border-radius: 1rem;",
    "      text-decoration: none;",
    "      background: linear-gradient(180deg, rgba(255,255,255,0.95), rgba(236,243,249,0.98));",
    "      box-shadow: 0 10px 30px rgba(15, 35, 55, 0.08);",
    "      color: inherit;",
    "    }",
    "    .gallery-card:hover {",
    "      border-color: #93b7da;",
    "      transform: translateY(-1px);",
    "      box-shadow: 0 14px 32px rgba(15, 35, 55, 0.12);",
    "    }",
    "    .gallery-card__name {",
    "      font-family: \"Space Grotesk\", \"Helvetica Neue\", sans-serif;",
    "      font-size: 1.25rem;",
    "      font-weight: 700;",
    "      color: #102a43;",
    "    }",
    "    .gallery-card__subtitle {",
    "      font-size: 1rem;",
    "      line-height: 1.4;",
    "      color: #486581;",
    "    }",
    "    .gallery-card__hint {",
    "      margin-top: auto;",
    "      font-size: 0.95rem;",
    "      line-height: 1.45;",
    "      color: #334e68;",
    "    }",
    "  </style>",
    "</head>",
    "<body>",
    "  <main class=\"page\">",
    "    <p class=\"eyebrow\">ggWebGL Showcase Gallery</p>",
    "    <h1>Renderer Showcase Exports</h1>",
    "    <p class=\"summary\">This landing page links the standalone HTML widgets created by <code>export_renderer_showcase_gallery()</code>. Each card opens one exported scene.</p>",
    "    <div class=\"pill\">Detail preset: " %+% html_escape(detail) %+% "</div>",
    "    <section class=\"grid\">",
    paste0("      ", items),
    "    </section>",
    "  </main>",
    "</body>",
    "</html>"
  )

  index_path <- file.path(output_dir, "index.html")
  writeLines(lines, con = index_path, useBytes = TRUE)
  index_path
}

`%+%` <- function(x, y) paste0(x, y)

export_renderer_showcase_gallery <- function(output_dir = tempfile("ggwebgl-showcase-"),
                                             selfcontained = FALSE,
                                             detail = c("high_detail", "standard")) {
  detail <- match_showcase_detail(detail)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  plots <- showcase_plots(detail = detail)
  written <- character(length(plots))
  names(written) <- names(plots)

  for (name in names(plots)) {
    file <- file.path(output_dir, paste0(name, ".html"))
    widget <- ggplot_webgl(plots[[name]], width = "100%", height = 520)
    htmlwidgets::saveWidget(widget, file = file, selfcontained = selfcontained)
    written[[name]] <- file
  }

  index_path <- write_renderer_showcase_index(output_dir = output_dir, files = written, detail = detail)
  attr(written, "index") <- index_path

  message("Renderer showcase gallery (", detail, ") written to: ", output_dir)
  invisible(written)
}
