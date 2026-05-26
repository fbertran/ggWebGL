shader_registry_path <- function(path) {
  ggwebgl_test_file_path(path)
}

shader_registry_text <- function(path) {
  paste(readLines(shader_registry_path(path), warn = FALSE), collapse = "\n")
}

test_that("theme_webgl normalizes registry-visible shader names and aliases", {
  expect_equal(theme_webgl(shader = "density")$shader, "density_splat")
  expect_equal(theme_webgl(shader = "uncertainty")$shader, "uncertainty_alpha")
  expect_equal(theme_webgl(shader = "point-sprite-glow")$shader, "point_sprite_glow")

  expect_equal(theme_webgl(shader = "velocity")$shader, "trajectory_velocity")
  expect_equal(theme_webgl(shader = "direction")$shader, "trajectory_direction")

  expect_equal(theme_webgl(shader = "raster")$shader, "raster_texture")
  expect_equal(theme_webgl(shader = "threshold")$shader, "raster_threshold")
  expect_equal(theme_webgl(shader = "raster-contour")$shader, "raster_contour_overlay")
})

test_that("mesh and surface material modes validate through registry-compatible names", {
  expect_equal(ggwebgl_material(shading = "mesh_scalar_colormap")$shading, "mesh_scalar_colormap")
  expect_equal(ggwebgl_material(shading = "mesh_selection_highlight")$shading, "mesh_selection_highlight")
  expect_equal(ggwebgl_material(shading = "surface_lambert")$shading, "surface_lambert")
  expect_equal(ggwebgl_material(shading = "surface_height_colormap")$shading, "surface_height_colormap")

  expect_equal(
    ggwebgl_layer_surface(matrix(1:4, nrow = 2L), shading = "surface_height_colormap")$surface_meta$shading,
    "surface_height_colormap"
  )

  vertices <- data.frame(x = c(0, 1, 0), y = c(0, 0, 1), z = c(0, 0, 0), scalar = c(0, 0.5, 1))
  triangles <- data.frame(i = 1L, j = 2L, k = 3L)
  mesh <- ggwebgl_layer_mesh(
    vertices,
    x = "x",
    y = "y",
    z = "z",
    scalar = "scalar",
    triangles = triangles,
    shading = "mesh_scalar_colormap"
  )
  expect_equal(mesh$material$shading, "mesh_scalar_colormap")

  expect_error(ggwebgl_material(shading = "not_a_shader"), "arg")
})

test_that("program registry declares required shader families and entries", {
  registry <- shader_registry_text("inst/htmlwidgets/lib/program-registry.js")

  required <- c(
    "points", "default", "density_splat", "uncertainty_alpha", "point_sprite_glow",
    "lines", "trajectory_age", "trajectory_velocity", "trajectory_direction",
    "raster", "raster_texture", "raster_threshold", "raster_contour_overlay",
    "surface", "surface_flat", "surface_lambert", "surface_height_colormap",
    "mesh", "mesh_flat", "mesh_lambert", "mesh_scalar_colormap", "mesh_selection_highlight"
  )

  for (name in required) {
    expect_match(registry, name, fixed = TRUE, info = name)
  }

  expect_match(registry, "material_type", fixed = TRUE)
  expect_match(registry, "attributes", fixed = TRUE)
  expect_match(registry, "uniforms", fixed = TRUE)
  expect_match(registry, "fallback", fixed = TRUE)
  expect_match(registry, "layerTypes", fixed = TRUE)
  expect_match(registry, "getShaderEntry", fixed = TRUE)
  expect_match(registry, "shaderModeForLayer", fixed = TRUE)
  expect_match(registry, "getProgramForLayer", fixed = TRUE)
})

test_that("widget shader dispatch uses registry selection", {
  js <- shader_registry_text("inst/htmlwidgets/ggWebGL.js")

  expect_match(js, "function shaderRegistryEntryForLayer", fixed = TRUE)
  expect_match(js, "window.ggWebGLProgramRegistry.getShaderEntry", fixed = TRUE)
  expect_match(js, "function shaderModeForLayer(x, layerType, layer)", fixed = TRUE)
  expect_match(js, "window.ggWebGLProgramRegistry.getProgramForLayer", fixed = TRUE)

  expect_false(grepl("layerType === \"points\" && shader === \"density_splat\"", js, fixed = TRUE))
  expect_match(js, "uncertainty = clamp(1.0 - v_age", fixed = TRUE)
  expect_match(js, "point_sprite_glow", fixed = TRUE)
  expect_match(js, "raster_threshold", fixed = TRUE)
  expect_match(js, "raster_contour_overlay", fixed = TRUE)
})

test_that("packaged shader source files exist for required built-ins", {
  required <- c(
    file.path("points", c("default", "density_splat", "uncertainty_alpha", "point_sprite_glow")),
    file.path("lines", c("trajectory_age", "trajectory_velocity", "trajectory_direction")),
    file.path("raster", c("raster_texture", "raster_threshold", "raster_contour_overlay")),
    file.path("surface", c("surface_flat", "surface_lambert", "surface_height_colormap")),
    file.path("mesh", c("mesh_flat", "mesh_lambert", "mesh_scalar_colormap", "mesh_selection_highlight"))
  )

  for (stem in required) {
    vert <- shader_registry_path(file.path("inst", "www", "shaders", paste0(stem, ".vert.glsl")))
    frag <- shader_registry_path(file.path("inst", "www", "shaders", paste0(stem, ".frag.glsl")))
    expect_true(file.exists(vert), info = vert)
    expect_true(file.exists(frag), info = frag)
  }
})
