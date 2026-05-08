derive_single_panel_compatibility <- function(render) {
  if (!is.list(render) || length(render$panels) != 1L) {
    return(render)
  }

  render$panel <- render$panels[[1]]$panel_id
  render$viewport <- render$panels[[1]]$viewport
  render$layers <- render$panels[[1]]$layers
  render
}

validate_ggwebgl_scene <- function(scene, allow_legacy = TRUE) {
  if (!is.list(scene)) {
    rlang::abort("A ggWebGL scene must be a list.")
  }

  if (is.null(scene$render)) {
    return(scene)
  }

  if (!is.list(scene$render)) {
    rlang::abort("A ggWebGL scene `render` field must be a list.")
  }

  if (is.null(scene$scene_version)) {
    if (!isTRUE(allow_legacy)) {
      rlang::abort("A ggWebGL typed scene must include `scene_version`.")
    }
    scene$scene_version <- ggwebgl_scene_version()
  }

  if (!identical(as.integer(scene$scene_version), ggwebgl_scene_version())) {
    rlang::abort("Unsupported ggWebGL `scene_version`.")
  }

  if (is.null(scene$render$panels)) {
    if (isTRUE(allow_legacy) && !is.null(scene$render$layers)) {
      scene$render$panels <- list(compact_list(list(
        panel_id = scene$render$panel %||% 1L,
        row = 1L,
        col = 1L,
        viewport = scene$render$viewport %||% list(x = c(0, 1), y = c(0, 1)),
        layers = scene$render$layers
      )))
    } else {
      rlang::abort("A ggWebGL typed scene `render` field must include `panels`.")
    }
  }

  if (!is.list(scene$render$panels)) {
    rlang::abort("A ggWebGL typed scene `render$panels` field must be a list.")
  }

  for (panel in scene$render$panels) {
    if (!is.list(panel)) {
      rlang::abort("Every ggWebGL scene panel must be a list.")
    }
    if (is.null(panel$panel_id)) {
      rlang::abort("Every ggWebGL scene panel must include `panel_id`.")
    }
    if (!is.null(panel$layers)) {
      invisible(lapply(panel$layers, ggwebgl_validate_layer))
    }
  }

  scene$render$dimension <- scene$render$dimension %||% scene$webgl$dimension %||% "2d"
  scene$render$coordinate_system <- scene$render$coordinate_system %||%
    ggwebgl_coordinate_system(scene$render$dimension)
  scene$render$messages <- unname(as.character(scene$render$messages %||% character()))
  scene$render <- derive_single_panel_compatibility(scene$render)
  scene
}
