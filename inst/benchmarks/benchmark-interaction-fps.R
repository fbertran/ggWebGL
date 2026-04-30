# Interaction-frame benchmark scaffold for ggWebGL frame-rate evidence.
#
# The output contract is intentionally strict. Do not cite a fixed frame-rate
# value unless rows from this script were generated on the named target machine
# and archived with the commit SHA.

fps_claim_required_columns <- function() {
  c(
    "claim_id",
    "package_version",
    "commit_sha",
    "dataset_size",
    "primitive_counts",
    "browser",
    "browser_version",
    "device",
    "gpu_renderer",
    "os",
    "pixel_width",
    "pixel_height",
    "shader",
    "rendering_mode",
    "dimension",
    "interaction",
    "frame_count",
    "warmup_frames",
    "median_frame_time_ms",
    "p95_frame_time_ms",
    "median_fps",
    "p95_fps",
    "artifact_html",
    "artifact_csv",
    "status",
    "created_at"
  )
}

ggwebgl_interaction_commit_sha <- function() {
  sha <- tryCatch(
    system("git rev-parse --short HEAD", intern = TRUE),
    warning = function(e) character(),
    error = function(e) character()
  )
  if (!length(sha) || !nzchar(sha[[1L]])) {
    return(NA_character_)
  }
  sha[[1L]]
}

ggwebgl_interaction_device_label <- function() {
  info <- Sys.info()
  paste(stats::na.omit(c(info[["sysname"]], info[["machine"]])), collapse = " ")
}

ggwebgl_package_version_label <- function() {
  tryCatch(
    as.character(utils::packageVersion("ggWebGL")),
    error = function(e) NA_character_
  )
}

fps_claim_metrics_template <- function() {
  out <- data.frame(
    claim_id = character(),
    package_version = character(),
    commit_sha = character(),
    dataset_size = integer(),
    primitive_counts = character(),
    browser = character(),
    browser_version = character(),
    device = character(),
    gpu_renderer = character(),
    os = character(),
    pixel_width = integer(),
    pixel_height = integer(),
    shader = character(),
    rendering_mode = character(),
    dimension = character(),
    interaction = character(),
    frame_count = integer(),
    warmup_frames = integer(),
    median_frame_time_ms = numeric(),
    p95_frame_time_ms = numeric(),
    median_fps = numeric(),
    p95_fps = numeric(),
    artifact_html = character(),
    artifact_csv = character(),
    status = character(),
    created_at = character(),
    stringsAsFactors = FALSE
  )
  out[fps_claim_required_columns()]
}

benchmark_interaction_frame_times <- function(output_file = file.path(tempdir(), "ggwebgl_interaction_frame_times.csv"),
                                              dataset_size = 100000L,
                                              shader = "density_splat",
                                              pixel_width = 900L,
                                              pixel_height = 600L,
                                              frame_count = 90L,
                                              warmup_frames = 15L,
                                              interaction = "pan_zoom",
                                              rendering_mode = "visualization",
                                              dimension = "2d",
                                              include_browser = FALSE) {
  dataset_size <- as.integer(dataset_size)[[1L]]
  pixel_width <- as.integer(pixel_width)[[1L]]
  pixel_height <- as.integer(pixel_height)[[1L]]
  frame_count <- as.integer(frame_count)[[1L]]
  warmup_frames <- as.integer(warmup_frames)[[1L]]
  shader <- as.character(shader)[[1L]]
  browser_available <- isTRUE(include_browser) && requireNamespace("chromote", quietly = TRUE)
  status <- if (browser_available) "browser_metric_pending" else "browser_unavailable"

  row <- data.frame(
    claim_id = sprintf("ggwebgl-%s-%s-%s", shader, dataset_size, ggwebgl_interaction_commit_sha()),
    package_version = ggwebgl_package_version_label(),
    commit_sha = ggwebgl_interaction_commit_sha(),
    dataset_size = dataset_size,
    primitive_counts = sprintf("points=%s", dataset_size),
    browser = if (browser_available) "chromote" else "unavailable",
    browser_version = NA_character_,
    device = ggwebgl_interaction_device_label(),
    gpu_renderer = NA_character_,
    os = paste(Sys.info()[["sysname"]], Sys.info()[["release"]]),
    pixel_width = pixel_width,
    pixel_height = pixel_height,
    shader = shader,
    rendering_mode = as.character(rendering_mode)[[1L]],
    dimension = as.character(dimension)[[1L]],
    interaction = as.character(interaction)[[1L]],
    frame_count = frame_count,
    warmup_frames = warmup_frames,
    median_frame_time_ms = NA_real_,
    p95_frame_time_ms = NA_real_,
    median_fps = NA_real_,
    p95_fps = NA_real_,
    artifact_html = NA_character_,
    artifact_csv = normalizePath(output_file, winslash = "/", mustWork = FALSE),
    status = status,
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    stringsAsFactors = FALSE
  )

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(row, file = output_file, row.names = FALSE)
  row
}

validate_fps_claim_metrics <- function(metrics) {
  if (!is.data.frame(metrics)) {
    stop("Frame-rate metrics must be a data frame.", call. = FALSE)
  }
  missing <- setdiff(fps_claim_required_columns(), names(metrics))
  if (length(missing)) {
    stop(
      "Frame-rate metrics are missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  TRUE
}
