# WebGL Boxplot Layer

Add a boxplot layer tagged for the `ggWebGL` renderer. Boxplot
statistics are computed by `ggplot2`; the renderer serializes the built
box body as rectangles, medians/whiskers as pure segments, and outliers
as points.

## Usage

``` r
geom_boxplot_webgl(
  mapping = NULL,
  data = NULL,
  stat = "boxplot",
  position = "dodge2",
  ...,
  outliers = TRUE,
  outlier.colour = NULL,
  outlier.color = NULL,
  outlier.fill = NULL,
  outlier.shape = NULL,
  outlier.size = NULL,
  outlier.stroke = 0.5,
  outlier.alpha = NULL,
  whisker.colour = NULL,
  whisker.color = NULL,
  whisker.linetype = NULL,
  whisker.linewidth = NULL,
  staple.colour = NULL,
  staple.color = NULL,
  staple.linetype = NULL,
  staple.linewidth = NULL,
  median.colour = NULL,
  median.color = NULL,
  median.linetype = NULL,
  median.linewidth = NULL,
  box.colour = NULL,
  box.color = NULL,
  box.linetype = NULL,
  box.linewidth = NULL,
  notch = FALSE,
  notchwidth = 0.5,
  staplewidth = 0,
  varwidth = FALSE,
  na.rm = FALSE,
  orientation = NA,
  show.legend = NA,
  inherit.aes = TRUE
)
```

## Arguments

- mapping:

  Set of aesthetic mappings created by
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html). If
  specified and `inherit.aes = TRUE` (the default), it is combined with
  the default mapping at the top level of the plot. You must supply
  `mapping` if there is no plot mapping.

- data:

  The data to be displayed in this layer. There are three options:

  If `NULL`, the default, the data is inherited from the plot data as
  specified in the call to
  [`ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

  A `data.frame`, or other object, will override the plot data. All
  objects will be fortified to produce a data frame. See
  [`fortify()`](https://ggplot2.tidyverse.org/reference/fortify.html)
  for which variables will be created.

  A `function` will be called with a single argument, the plot data. The
  return value must be a `data.frame`, and will be used as the layer
  data. A `function` can be created from a `formula` (e.g.
  `~ head(.x, 10)`).

- stat:

  Statistical transformation to use. Defaults to `"boxplot"` so
  `ggplot2` computes boxplot summary statistics before WebGL
  serialization.

- position:

  A position adjustment to use on the data for this layer. This can be
  used in various ways, including to prevent overplotting and improving
  the display. The `position` argument accepts the following:

  - The result of calling a position function, such as
    [`position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html).
    This method allows for passing extra arguments to the position.

  - A string naming the position adjustment. To give the position as a
    string, strip the function name of the `position_` prefix. For
    example, to use
    [`position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html),
    give the position as `"jitter"`.

  - For more information and other ways to specify the position, see the
    [layer
    position](https://ggplot2.tidyverse.org/reference/layer_positions.html)
    documentation.

- ...:

  Additional arguments forwarded through
  [`ggplot2::layer()`](https://ggplot2.tidyverse.org/reference/layer.html),
  including
  [`ggplot2::stat_boxplot()`](https://ggplot2.tidyverse.org/reference/geom_boxplot.html)
  parameters such as `coef` and `width`, plus static aesthetics.

- outliers:

  Whether to display (`TRUE`) or discard (`FALSE`) outliers from the
  plot. Hiding or discarding outliers can be useful when, for example,
  raw data points need to be displayed on top of the boxplot. By
  discarding outliers, the axis limits will adapt to the box and
  whiskers only, not the full data range. If outliers need to be hidden
  and the axes needs to show the full data range, please use
  `outlier.shape = NA` instead.

- outlier.colour, outlier.color, outlier.fill, outlier.shape,
  outlier.size, outlier.stroke, outlier.alpha:

  Default aesthetics for outliers. Set to `NULL` to inherit from the
  data's aesthetics.

- whisker.colour, whisker.color, whisker.linetype, whisker.linewidth:

  Default aesthetics for the whiskers. Set to `NULL` to inherit from the
  data's aesthetics.

- staple.colour, staple.color, staple.linetype, staple.linewidth:

  Default aesthetics for the staples. Set to `NULL` to inherit from the
  data's aesthetics. Note that staples don't appear unless the
  `staplewidth` argument is set to a non-zero size.

- median.colour, median.color, median.linetype, median.linewidth:

  Default aesthetics for the median line. Set to `NULL` to inherit from
  the data's aesthetics.

- box.colour, box.color, box.linetype, box.linewidth:

  Default aesthetics for the boxes. Set to `NULL` to inherit from the
  data's aesthetics.

- notch:

  If `FALSE` (default) make a standard box plot. If `TRUE`, make a
  notched box plot. Notches are used to compare groups; if the notches
  of two boxes do not overlap, this suggests that the medians are
  significantly different.

- notchwidth:

  For a notched box plot, width of the notch relative to the body
  (defaults to `notchwidth = 0.5`).

- staplewidth:

  The relative width of staples to the width of the box. Staples mark
  the ends of the whiskers with a line.

- varwidth:

  If `FALSE` (default) make a standard box plot. If `TRUE`, boxes are
  drawn with widths proportional to the square-roots of the number of
  observations in the groups (possibly weighted, using the `weight`
  aesthetic).

- na.rm:

  If `FALSE`, the default, missing values are removed with a warning. If
  `TRUE`, missing values are silently removed.

- orientation:

  The orientation of the layer. The default (`NA`) automatically
  determines the orientation from the aesthetic mapping. In the rare
  event that this fails it can be given explicitly by setting
  `orientation` to either `"x"` or `"y"`. See the *Orientation* section
  for more detail.

- show.legend:

  logical. Should this layer be included in the legends? `NA`, the
  default, includes if any aesthetics are mapped. `FALSE` never
  includes, and `TRUE` always includes. It can also be a named logical
  vector to finely select the aesthetics to display. To include legend
  keys for all levels, even when no data exists, use `TRUE`. If `NA`,
  all levels are shown in legend, but unobserved levels are omitted.

- inherit.aes:

  If `FALSE`, overrides the default aesthetics, rather than combining
  with them. This is most useful for helper functions that define both
  data and aesthetics and shouldn't inherit behaviour from the default
  plot specification, e.g.
  [`annotation_borders()`](https://ggplot2.tidyverse.org/reference/annotation_borders.html).

## Value

A `Layer` ready for `ggplot2`.

## Examples

``` r
box_data <- data.frame(group = rep(c("a", "b"), each = 6), value = c(1:6, 2:7))
ggplot2::ggplot(box_data, ggplot2::aes(group, value, fill = group)) +
  geom_boxplot_webgl()
```
