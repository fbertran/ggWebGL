mesh_repo_text <- function(path) {
  candidates <- c(
    file.path(getwd(), path),
    file.path(testthat::test_path(), "..", "..", path)
  )
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    skip(sprintf("%s is unavailable in this installed-package test context.", path))
  }
  paste(readLines(found[[1L]], warn = FALSE), collapse = "\n")
}

tetrahedron_mesh <- function() {
  vertices <- data.frame(
    x = c(0, 1, 0, 0),
    y = c(0, 0, 1, 0),
    z = c(0, 0, 0, 1),
    scalar = c(0.1, 0.4, 0.8, 1.2),
    id = paste0("v", 1:4)
  )
  triangles <- data.frame(
    i = c(1L, 1L, 1L, 2L),
    j = c(2L, 3L, 4L, 3L),
    k = c(3L, 4L, 2L, 4L),
    pick_id = paste0("f", 1:4)
  )
  list(vertices = vertices, triangles = triangles)
}

test_that("as_mesh_webgl validates explicit vertex and triangle inputs", {
  fixture <- tetrahedron_mesh()
  mesh <- as_mesh_webgl(fixture)

  expect_s3_class(mesh, "ggwebgl_mesh")
  expect_equal(nrow(mesh$vertices), 4L)
  expect_equal(nrow(mesh$triangles), 4L)
  expect_equal(mesh$scalar, "scalar")
  expect_equal(mesh$id, "id")
  expect_equal(mesh$pick_id, "pick_id")

  expect_error(as_mesh_webgl(list(vertices = fixture$vertices)), "explicit")
  expect_error(as_mesh_webgl(data.frame(x = 1, y = 1, z = 1)), "include")
  expect_error(
    ggwebgl_mesh(fixture$vertices, transform(fixture$triangles, k = 99L)),
    "existing vertices"
  )
  expect_error(
    ggwebgl_mesh(fixture$vertices, transform(fixture$triangles, i = 1.5)),
    "one-based integers"
  )
  expect_error(
    ggwebgl_mesh(transform(fixture$vertices, x = Inf), fixture$triangles),
    "finite"
  )
})

test_that("ggwebgl_layer_mesh emits indexed unstructured mesh payloads", {
  fixture <- tetrahedron_mesh()
  layer <- ggwebgl_layer_mesh(
    as_mesh_webgl(fixture),
    material = ggwebgl_material(shading = "mesh_scalar_colormap", wireframe = TRUE)
  )

  expect_equal(layer$type, "mesh")
  expect_equal(layer$vertex_count, 4L)
  expect_equal(layer$triangle_count, 4L)
  expect_equal(layer$indices, c(0L, 1L, 2L, 0L, 2L, 3L, 0L, 3L, 1L, 1L, 2L, 3L))
  expect_true(all(layer$wire_indices >= 0L))
  expect_equal(length(layer$wire_indices), 12L)
  expect_equal(layer$scalar_range, c(0.1, 1.2))
  expect_equal(layer$material$shading, "mesh_scalar_colormap")
  expect_true(layer$wireframe)
  expect_equal(layer$pick_id, paste0("f", 1:4))
  expect_length(layer$normal, layer$vertex_count * 3L)
  expect_true(all(is.finite(layer$normal)))
  expect_equal(layer$bbox3d$zmax, 1)
})

test_that("geom_mesh_webgl creates a mesh primitive and defaults to a 3D scene", {
  mesh_data <- data.frame(
    x = c(0, 1, 0),
    y = c(0, 0, 1),
    z = c(0, 0.2, 0.4),
    i = c(1L, 1L, 1L),
    j = c(2L, 2L, 2L),
    k = c(3L, 3L, 3L),
    scalar = c(0.1, 0.5, 0.9)
  )

  widget <- ggplot_webgl(
    ggplot2::ggplot(mesh_data, ggplot2::aes(x, y, z = z, i = i, j = j, k = k, scalar = scalar)) +
      geom_mesh_webgl(shading = "mesh_lambert", wireframe = TRUE)
  )

  expect_true("mesh" %in% widget$x$render$primitives)
  expect_equal(widget$x$render$dimension, "3d")
  expect_equal(widget$x$render$coordinate_system, "cartesian3d")
  expect_gt(widget$x$render$mesh_vertex_count, 0L)
  expect_gt(widget$x$render$mesh_triangle_count, 0L)
  expect_equal(widget$x$render$panels[[1L]]$layers[[1L]]$type, "mesh")
})

test_that("mesh shader modes normalize and reject unknown values", {
  fixture <- tetrahedron_mesh()

  expect_equal(
    ggwebgl_layer_mesh(as_mesh_webgl(fixture), shading = "flat")$material$shading,
    "mesh_flat"
  )
  expect_equal(
    ggwebgl_layer_mesh(as_mesh_webgl(fixture), shading = "mesh_phong_simple")$material$shading,
    "mesh_phong_simple"
  )
  expect_equal(
    ggwebgl_layer_mesh(as_mesh_webgl(fixture), shading = "mesh_selection_highlight")$material$shading,
    "mesh_selection_highlight"
  )
  expect_error(
    ggwebgl_layer_mesh(as_mesh_webgl(fixture), shading = "unsupported"),
    "Unknown mesh shading"
  )
})

test_that("widget source has a dedicated indexed mesh path", {
  js <- mesh_repo_text("inst/htmlwidgets/ggWebGL.js")

  expect_match(js, "var meshVertexShaderSource", fixed = TRUE)
  expect_match(js, "var meshFragmentShaderSource", fixed = TRUE)
  expect_match(js, "function drawMeshLayer", fixed = TRUE)
  expect_match(js, "function createMeshLayerGpuPayload", fixed = TRUE)
  expect_match(js, "a_scalar", fixed = TRUE)
  expect_match(js, "mesh_scalar_colormap", fixed = TRUE)
  expect_match(js, "mesh_phong_simple", fixed = TRUE)
  expect_match(js, "gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER", fixed = TRUE)
  expect_match(js, "gl.drawElements(gl.TRIANGLES", fixed = TRUE)
  expect_match(js, "gl.drawElements(gl.LINES", fixed = TRUE)
  expect_match(js, "function encodeMeshPickId", fixed = TRUE)
  expect_match(js, "function decodeMeshPickColor", fixed = TRUE)
  expect_match(js, "var meshPickVertexShaderSource", fixed = TRUE)
  expect_match(js, "function pickMeshFaceWithObjectIdPass", fixed = TRUE)
  expect_match(js, "function pickMeshFaceAt", fixed = TRUE)

  draw_mesh_body <- sub(".*function drawMeshLayer", "function drawMeshLayer", js)
  draw_mesh_body <- sub("function surfaceShadingMode.*", "", draw_mesh_body)
  expect_false(grepl("drawArrays(gl.TRIANGLES, 0, payload.count)", draw_mesh_body, fixed = TRUE))
})
