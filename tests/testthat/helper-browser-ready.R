wait_for_widget_ready <- function(session, timeout_seconds = 5, settle_seconds = 0.2) {
  deadline <- Sys.time() + timeout_seconds
  last <- NULL
  script <- paste(
    "(() => {",
    "const readyState = document.readyState;",
    "const roots = Array.from(document.querySelectorAll('.ggWebGL'));",
    "const hasCanvas = roots.some((root) => !!root.querySelector('.ggwebgl__stage canvas'));",
    "const renderReady = typeof window.__render_ready === 'undefined' ? null : window.__render_ready;",
    "return {",
    "readyState: readyState,",
    "rootCount: roots.length,",
    "hasCanvas: hasCanvas,",
    "renderReady: renderReady,",
    "ready: (readyState === 'interactive' || readyState === 'complete') && roots.length > 0 && hasCanvas",
    "};",
    "})()",
    sep = "\n"
  )

  while (Sys.time() < deadline) {
    last <- tryCatch(
      session$Runtime$evaluate(script, returnByValue = TRUE)$result$value,
      error = function(e) list(error = conditionMessage(e), ready = FALSE)
    )
    if (isTRUE(last$ready)) {
      if (settle_seconds > 0) {
        Sys.sleep(settle_seconds)
      }
      return(invisible(last))
    }
    Sys.sleep(0.05)
  }

  testthat::fail(paste(
    "Timed out waiting for ggWebGL widget readiness:",
    paste(utils::capture.output(str(last)), collapse = "\n")
  ))
}
