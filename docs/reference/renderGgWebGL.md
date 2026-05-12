# Render a ggWebGL Widget in Shiny

Render a ggWebGL Widget in Shiny

## Usage

``` r
renderGgWebGL(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- expr:

  An expression returning a `ggWebGL` widget.

- env:

  Evaluation environment.

- quoted:

  Whether `expr` is quoted.

## Value

A Shiny render function.

## Examples

``` r
server <- function(input, output, session) {
  output$plot <- renderGgWebGL({
    ggplot_webgl(
      ggplot2::ggplot(
        mtcars[1:8, ],
        ggplot2::aes(mpg, wt, colour = factor(cyl))
      ) +
        geom_point_webgl(size = 2) +
        theme_webgl()
    )
  })
}

server
#> function (input, output, session) 
#> {
#>     output$plot <- renderGgWebGL({
#>         ggplot_webgl(ggplot2::ggplot(mtcars[1:8, ], ggplot2::aes(mpg, 
#>             wt, colour = factor(cyl))) + geom_point_webgl(size = 2) + 
#>             theme_webgl())
#>     })
#> }
#> <environment: 0x121ef36b8>
```
