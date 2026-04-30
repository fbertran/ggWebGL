# Shiny Output Binding for ggWebGL

Shiny Output Binding for ggWebGL

## Usage

``` r
ggWebGLOutput(outputId, width = "100%", height = "480px")
```

## Arguments

- outputId:

  Output variable to read from.

- width, height:

  Widget dimensions.

## Value

A Shiny output tag.

## Examples

``` r
ui <- shiny::fluidPage(
  ggWebGLOutput("plot", height = "320px")
)

ui
#> <div class="container-fluid">
#>   <div class="ggWebGL html-widget html-widget-output shiny-report-size html-fill-item" id="plot" style="width:100%;height:320px;"></div>
#> </div>
```
