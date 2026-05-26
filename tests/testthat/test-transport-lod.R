test_that("transport options normalize and validate", {
  transport <- ggwebgl_transport(
    mode = "auto",
    threshold = 12L,
    progressive = "auto",
    chunk_size = 8L,
    position = "float32",
    colors = "auto",
    lod = "auto",
    lod_max_points = 5L
  )

  expect_s3_class(transport, "ggwebgl_transport")
  expect_equal(transport$mode, "auto")
  expect_equal(transport$threshold, 12L)
  expect_equal(transport$chunk_size, 8L)
  expect_error(ggwebgl_transport(mode = "bad"), "mode")
  expect_error(ggwebgl_transport(threshold = 0L), "threshold")
  expect_error(ggwebgl_transport(chunk_size = 0L), "chunk_size")
})

test_that("compact transport is automatic for large point layers only", {
  data <- data.frame(
    x = seq_len(6),
    y = seq_len(6),
    group = rep(c("#0f766e", "#f97316"), 3),
    stringsAsFactors = FALSE
  )
  layer <- ggwebgl_layer_points(data, x = "x", y = "y", colour = "group")

  legacy <- ggwebgl_spec(
    layers = list(layer),
    webgl = list(transport = ggwebgl_transport(mode = "auto", threshold = 100L))
  )
  expect_null(legacy$render$panels[[1]]$layers[[1]]$compact)
  expect_equal(legacy$render$transport$compact_layers, 0L)

  compact <- ggwebgl_spec(
    layers = list(layer),
    webgl = list(transport = ggwebgl_transport(mode = "auto", threshold = 5L))
  )
  compact_layer <- compact$render$panels[[1]]$layers[[1]]
  expect_equal(compact$render$transport$compact_layers, 1L)
  expect_equal(compact$render$transport$compact_point_count, 6L)
  expect_equal(compact_layer$compact$position$encoding, "float32_base64")
  expect_equal(compact_layer$compact$color$encoding, "palette_rgba_u8")
  expect_null(compact_layer$x)
  expect_null(compact_layer$rgba)

  forced_legacy <- ggwebgl_spec(
    layers = list(layer),
    webgl = list(transport = ggwebgl_transport(mode = "legacy", threshold = 1L))
  )
  expect_null(forced_legacy$render$panels[[1]]$layers[[1]]$compact)
})

test_that("base64 typed-array encoders round trip compact numeric fields", {
  values <- c(-1, 0.5, 3.25)
  encoded <- ggWebGL:::ggwebgl_encode_float32_base64(values)
  decoded <- readBin(jsonlite::base64_dec(encoded), numeric(), n = length(values), size = 4L, endian = "little")
  expect_equal(decoded, values, tolerance = 1e-6)

  u16 <- c(0L, 255L, 256L, 65535L)
  raw16 <- as.integer(jsonlite::base64_dec(ggWebGL:::ggwebgl_encode_uint16_base64(u16)))
  decoded16 <- raw16[c(TRUE, FALSE)] + raw16[c(FALSE, TRUE)] * 256L
  expect_equal(decoded16, u16)
})

test_that("quantized point transport records ranges and uint16 positions", {
  layer <- ggwebgl_layer_points(
    data.frame(x = c(-1, 0, 1), y = c(10, 20, 30)),
    x = "x",
    y = "y",
    colour = "#0f766e"
  )
  spec <- ggwebgl_spec(
    layers = list(layer),
    webgl = list(transport = ggwebgl_transport(mode = "compact", position = "quantized"))
  )
  position <- spec$render$panels[[1]]$layers[[1]]$compact$position

  expect_equal(position$encoding, "uint16_base64")
  expect_equal(position$components, 2L)
  expect_equal(position$ranges$x, c(-1, 1))
  expect_equal(position$ranges$y, c(10, 30))
})

test_that("point LOD grid previews are deterministic and bounded", {
  data <- data.frame(
    x = rep(seq_len(40), each = 2),
    y = rep(seq_len(2), times = 40),
    colour = rep(c("#0f766e", "#f97316"), 40),
    stringsAsFactors = FALSE
  )
  layer <- ggwebgl_layer_points(data, x = "x", y = "y", colour = "colour")
  first <- ggWebGL:::ggwebgl_point_lod_grid(layer, max_points = 12L, grid_size = 16L)
  second <- ggWebGL:::ggwebgl_point_lod_grid(layer, max_points = 12L, grid_size = 16L)

  expect_equal(first, second)
  expect_lte(first$rows, 12L)
  expect_equal(first$source_rows, nrow(data))
  expect_true(all(c("x", "y", "rgba") %in% names(first)))
})

test_that("transport modules and progressive upload are wired in JavaScript", {
  yaml <- ggwebgl_test_read_text("inst/htmlwidgets/ggWebGL.yaml")
  buffers <- ggwebgl_test_read_text("inst/htmlwidgets/lib/buffers.js")
  lod <- ggwebgl_test_read_text("inst/htmlwidgets/lib/lod.js")
  js <- ggwebgl_test_read_text("inst/htmlwidgets/ggWebGL.js")

  expect_match(yaml, "lib/buffers.js", fixed = TRUE)
  expect_match(yaml, "lib/lod.js", fixed = TRUE)
  expect_lt(regexpr("lib/buffers.js", yaml)[[1]], regexpr("lib/picking.js", yaml)[[1]])
  expect_lt(regexpr("lib/lod.js", yaml)[[1]], regexpr("lib/picking.js", yaml)[[1]])

  expect_match(buffers, "decodeBase64ToUint8Array", fixed = TRUE)
  expect_match(buffers, "materializePointLayerCompact", fixed = TRUE)
  expect_match(buffers, "palette_rgba_u8", fixed = TRUE)
  expect_match(lod, "pointLodLayer", fixed = TRUE)
  expect_match(js, "pointLayerProgressiveEnabled", fixed = TRUE)
  expect_match(js, "requestIdleCallback", fixed = TRUE)
  expect_match(js, "window.__ggwebgl_transport_metrics", fixed = TRUE)
  expect_match(js, "flattenPointLayer(layer, null, null, 0", fixed = TRUE)
})
