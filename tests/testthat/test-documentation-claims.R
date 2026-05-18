claim_gate_repo_file <- function(...) {
  candidates <- c(
    file.path(getwd(), ...),
    testthat::test_path("..", "..", ...)
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    return(NA_character_)
  }
  found[[1L]]
}

claim_gate_read_text <- function(path) {
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

claim_gate_public_source_files <- function() {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE)
  explicit <- file.path(root, c("README.Rmd", "README.md", "DESCRIPTION", "NEWS.md", "inst/_pkgdown.yml"))
  vignettes <- list.files(file.path(root, "vignettes"), pattern = "\\.Rmd$", full.names = TRUE)
  unique(c(explicit[file.exists(explicit)], vignettes))
}

claim_gate_generated_doc_files <- function() {
  docs <- claim_gate_repo_file("docs")
  if (is.na(docs)) {
    return(character())
  }
  files <- list.files(docs, recursive = TRUE, full.names = TRUE)
  files <- files[grepl("\\.(html|md|yml|xml|json)$", files)]
  files <- files[!grepl("(^|/)(deps|.*_files)(/|$)", files)]
  files
}

claim_gate_forbidden_terms <- function() {
  c(
    "SIGGRAPH",
    "poster",
    "submission",
    "claim-to-evidence",
    "siggraph_figures",
    "final_selection",
    "reviewer-safe",
    "claims audit"
  )
}

test_that("README support matrix tracks exported experimental APIs", {
  namespace <- claim_gate_repo_file("NAMESPACE")
  readme <- claim_gate_repo_file("README.Rmd")
  if (is.na(namespace) || is.na(readme)) {
    skip("NAMESPACE or README.Rmd is unavailable in this test context.")
  }

  namespace_text <- claim_gate_read_text(namespace)
  readme_text <- claim_gate_read_text(readme)
  exports <- sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", strsplit(namespace_text, "\n")[[1L]], value = TRUE))

  required_exports <- c(
    "geom_path3d_webgl",
    "animation_spec",
    "scale_time_webgl",
    "updateGgWebGLTimeline",
    "as_mesh_webgl",
    "ggwebgl_mesh",
    "coord_webgl_3d",
    "ggwebgl_interactions",
    "ggwebgl_transport"
  )

  expect_true(all(required_exports %in% exports))
  for (api in required_exports) {
    expect_match(readme_text, paste0("`", api, "\\(\\)`"))
  }
  for (status in c("Stable", "Experimental", "Optional extension", "Metadata-only", "Deferred")) {
    expect_match(readme_text, status, fixed = TRUE)
  }
  expect_match(readme_text, "Public API | Status | Evidence | Notes", fixed = TRUE)
  expect_false(grepl("CRAN core vs SIGGRAPH demo extensions", readme_text, fixed = TRUE))
  expect_false(grepl("API.md", readme_text, fixed = TRUE))
})

test_that("public documentation avoids private submission-specific wording", {
  files <- claim_gate_public_source_files()
  expect_gt(length(files), 0L)
  pattern <- paste(claim_gate_forbidden_terms(), collapse = "|")

  for (file in files) {
    text <- claim_gate_read_text(file)
    expect_false(grepl(pattern, text, ignore.case = TRUE), info = file)
  }
})

test_that("generated public docs avoid private submission-specific wording when scanned", {
  files <- claim_gate_generated_doc_files()
  if (!length(files)) {
    skip("Generated docs are unavailable in this checkout.")
  }
  pattern <- paste(claim_gate_forbidden_terms(), collapse = "|")

  for (file in files) {
    text <- claim_gate_read_text(file)
    expect_false(grepl(pattern, text, ignore.case = TRUE), info = file)
  }
})
