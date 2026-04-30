library(shiny)

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

metadata <- showcase_metadata()

ui <- fluidPage(
  titlePanel("ggWebGL Renderer Showcase Demo"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "detail",
        label = "Detail preset",
        choices = c("Standard" = "standard", "High detail" = "high_detail"),
        selected = "standard"
      ),
      selectInput(
        inputId = "scenario",
        label = "Scenario",
        choices = setNames(names(metadata), vapply(metadata, `[[`, character(1), "title")),
        selected = "latent_cloud"
      ),
      checkboxInput("show_reference", "Show ggplot2 reference panel", value = TRUE),
      helpText("The standalone gallery exporter uses the high-detail preset by default."),
      tags$hr(),
      uiOutput("showcase_notes")
    ),
    mainPanel(
      ggWebGLOutput("webgl_plot", height = "560px"),
      conditionalPanel(
        condition = "input.show_reference",
        plotOutput("reference_plot", height = "340px")
      )
    )
  )
)

server <- function(input, output, session) {
  current_plots <- reactive({
    showcase_plots(detail = input$detail)
  })

  current_plot <- reactive(current_plots()[[input$scenario]])

  output$showcase_notes <- renderUI({
    info <- metadata[[input$scenario]]

    tagList(
      tags$h4(info$title),
      tags$p(tags$strong("Preset: "), if (identical(input$detail, "high_detail")) "High detail" else "Standard"),
      tags$p(tags$strong("Scenario: "), info$subtitle),
      tags$p(tags$strong("Package-user use case: "), info$use_case),
      tags$p(tags$strong("What to look for: "), info$reading_hint)
    )
  })

  output$webgl_plot <- renderGgWebGL({
    ggplot_webgl(current_plot(), width = "100%", height = 560)
  })

  output$reference_plot <- renderPlot({
    current_plot()
  })
}

shinyApp(ui, server)
