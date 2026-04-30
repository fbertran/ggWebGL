if (!requireNamespace("dplyr", quietly = TRUE)) {
  stop("The 'dplyr' package is required to build the full storm-track export.")
}

output <- commandArgs(trailingOnly = TRUE)
output <- if (length(output)) output[[1]] else "storm_tracks_full.csv.gz"

data("storms", package = "dplyr")

storms$storm_id <- paste0(storms$name, "-", storms$year)
storms$timestamp <- sprintf(
  "%04d-%02d-%02dT%02d:00:00Z",
  storms$year,
  storms$month,
  storms$day,
  storms$hour
)

export <- storms[, c(
  "storm_id", "name", "timestamp", "long", "lat",
  "wind", "pressure", "status", "category"
)]
names(export) <- c(
  "storm_id", "storm_name", "timestamp", "lon", "lat",
  "wind", "pressure", "status", "category"
)

con <- gzfile(output, open = "wt")
write.csv(export, con, row.names = FALSE)
close(con)

message("Wrote full storm-track export to: ", normalizePath(output, winslash = "/", mustWork = FALSE))
