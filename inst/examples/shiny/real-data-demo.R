library(shiny)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

helper_path <- if (file.exists("inst/examples/real/real-data-helpers.R")) {
  "inst/examples/real/real-data-helpers.R"
} else {
  system.file("examples", "real", "real-data-helpers.R", package = "ggWebGL")
}

source(helper_path, local = TRUE)

metadata <- real_data_metadata()

ui <- fluidPage(
  titlePanel("ggWebGL Real-Data Demo"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "scenario",
        label = "Scenario",
        choices = setNames(names(metadata), vapply(metadata, `[[`, character(1), "title")),
        selected = "volcano_dem"
      ),
      checkboxInput("show_reference", "Show ggplot2 reference panel", value = TRUE),
      helpText("This demo focuses on real raster, trajectory, dense-point, and faceted examples."),
      tags$hr(),
      uiOutput("real_data_notes")
    ),
    mainPanel(
      ggWebGLOutput("webgl_plot", height = "620px"),
      conditionalPanel(
        condition = "input.show_reference",
        plotOutput("reference_plot", height = "360px")
      )
    )
  )
)

server <- function(input, output, session) {
  current_plots <- reactive(real_data_plots())
  current_plot <- reactive(current_plots()[[input$scenario]])

  output$real_data_notes <- renderUI({
    info <- metadata[[input$scenario]]

    tagList(
      tags$h4(info$title),
      tags$p(tags$strong("Scenario: "), info$subtitle),
      tags$p(tags$strong("Package-user use case: "), info$use_case),
      tags$p(tags$strong("What to look for: "), info$reading_hint)
    )
  })

  output$webgl_plot <- renderGgWebGL({
    ggplot_webgl(current_plot(), width = "100%", height = 620)
  })

  output$reference_plot <- renderPlot({
    current_plot()
  })
}

shinyApp(ui, server)
