surface_gallery_volcano_widget <- function(height = 480) {
  surface <- ggWebGL::ggwebgl_layer_surface(
    ggWebGL::surface_matrix(volcano),
    shading = "surface_height_colormap",
    wireframe = TRUE,
    contours = TRUE,
    contour_levels = pretty(range(volcano), n = 8)
  )

  ggWebGL::ggWebGL(
    ggWebGL::ggwebgl_spec(
      layers = list(surface),
      labels = list(
        title = "Structured volcano surface",
        subtitle = "Height colormap, wireframe, contours, and orbit camera",
        x = "column",
        y = "row"
      ),
      webgl = ggWebGL::webgl_spec(camera = "orbit", projection = "perspective")
    ),
    height = height
  )
}

surface_gallery_mesh_widget <- function(height = 480) {
  vertices <- data.frame(
    x = c(-1, 1, 1, -1, -1, 1, 1, -1),
    y = c(-1, -1, 1, 1, -1, -1, 1, 1),
    z = c(-1, -1, -1, -1, 1, 1, 1, 1),
    scalar = c(0, 0.2, 0.45, 0.3, 0.6, 0.75, 1, 0.85)
  )
  triangles <- data.frame(
    i = c(1, 1, 5, 5, 1, 1, 2, 2, 3, 3, 4, 4),
    j = c(2, 3, 8, 7, 5, 6, 6, 7, 7, 8, 8, 5),
    k = c(3, 4, 7, 6, 6, 2, 7, 3, 8, 4, 5, 1)
  )
  mesh <- ggWebGL::ggwebgl_layer_mesh(
    vertices,
    x = "x",
    y = "y",
    z = "z",
    scalar = "scalar",
    triangles = triangles,
    shading = "mesh_scalar_colormap",
    wireframe = TRUE,
    pick_id = paste0("face", seq_len(nrow(triangles)))
  )

  ggWebGL::ggWebGL(
    ggWebGL::ggwebgl_spec(
      layers = list(mesh),
      labels = list(
        title = "Unstructured scalar mesh",
        subtitle = "Indexed triangles, scalar colormap, wireframe, and face ids"
      ),
      webgl = ggWebGL::webgl_spec(camera = "trackball", projection = "perspective")
    ),
    height = height
  )
}

surface_gallery_widgets <- function() {
  list(
    volcano = surface_gallery_volcano_widget(),
    mesh = surface_gallery_mesh_widget()
  )
}

run_manual_surface_gallery <- function(output_dir = tempdir(), selfcontained = FALSE) {
  if (!dir.exists(output_dir)) {
    stop("`output_dir` must exist before exporting the gallery.", call. = FALSE)
  }
  widgets <- surface_gallery_widgets()
  files <- file.path(output_dir, paste0(names(widgets), "-surface-gallery.html"))
  for (i in seq_along(widgets)) {
    htmlwidgets::saveWidget(widgets[[i]], file = files[[i]], selfcontained = selfcontained)
  }
  invisible(stats::setNames(files, names(widgets)))
}
