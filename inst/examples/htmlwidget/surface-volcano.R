if (requireNamespace("ggplot2", quietly = TRUE)) {
  volcano_surface <- ggWebGL::ggWebGL(
    ggWebGL::ggwebgl_spec(
      layers = list(
        ggWebGL::ggwebgl_layer_surface(
          ggWebGL::surface_matrix(volcano),
          shading = "surface_lambert",
          wireframe = TRUE
        )
      ),
      labels = list(title = "Structured volcano surface", x = "column", y = "row"),
      webgl = ggWebGL::webgl_spec(camera = "orbit", projection = "perspective")
    ),
    width = 720,
    height = 480
  )

  volcano_surface
}
