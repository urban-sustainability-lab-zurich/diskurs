
<!-- README.md is generated from README.Rmd. Please edit that file -->

# diskurs

<!-- badges: start -->
<!-- badges: end -->

diskurs (German for discourse) is an R package to handle data on
discourse networks in a very specific form.

The main goal of the package is to ensure validated data loading and
basic transformations of discourse in graph structure as introduced in
the (sustainability.discourses)\[sustainability.discourses\] project.

At the moment, it mainly exists to facilitate the reproduction of
analyses conducted within the
[sustainability.discourses](sustainability.discourses.ch) project. The
eventual goal is to hopefully support anyone working with a similar data
structure in the future.

`diskurs` is in most cases a thin wrapper or special use case around
[tidygraph](https://tidygraph.data-imaginist.com) and
[igraph](https://igraph.org).

## Installation

You can install the development version of diskurs from [the r-universe
builds of
diskurs](https://urban-sustainability-lab-zurich.r-universe.dev/diskurs)
with:

``` r
install.packages('diskurs', repos = c('https://urban-sustainability-lab-zurich.r-universe.dev', 'https://cloud.r-project.org'))
```

## Getting started

Create a discourse graph object from an edgelist and nodelist:

``` r
library(diskurs)
#> Warning: [S7] Failed to find generic aggregate() in package base
```

``` r
example_edgelist <- diskurs::edgelist_example
example_nodelist <- diskurs::nodelist_example
```

``` r
disc_g <- load_discourse_graph(edgelist = example_edgelist, nodelist = example_nodelist)
disc_g
#> <discourse_graph>
#>  @ nodelist  : tibble [5 × 4] (S3: tbl_df/tbl/data.frame)
#>  $ nodeid: int [1:5] 1 2 3 4 5
#>  $ name  : chr [1:5] "actor1" "actor2" "actor3" "statement1" ...
#>  $ label : chr [1:5] "Actor 1" "Actor 2" "Actress 3" "The fascists will lose" ...
#>  $ mode  : chr [1:5] "actor" "actor" "actor" "statement" ...
#>  @ edgelist  : tibble [7 × 4] (S3: tbl_df/tbl/data.frame)
#>  $ from     : num [1:7] 1 1 1 1 2 3 3
#>  $ to       : num [1:7] 4 4 5 4 5 4 5
#>  $ stance   : chr [1:7] "support" "support" "irrelevant" "support" ...
#>  $ timestamp: Date[1:7], format: "2012-02-01" "2013-02-01" ...
#>  @ aggregated: logi FALSE
#>  @ graph     :Classes 'tbl_graph', 'igraph'  hidden list of 10
#>  .. $ : num 5
#>  .. $ : logi TRUE
#>  .. $ : num [1:7] 0 0 0 0 1 2 2
#>  .. $ : num [1:7] 3 3 4 3 4 3 4
#>  .. $ : num [1:7] 3 1 0 2 4 5 6
#>  .. $ : num [1:7] 3 1 0 5 2 4 6
#>  .. $ : num [1:6] 0 4 5 7 7 7
#>  .. $ : num [1:6] 0 0 0 0 4 7
#>  .. $ :List of 4
#>  ..  ..$ : num [1:3] 1 0 1
#>  ..  ..$ : Named list()
#>  ..  ..$ :List of 4
#>  ..  .. ..$ nodeid: int [1:5] 1 2 3 4 5
#>  ..  .. ..$ name  : chr [1:5] "actor1" "actor2" "actor3" "statement1" ...
#>  ..  .. ..$ label : chr [1:5] "Actor 1" "Actor 2" "Actress 3" "The fascists will lose" ...
#>  ..  .. ..$ mode  : chr [1:5] "actor" "actor" "actor" "statement" ...
#>  ..  ..$ :List of 2
#>  ..  .. ..$ stance   : chr [1:7] "support" "support" "irrelevant" "support" ...
#>  ..  .. ..$ timestamp: Date[1:7], format: "2012-02-01" ...
#>  .. $ :<environment: 0x000002c1015f29a0> 
#>  .. - attr(*, "active")= chr "nodes"
```

More functionality is documented in the vignettes on:

- [Basic functionality](vignettes/basics.html)
