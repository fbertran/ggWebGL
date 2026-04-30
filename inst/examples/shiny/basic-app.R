library(ggplot2)
library(shiny)

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(ggWebGL)
}

ui <- fluidPage(
  titlePanel("ggWebGL Demo"),
  ggWebGLOutput("plot", height = "420px")
)

server <- function(input, output, session) {
  output$plot <- renderGgWebGL({
    ggplot_webgl(
      ggplot(data.frame(x = seq(-4, 4, length.out = 200)), aes(x, sin(x))) +
        geom_line_webgl(linewidth = 1.2, colour = "#0f766e") +
        geom_point_webgl(
          data = data.frame(x = seq(-4, 4, length.out = 25)),
          aes(x, sin(x)),
          colour = "#b45309",
          size = 2.4,
          inherit.aes = FALSE
        ) +
        theme_webgl(
          shader = "trajectory_age",
          interactions = c("pan", "zoom", "hover")
        )
    )
  })
}

shinyApp(ui, server)
