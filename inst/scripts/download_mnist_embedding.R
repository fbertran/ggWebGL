if (!requireNamespace("keras", quietly = TRUE)) {
  stop("The 'keras' package is required to build the MNIST embedding export.")
}

output <- commandArgs(trailingOnly = TRUE)
has_uwot <- requireNamespace("uwot", quietly = TRUE)
output <- if (length(output)) {
  output[[1]]
} else if (has_uwot) {
  "mnist_umap_10k.csv.gz"
} else {
  "mnist_embedding.csv.gz"
}

mnist <- keras::dataset_mnist()
x <- mnist$train$x
y <- mnist$train$y

n <- dim(x)[1]
matrix_x <- matrix(as.numeric(x), nrow = n, byrow = FALSE)
matrix_x <- matrix_x / 255

if (has_uwot) {
  embedding_xy <- uwot::umap(
    matrix_x,
    n_components = 2L,
    n_neighbors = 20L,
    min_dist = 0.08,
    ret_model = FALSE,
    verbose = TRUE
  )
  method <- "umap"
} else {
  projection <- stats::prcomp(matrix_x, center = TRUE, scale. = FALSE)
  embedding_xy <- projection$x[, 1:2, drop = FALSE]
  method <- "pca"
}

embedding <- data.frame(
  embed_x = embedding_xy[, 1],
  embed_y = embedding_xy[, 2],
  digit = y,
  embedding_method = method
)

con <- gzfile(output, open = "wt")
write.csv(embedding, con, row.names = FALSE)
close(con)

message(
  "Wrote MNIST embedding export (", method, ") to: ",
  normalizePath(output, winslash = "/", mustWork = FALSE)
)
