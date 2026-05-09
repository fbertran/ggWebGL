#' Update a ggWebGL Timeline from Shiny
#'
#' Send a timeline update message to a rendered ggWebGL widget. The browser
#' applies the update to the widget identified by `outputId` and emits the
#' updated state back as `input$<outputId>_timeline`.
#'
#' @param session A Shiny session object.
#' @param outputId Output id passed to [ggWebGLOutput()]. Inside Shiny modules,
#'   pass the un-namespaced id; `session$ns()` is applied by this helper.
#' @param value Optional frame or time value to select.
#' @param index Optional 1-based timeline index to select. Exactly one of
#'   `value` or `index` may be supplied.
#' @param playing Optional logical scalar controlling playback.
#' @param speed Optional positive playback-speed multiplier.
#' @param loop Optional logical scalar controlling loop playback.
#'
#' @return `NULL`, invisibly.
#'
#' @examplesIf interactive() && requireNamespace("shiny", quietly = TRUE)
#' server <- function(input, output, session) {
#'   shiny::observeEvent(input$next_frame, {
#'     updateGgWebGLTimeline(session, "plot", index = 2)
#'   })
#' }
#' @export
updateGgWebGLTimeline <- function(session,
                                  outputId,
                                  value = NULL,
                                  index = NULL,
                                  playing = NULL,
                                  speed = NULL,
                                  loop = NULL) {
  if (!is.function(session$sendCustomMessage)) {
    rlang::abort("`session` must provide a `sendCustomMessage()` method.")
  }

  if (missing(outputId) || is.null(outputId) || length(outputId) != 1L) {
    rlang::abort("`outputId` must be a non-empty character scalar.")
  }
  outputId <- as.character(outputId)
  if (!nzchar(outputId)) {
    rlang::abort("`outputId` must be a non-empty character scalar.")
  }

  has_value <- !is.null(value)
  has_index <- !is.null(index)
  if (has_value && has_index) {
    rlang::abort("Supply exactly one of `value` or `index`, not both.")
  }

  if (has_value) {
    if (length(value) != 1L || !(is.numeric(value) || is.character(value))) {
      rlang::abort("`value` must be a numeric or character scalar.")
    }
    value <- unname(value)
  }

  if (has_index) {
    if (length(index) != 1L || !is.numeric(index) || !is.finite(index) || index < 1 || index != floor(index)) {
      rlang::abort("`index` must be a positive integer scalar.")
    }
    index <- as.integer(index)
  }

  if (!is.null(speed)) {
    if (length(speed) != 1L || !is.numeric(speed) || !is.finite(speed) || speed <= 0) {
      rlang::abort("`speed` must be a positive finite numeric scalar.")
    }
    speed <- as.numeric(speed)
  }

  if (!is.null(playing)) {
    if (length(playing) != 1L || !is.logical(playing) || is.na(playing)) {
      rlang::abort("`playing` must be a non-missing logical scalar.")
    }
    playing <- isTRUE(playing)
  }

  if (!is.null(loop)) {
    if (length(loop) != 1L || !is.logical(loop) || is.na(loop)) {
      rlang::abort("`loop` must be a non-missing logical scalar.")
    }
    loop <- isTRUE(loop)
  }

  id <- if (is.function(session$ns)) session$ns(outputId) else outputId
  message <- compact_list(list(
    id = id,
    outputId = id,
    value = value,
    index = index,
    playing = playing,
    speed = speed,
    loop = loop
  ))

  session$sendCustomMessage("ggWebGL:updateTimeline", message)
  invisible(NULL)
}
