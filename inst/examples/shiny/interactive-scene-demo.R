interactive_scene_demo_source <- function(file) {
  installed <- system.file("examples", "htmlwidget", file, package = "ggWebGL")
  candidates <- c(installed, file.path("inst", "examples", "htmlwidget", file))
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates) == 0L) {
    stop("Cannot find demo helper script: ", file, call. = FALSE)
  }
  sys.source(candidates[[1L]], envir = parent.frame())
}

interactive_scene_demo_widget <- function(scene = c("embedding", "trajectory", "surface", "mesh"),
                                          height = 560) {
  scene <- match.arg(scene)
  if (identical(scene, "embedding")) {
    interactive_scene_demo_source("million-point-embedding.R")
    return(embedding_widget(
      point_count = 25000L,
      height = height,
      brush = TRUE,
      transport_threshold = 5000L
    ))
  }
  if (identical(scene, "trajectory")) {
    interactive_scene_demo_source("temporal-trajectories.R")
    return(temporal_velocity_widget(height = height))
  }
  if (identical(scene, "surface")) {
    interactive_scene_demo_source("surface-gallery.R")
    return(surface_gallery_volcano_widget(height = height))
  }

  interactive_scene_demo_source("surface-gallery.R")
  surface_gallery_mesh_widget(height = height)
}

interactive_scene_demo_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required for the interactive scene demo.", call. = FALSE)
  }

  shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::tags$h3("ggWebGL interactive scene demo"),
      shiny::tags$p(
        "Choose a compact scene. Hover, selection, camera, and timeline events ",
        "are emitted by ggWebGL without custom JavaScript."
      ),
      shiny::fluidRow(
        shiny::column(
          8,
          shiny::selectInput(
            "scene_kind",
            "Scene",
            choices = c(
              "Dense embedding" = "embedding",
              "Trajectory timeline" = "trajectory",
              "Surface" = "surface",
              "Mesh" = "mesh"
            ),
            selected = "embedding"
          ),
          ggWebGL::ggWebGLOutput("scene", height = "600px")
        ),
        shiny::column(
          4,
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
        interactive_scene_demo_widget(input$scene_kind)
      })

      output$hover <- shiny::renderPrint(input$scene_hover)
      output$selection <- shiny::renderPrint(list(selection = input$scene_selection, brush = input$scene_brush))
      output$camera <- shiny::renderPrint(input$scene_camera)
      output$time <- shiny::renderPrint(list(time = input$scene_time, timeline = input$scene_timeline))
    }
  )
}

if (interactive()) {
  shiny::runApp(interactive_scene_demo_app())
}
