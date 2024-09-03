
<!-- README.md is generated from README.Rmd. Please edit that file -->

# diskurs

<!-- badges: start -->
<!-- badges: end -->

⚠️ This package is at a very early stage of development ⚠️

diskurs (German for discourse) is an R package to handle data on
discourse networks in a very specific form.

The main goal of the package is to ensure validated data loading and
basic transformations of discourse in graph structure as introduced in
the [sustainability.discourses](sustainability.discourses.ch) project.

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

# Basic functionality

``` r
library(diskurs)
```

## Required data format

``` r
example_edgelist <- diskurs::edgelist_example
example_nodelist <- diskurs::nodelist_example
```

``` r
example_edgelist
#>   from to     stance  timestamp
#> 1    1  4    support 2012-02-01
#> 2    1  4    support 2013-02-01
#> 3    1  5 irrelevant 2014-02-01
#> 4    1  4    support 2014-04-01
#> 5    2  5 opposition 2016-02-01
#> 6    3  4    support 2016-02-01
#> 7    3  5    support 2016-03-01
```

``` r
example_nodelist
#>   nodeid       name                  label      mode
#> 1      1     actor1                Actor 1     actor
#> 2      2     actor2                Actor 2     actor
#> 3      3     actor3              Actress 3     actor
#> 4      4 statement1 The fascists will lose statement
#> 5      5 statement2         Owls are great statement
```

## Creating a discourse graph

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
#>  .. $ :<environment: 0x000002284f9ad438> 
#>  .. - attr(*, "active")= chr "nodes"
```

Let’s look at it:

``` r
disc_g |> plot()
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />

In many cases, working with the igraph or tidygraph object is advisable

``` r
disc_g |> get_igraph()
#> IGRAPH 42e95d5 DN-- 5 7 -- 
#> + attr: nodeid (v/n), name (v/c), label (v/c), mode (v/c), stance
#> | (e/c), timestamp (e/n)
#> + edges from 42e95d5 (vertex names):
#> [1] actor1->statement1 actor1->statement1 actor1->statement2 actor1->statement1
#> [5] actor2->statement2 actor3->statement1 actor3->statement2
```

This makes it possible to use the entire ecosystem provided by igraph…

``` r
disc_g |> 
  get_igraph() |> 
  plot()
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="100%" />

… or tidygraph.

``` r
disc_g |> 
  get_tbl_graph() |> 
  tidygraph::activate(nodes) |>
  dplyr::mutate(closeness = tidygraph::centrality_closeness())
#> # A tbl_graph: 5 nodes and 7 edges
#> #
#> # A directed acyclic multigraph with 1 component
#> #
#> # A tibble: 5 × 5
#>   nodeid name       label                  mode      closeness
#>    <int> <chr>      <chr>                  <chr>         <dbl>
#> 1      1 actor1     Actor 1                actor           0.5
#> 2      2 actor2     Actor 2                actor           1  
#> 3      3 actor3     Actress 3              actor           0.5
#> 4      4 statement1 The fascists will lose statement     NaN  
#> 5      5 statement2 Owls are great         statement     NaN  
#> #
#> # A tibble: 7 × 4
#>    from    to stance     timestamp 
#>   <int> <int> <chr>      <date>    
#> 1     1     4 support    2012-02-01
#> 2     1     4 support    2013-02-01
#> 3     1     5 irrelevant 2014-02-01
#> # ℹ 4 more rows
```

## Aggregating a graph

Aggregating a discourse graph here means combining stance edges to
weighted edges over time, possibly also keeping only the most prevalent
category.

``` r
disc_g |> aggregate_discourse_graph()
#> <discourse_graph>
#>  @ nodelist  : tibble [5 × 4] (S3: tbl_df/tbl/data.frame)
#>  $ nodeid: int [1:5] 1 2 3 4 5
#>  $ name  : chr [1:5] "actor1" "actor2" "actor3" "statement1" ...
#>  $ label : chr [1:5] "Actor 1" "Actor 2" "Actress 3" "The fascists will lose" ...
#>  $ mode  : chr [1:5] "actor" "actor" "actor" "statement" ...
#>  @ edgelist  : gropd_df [5 × 5] (S3: grouped_df/tbl_df/tbl/data.frame)
#>  $ from     : int [1:5] 1 1 2 3 3
#>  $ to       : int [1:5] 4 5 5 4 5
#>  $ stance   : chr [1:5] "support" "irrelevant" "opposition" "support" ...
#>  $ n_stances: int [1:5] 3 1 1 1 1
#>  $ timestamp: Date[1:5], format: "2016-03-01" "2016-03-01" ...
#>  - attr(*, "groups")= tibble [5 × 3] (S3: tbl_df/tbl/data.frame)
#>   ..$ from : int [1:5] 1 1 2 3 3
#>   ..$ to   : int [1:5] 4 5 5 4 5
#>   ..$ .rows: list<int> [1:5] 
#>   .. ..$ : int 1
#>   .. ..$ : int 2
#>   .. ..$ : int 3
#>   .. ..$ : int 4
#>   .. ..$ : int 5
#>   .. ..@ ptype: int(0) 
#>   ..- attr(*, ".drop")= logi TRUE
#>  @ aggregated: logi TRUE
#>  @ graph     :Classes 'tbl_graph', 'igraph'  hidden list of 10
#>  .. $ : num 5
#>  .. $ : logi TRUE
#>  .. $ : num [1:5] 0 0 1 2 2
#>  .. $ : num [1:5] 3 4 4 3 4
#>  .. $ : num [1:5] 0 1 2 3 4
#>  .. $ : num [1:5] 0 3 1 2 4
#>  .. $ : num [1:6] 0 2 3 5 5 5
#>  .. $ : num [1:6] 0 0 0 0 2 5
#>  .. $ :List of 4
#>  ..  ..$ : num [1:3] 1 0 1
#>  ..  ..$ : Named list()
#>  ..  ..$ :List of 4
#>  ..  .. ..$ nodeid: int [1:5] 1 2 3 4 5
#>  ..  .. ..$ name  : chr [1:5] "actor1" "actor2" "actor3" "statement1" ...
#>  ..  .. ..$ label : chr [1:5] "Actor 1" "Actor 2" "Actress 3" "The fascists will lose" ...
#>  ..  .. ..$ mode  : chr [1:5] "actor" "actor" "actor" "statement" ...
#>  ..  ..$ :List of 3
#>  ..  .. ..$ stance   : chr [1:5] "support" "irrelevant" "opposition" "support" ...
#>  ..  .. ..$ n_stances: int [1:5] 3 1 1 1 1
#>  ..  .. ..$ timestamp: Date[1:5], format: "2016-03-01" ...
#>  .. $ :<environment: 0x0000022853cfe0c8> 
#>  .. - attr(*, "active")= chr "nodes"
```

``` r
disc_g |> aggregate_discourse_graph(keep_only_highest = TRUE) |> plot()
```

<img src="man/figures/README-unnamed-chunk-12-1.png" width="100%" />

## Time slice of discourse graph

``` r
start_date <- "2012-01-01"
end_date <- "2014-06-06"
disc_g |> 
  time_slice_graph(start_date = start_date, end_date = end_date) |> 
  get_tbl_graph()
#> # A tbl_graph: 5 nodes and 4 edges
#> #
#> # A directed acyclic multigraph with 3 components
#> #
#> # A tibble: 5 × 4
#>   nodeid name       label                  mode     
#>    <int> <chr>      <chr>                  <chr>    
#> 1      1 actor1     Actor 1                actor    
#> 2      2 actor2     Actor 2                actor    
#> 3      3 actor3     Actress 3              actor    
#> 4      4 statement1 The fascists will lose statement
#> 5      5 statement2 Owls are great         statement
#> #
#> # A tibble: 4 × 4
#>    from    to stance     timestamp 
#>   <int> <int> <chr>      <date>    
#> 1     1     4 support    2012-02-01
#> 2     1     4 support    2013-02-01
#> 3     1     5 irrelevant 2014-02-01
#> # ℹ 1 more row
```

``` r
disc_g |> 
  time_slice_graph(start_date = start_date, end_date = end_date) |> 
  plot()
```

<img src="man/figures/README-unnamed-chunk-14-1.png" width="100%" />
