ggwebgl_test_repo_roots <- function() {
  unique(normalizePath(
    c(
      getwd(),
      file.path(testthat::test_path(), "..", "..")
    ),
    winslash = "/",
    mustWork = FALSE
  ))
}

ggwebgl_test_installed_path <- function(path) {
  rel <- gsub("\\\\", "/", path)
  if (startsWith(rel, "inst/")) {
    rel <- sub("^inst/", "", rel)
  } else if (startsWith(rel, "vignettes/")) {
    rel <- file.path("doc", basename(rel))
  }

  parts <- strsplit(rel, "/", fixed = TRUE)[[1L]]
  found <- do.call(system.file, c(as.list(parts), list(package = "ggWebGL")))
  if (nzchar(found) && file.exists(found)) {
    return(normalizePath(found, winslash = "/", mustWork = FALSE))
  }

  NA_character_
}

ggwebgl_test_file_path <- function(..., required = TRUE) {
  path <- file.path(...)
  source_candidates <- file.path(ggwebgl_test_repo_roots(), path)
  candidates <- unique(c(
    normalizePath(source_candidates, winslash = "/", mustWork = FALSE),
    ggwebgl_test_installed_path(path)
  ))
  found <- candidates[!is.na(candidates) & file.exists(candidates)]

  if (!length(found)) {
    if (isTRUE(required)) {
      testthat::skip(sprintf("%s is unavailable in this test context.", path))
    }
    return(NA_character_)
  }

  found[[1L]]
}

ggwebgl_test_read_text <- function(..., required = TRUE) {
  path <- ggwebgl_test_file_path(..., required = required)
  if (is.na(path)) {
    return("")
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

