## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(ggWebGL)
helper_path <- system.file("examples", "real", "real-data-helpers.R", package = "ggWebGL")
source(helper_path, local = knitr::knit_global())
real_examples <- real_data_plots()
real_info <- real_data_metadata()

## ----volcano-dem, out.width='100%'--------------------------------------------
real_examples$volcano_dem

## ----volcano-demgl, out.width='100%'------------------------------------------
ggplot_webgl(real_examples$volcano_dem+theme_webgl(shader = "default"), height = 620)

## ----volcano-demgl2, out.width='100%'-----------------------------------------
ggplot_webgl(real_examples$volcano_dem, height = 620)

## ----storm-tracks, out.width='100%'-------------------------------------------
real_examples$storm_tracks

## ----storm-tracksgl, out.width='100%'-----------------------------------------
ggplot_webgl(real_examples$storm_tracks+theme_webgl(shader = "default"), height = 620)

## ----storm-tracksgl2, out.width='100%'----------------------------------------
ggplot_webgl(real_examples$storm_tracks, height = 620)

## ----dense-embedding, out.width='100%'----------------------------------------
real_examples$dense_embedding

## ----dense-embeddinggl, out.width='100%'--------------------------------------
ggplot_webgl(real_examples$dense_embedding+theme_webgl(shader = "default"), height = 620)

## ----dense-embeddinggl2, out.width='100%'-------------------------------------
ggplot_webgl(real_examples$dense_embedding, height = 620)

## ----faceted-embedding, out.width='100%'--------------------------------------
real_examples$faceted_embedding

## ----faceted-embeddinggl, out.width='100%'------------------------------------
ggplot_webgl(real_examples$faceted_embedding+theme_webgl(shader = "default"), height = 720)

## ----faceted-embeddinggl2, out.width='100%'-----------------------------------
ggplot_webgl(real_examples$faceted_embedding, height = 720)

