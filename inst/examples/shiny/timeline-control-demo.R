locate_temporal_trajectory_examples <- function() {
  candidates <- c(
    system.file("examples", "htmlwidget", "temporal-trajectories.R", package = "ggWebGL"),
    file.path("inst", "examples", "htmlwidget", "temporal-trajectories.R"),
    file.path("..", "htmlwidget", "temporal-trajectories.R")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) {
    stop("Could not find temporal-trajectories.R.", call. = FALSE)
  }

  candidates[[1L]]
}

timeline_control_demo_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required for the timeline control demo.", call. = FALSE)
  }

  source(locate_temporal_trajectory_examples(), local = TRUE)

  shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::tags$h3("ggWebGL timeline control demo"),
      shiny::fluidRow(
        shiny::column(
          width = 8,
          ggWebGL::ggWebGLOutput("trajectory", height = "420px")
        ),
        shiny::column(
          width = 4,
          shiny::actionButton("restart", "Reset"),
          shiny::actionButton("play_from_middle", "Play from middle"),
          shiny::tags$hr(),
          shiny::verbatimTextOutput("timeline_state")
        )
      )
    ),
    server = function(input, output, session) {
      output$trajectory <- ggWebGL::renderGgWebGL({
        temporal_helix_widget(height = 420)
      })

      shiny::observeEvent(input$restart, {
        ggWebGL::updateGgWebGLTimeline(
          session,
          "trajectory",
          index = 1L,
          playing = FALSE
        )
      })

      shiny::observeEvent(input$play_from_middle, {
        ggWebGL::updateGgWebGLTimeline(
          session,
          "trajectory",
          index = 60L,
          playing = TRUE,
          speed = 1.2
        )
      })

      output$timeline_state <- shiny::renderPrint({
        input$trajectory_timeline
      })
    }
  )
}

if (interactive()) {
  shiny::runApp(timeline_control_demo_app())
}
