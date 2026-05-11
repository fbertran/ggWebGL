interaction_demo_widget <- function() {
  t <- seq(0, 2 * pi, length.out = 90)
  points <- data.frame(
    x = cos(t) * seq(0.25, 1, length.out = length(t)),
    y = sin(t) * seq(0.25, 1, length.out = length(t)),
    z = seq(-0.35, 0.35, length.out = length(t)),
    frame = rep(1:3, length.out = length(t)),
    id = paste0("p", seq_along(t)),
    label = paste("sample", seq_along(t))
  )
  surface <- outer(seq(-1, 1, length.out = 9), seq(-1, 1, length.out = 9), function(x, y) {
    0.25 * cos(pi * x) * sin(pi * y)
  })

  spec <- ggWebGL::ggwebgl_spec(
    layers = list(
      ggWebGL::ggwebgl_layer_points(
        points,
        x = "x",
        y = "y",
        z = "z",
        colour = "#2563eb",
        alpha = 0.68,
        size = 4,
        id = "id",
        label = "label",
        frame = "frame"
      ),
      ggWebGL::ggwebgl_layer_surface(
        surface,
        x = seq(-1, 1, length.out = 9),
        y = seq(-1, 1, length.out = 9),
        shading = "surface_lambert",
        wireframe = TRUE,
        alpha = 0.55,
        pick_id = paste0("face", seq_len((9 - 1) * (9 - 1) * 2))
      )
    ),
    webgl = list(
      view = ggWebGL::ggwebgl_view(dimension = "3d", projection = "perspective", controller = "orbit"),
      interactions_spec = ggWebGL::ggwebgl_interactions(brush = TRUE, lasso = TRUE),
      timeline = ggWebGL::ggwebgl_timeline(frames = 1:3, filter = "exact", autoplay = FALSE)
    )
  )

  ggWebGL::ggWebGL(spec, height = 520)
}

interaction_demo_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required for the interaction demo.", call. = FALSE)
  }

  shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::tags$h3("ggWebGL interaction demo"),
      shiny::fluidRow(
        shiny::column(8, ggWebGL::ggWebGLOutput("scene", height = "560px")),
        shiny::column(
          4,
          shiny::tags$p("Events are emitted by ggWebGL; no custom JavaScript is needed."),
          shiny::tags$h4("Hover"),
          shiny::verbatimTextOutput("hover"),
          shiny::tags$h4("Selection / Brush"),
          shiny::verbatimTextOutput("selection"),
          shiny::tags$h4("Camera"),
          shiny::verbatimTextOutput("camera"),
          shiny::tags$h4("Time"),
          shiny::verbatimTextOutput("time")
        )
      )
    ),
    server = function(input, output, session) {
      output$scene <- ggWebGL::renderGgWebGL({
        interaction_demo_widget()
      })

      output$hover <- shiny::renderPrint(input$scene_hover)
      output$selection <- shiny::renderPrint(list(selection = input$scene_selection, brush = input$scene_brush))
      output$camera <- shiny::renderPrint(input$scene_camera)
      output$time <- shiny::renderPrint(input$scene_time)
    }
  )
}

if (interactive()) {
  shiny::runApp(interaction_demo_app())
}
