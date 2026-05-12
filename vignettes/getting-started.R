## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## ----eval = FALSE-------------------------------------------------------------
# library(ggplot2)
# library(ggWebGL)
# 
# plot <- ggplot(diamonds, aes(carat, price, colour = cut)) +
#   geom_point_webgl(size = 1.1, alpha = 0.18) +
#   theme_webgl(
#     shader = "density_splat",
#     interactions = c("pan", "zoom", "hover")
#   )
# 
# ggplot_webgl(plot, height = 520)

