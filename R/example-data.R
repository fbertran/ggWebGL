#' Load Packaged ggWebGL Example Data
#'
#' Read one of the packaged real-data subsets used by the examples, vignettes,
#' and benchmark scripts.
#'
#' @param name Name of the example dataset to load. `"dense_embedding"` is the
#'   stable public alias for the packaged dense point-cloud dataset. The legacy
#'   alias `"diamonds_embedding"` is kept for backward compatibility.
#'
#' @return A data frame for CSV-backed datasets or the saved R object for
#'   `volcano_dem`.
#'
#' @examples
#' dem <- ggwebgl_example_data("volcano_dem")
#' str(dem)
#' @export
ggwebgl_example_data <- function(name = c(
  "volcano_dem",
  "storm_tracks",
  "dense_embedding",
  "diamonds_embedding"
)) {
  name <- match.arg(name)

  dense_embedding_path <- function() {
    candidates <- c(
      system.file("extdata", "real", "mnist_umap_10k.csv.gz", package = "ggWebGL"),
      system.file("extdata", "real", "diamonds_pca_10k.csv.gz", package = "ggWebGL")
    )
    existing <- candidates[nzchar(candidates) & file.exists(candidates)]

    if (!length(existing)) {
      return("")
    }

    existing[[1]]
  }

  path <- switch(
    name,
    volcano_dem = system.file("extdata", "real", "volcano_dem.rds", package = "ggWebGL"),
    storm_tracks = system.file("extdata", "real", "storm_tracks_subset.csv.gz", package = "ggWebGL"),
    dense_embedding = dense_embedding_path(),
    diamonds_embedding = dense_embedding_path()
  )

  if (!nzchar(path) || !file.exists(path)) {
    rlang::abort(paste0("Could not locate packaged example data for `", name, "`."))
  }

  if (grepl("\\.rds$", path, ignore.case = TRUE)) {
    return(readRDS(path))
  }

  utils::read.csv(path, stringsAsFactors = FALSE)
}
