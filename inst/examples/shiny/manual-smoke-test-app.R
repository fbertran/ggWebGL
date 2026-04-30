library(ggplot2)
library(shiny)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

smoke_test_plot <- function(scenario = c("points", "lines", "mixed", "raster", "facet")) {
  scenario <- match.arg(scenario)

  if (identical(scenario, "points")) {
    return(
      ggplot(mtcars, aes(mpg, wt, colour = factor(cyl))) +
        geom_point_webgl(size = 3) +
        theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Points Smoke Test", subtitle = "WebGL point rendering")
    )
  }

  if (identical(scenario, "lines")) {
    df <- transform(
      economics_long[economics_long$variable %in% c("psavert", "uempmed"), ],
      scaled_value = value01 * 100
    )

    return(
      ggplot(df, aes(date, scaled_value, colour = variable)) +
        geom_line_webgl(linewidth = 1.1) +
        theme_webgl(shader = "trajectory_age", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Lines Smoke Test", subtitle = "WebGL line rendering")
    )
  }

  if (identical(scenario, "mixed")) {
    df <- data.frame(
      x = seq(-4, 4, length.out = 200),
      y = sin(seq(-4, 4, length.out = 200))
    )

    return(
      ggplot(df, aes(x, y)) +
        geom_line_webgl(linewidth = 1.2, colour = "#0f766e") +
        geom_point_webgl(
          data = df[seq(1, nrow(df), by = 8), , drop = FALSE],
          colour = "#b45309",
          size = 2.5
        ) +
        theme_webgl(shader = "trajectory_age", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Mixed Smoke Test", subtitle = "Line plus sampled points")
    )
  }

  if (identical(scenario, "raster")) {
    grid <- expand.grid(x = seq(-2, 2, length.out = 24), y = seq(-2, 2, length.out = 18))
    grid$z <- with(grid, cos(x * 1.5) * sin(y * 1.2))

    return(
      ggplot(grid, aes(x, y, fill = z)) +
        geom_raster_webgl(interpolate = TRUE) +
        theme_webgl(shader = "default", interactions = c("pan", "zoom", "hover")) +
        labs(title = "Raster Smoke Test", subtitle = "Texture-backed raster rendering")
    )
  }

  ggplot(transform(mtcars, cyl = factor(cyl)), aes(mpg, wt, colour = cyl)) +
    geom_point_webgl(size = 2.4, alpha = 0.85) +
    ggplot2::facet_wrap(~cyl) +
    theme_webgl(shader = "density_splat", interactions = c("pan", "zoom", "hover")) +
    labs(title = "Facet Smoke Test", subtitle = "Fixed-scale multi-panel point rendering")
}

ui <- fluidPage(
  titlePanel("ggWebGL Manual Smoke Test"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "scenario",
        label = "Scenario",
        choices = c("points", "lines", "mixed", "raster", "facet"),
        selected = "mixed"
      ),
      checkboxInput("show_reference", "Show ggplot2 reference plot", value = TRUE),
      helpText("Use this app to compare the htmlwidget renderer against ggplot2 output.")
    ),
    mainPanel(
      ggWebGLOutput("webgl_plot", height = "520px"),
      conditionalPanel(
        condition = "input.show_reference",
        plotOutput("reference_plot", height = "320px")
      )
    )
  )
)

server <- function(input, output, session) {
  current_plot <- reactive(smoke_test_plot(input$scenario))

  output$webgl_plot <- renderGgWebGL({
    ggplot_webgl(current_plot(), width = "100%", height = 520)
  })

  output$reference_plot <- renderPlot({
    current_plot()
  })
}

shinyApp(ui, server)
