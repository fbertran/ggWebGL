## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(ggWebGL)
helper_path <- system.file("examples", "showcase", "showcase-helpers.R", package = "ggWebGL")
source(helper_path, local = knitr::knit_global())
showcase_info <- showcase_metadata()
showcase_examples <- showcase_plots(detail = "standard")

## ----latent-cloud, out.width='100%'-------------------------------------------
showcase_examples$latent_cloud

## ----latent-cloudgl, out.width='100%'-----------------------------------------
ggplot_webgl(showcase_examples$latent_cloud+theme_webgl(shader = "default", height = 630))

## ----latent-cloudgl2, out.width='100%'----------------------------------------
ggplot_webgl(showcase_examples$latent_cloud, height = 630)

## ----diffusion-paths, out.width='100%'----------------------------------------
showcase_examples$diffusion_paths

## ----diffusion-pathsgl, out.width='100%'--------------------------------------
ggplot_webgl(showcase_examples$diffusion_paths+theme_webgl(shader = "default", height = 630), height = 630)

## ----diffusion-pathsgl2, out.width='100%'-------------------------------------
ggplot_webgl(showcase_examples$diffusion_paths, height = 630)

## ----phase-portrait, out.width='100%'-----------------------------------------
showcase_examples$phase_portrait

## ----phase-portraitgl, out.width='100%'---------------------------------------
ggplot_webgl(showcase_examples$phase_portrait+theme_webgl(shader = "default"), height = 630)

## ----phase-portraitgl2, out.width='100%'--------------------------------------
ggplot_webgl(showcase_examples$phase_portrait, height = 630)

## ----loss-landscape, out.width='100%'-----------------------------------------
showcase_examples$loss_landscape

## ----loss-landscapegl, out.width='100%'---------------------------------------
ggplot_webgl(showcase_examples$loss_landscape+theme_webgl(shader = "default"), height = 630)

## ----loss-landscapegl2, out.width='100%'--------------------------------------
ggplot_webgl(showcase_examples$loss_landscape, height = 630)

## ----loss-landscapegl3, out.width='100%'--------------------------------------
ggplot_webgl(showcase_examples$loss_landscape+theme_webgl(shader = "trajectory_age"), height = 630)

## ----loss-landscapegl4, out.width='100%'--------------------------------------
ggplot_webgl(showcase_examples$loss_landscape+theme_webgl(shader = "trajectory_age_glow"), height = 630)

