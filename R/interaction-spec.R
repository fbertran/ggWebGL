#' Define ggWebGL Runtime Interactions
#'
#' Build a structured interaction specification for widget-owned hover, click,
#' brush/lasso, camera, and Shiny event behavior. Existing character
#' `interactions` vectors remain supported; this helper is the normalized
#' contract for new code.
#'
#' @param hover Enable hover picking and tooltip/event emission.
#' @param click Enable click picking and event emission.
#' @param brush Enable rectangular brush selection.
#' @param lasso Enable lasso selection.
#' @param camera Enable camera-state event emission for 3D interactions.
#' @param shiny Enable Shiny event emission when a Shiny runtime is present.
#'
#' @return A `ggwebgl_interactions` list.
#'
#' @examples
#' ggwebgl_interactions(brush = TRUE)
#' @export
ggwebgl_interactions <- function(hover = TRUE,
                                 click = TRUE,
                                 brush = FALSE,
                                 lasso = FALSE,
                                 camera = TRUE,
                                 shiny = TRUE) {
  out <- list(
    hover = isTRUE(hover),
    click = isTRUE(click),
    brush = isTRUE(brush),
    lasso = isTRUE(lasso),
    camera = isTRUE(camera),
    shiny = isTRUE(shiny)
  )
  out$modes <- ggwebgl_interaction_modes(out)
  class(out) <- c("ggwebgl_interactions", "list")
  out
}

ggwebgl_interaction_modes <- function(spec) {
  modes <- character()
  if (isTRUE(spec$hover)) {
    modes <- c(modes, "hover")
  }
  if (isTRUE(spec$click)) {
    modes <- c(modes, "click")
  }
  if (isTRUE(spec$brush)) {
    modes <- c(modes, "brush")
  }
  if (isTRUE(spec$lasso)) {
    modes <- c(modes, "lasso")
  }
  if (isTRUE(spec$camera)) {
    modes <- c(modes, "camera")
  }
  unique(modes)
}

normalise_interactions_spec <- function(interactions_spec = NULL,
                                        interactions = character(),
                                        selection = NULL,
                                        view = NULL) {
  if (inherits(interactions_spec, "ggwebgl_interactions")) {
    interactions_spec <- unclass(interactions_spec)
  }

  interactions <- unique(as.character(interactions %||% character()))
  selection_mode <- selection$mode %||% selection_mode_from_interactions(interactions)
  selection_brush <- selection_mode %in% c("brush", "brush_lasso")
  selection_lasso <- selection_mode %in% c("lasso", "brush_lasso")

  if (is.null(interactions_spec)) {
    out <- list(
      hover = "hover" %in% interactions,
      click = any(c("click", "select") %in% interactions),
      brush = "brush" %in% interactions || selection_brush,
      lasso = "lasso" %in% interactions || selection_lasso,
      camera = "camera" %in% interactions || identical(view$dimension %||% "2d", "3d"),
      shiny = TRUE
    )
  } else {
    if (!is.list(interactions_spec)) {
      rlang::abort("`interactions_spec` must be created by `ggwebgl_interactions()` or be a list.")
    }
    out <- list(
      hover = isTRUE(interactions_spec$hover),
      click = isTRUE(interactions_spec$click),
      brush = isTRUE(interactions_spec$brush) || selection_brush,
      lasso = isTRUE(interactions_spec$lasso) || selection_lasso,
      camera = isTRUE(interactions_spec$camera),
      shiny = isTRUE(interactions_spec$shiny %||% TRUE)
    )
  }

  out$modes <- ggwebgl_interaction_modes(out)
  class(out) <- c("ggwebgl_interactions", "list")
  out
}
