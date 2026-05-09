if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
  shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::tags$h3("ggWebGL structured surface"),
      ggWebGL::ggWebGLOutput("surface", height = "520px")
    ),
    server = function(input, output, session) {
      output$surface <- ggWebGL::renderGgWebGL({
        ggWebGL::ggWebGL(
          ggWebGL::ggwebgl_spec(
            layers = list(
              ggWebGL::ggwebgl_layer_surface(
                ggWebGL::surface_matrix(volcano),
                shading = "surface_lambert",
                wireframe = TRUE
              )
            ),
            labels = list(title = "Volcano DEM surface"),
            webgl = ggWebGL::webgl_spec(camera = "orbit", projection = "perspective")
          )
        )
      })
    }
  )
}
