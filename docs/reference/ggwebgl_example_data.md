# Load Packaged ggWebGL Example Data

Read one of the packaged real-data subsets used by the examples,
vignettes, and benchmark scripts.

## Usage

``` r
ggwebgl_example_data(
  name = c("volcano_dem", "storm_tracks", "dense_embedding", "diamonds_embedding")
)
```

## Arguments

- name:

  Name of the example dataset to load. `"dense_embedding"` is the stable
  public alias for the packaged dense point-cloud dataset. The legacy
  alias `"diamonds_embedding"` is kept for backward compatibility.

## Value

A data frame for CSV-backed datasets or the saved R object for
`volcano_dem`.

## Examples

``` r
dem <- ggwebgl_example_data("volcano_dem")
str(dem)
#> 'data.frame':    5307 obs. of  3 variables:
#>  $ x        : int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ y        : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ elevation: num  100 100 101 101 101 101 101 100 100 100 ...
#>  - attr(*, "out.attrs")=List of 2
#>   ..$ dim     : Named int [1:2] 61 87
#>   .. ..- attr(*, "names")= chr [1:2] "x" "y"
#>   ..$ dimnames:List of 2
#>   .. ..$ x: chr [1:61] "x= 1" "x= 2" "x= 3" "x= 4" ...
#>   .. ..$ y: chr [1:87] "y= 1" "y= 2" "y= 3" "y= 4" ...
```
