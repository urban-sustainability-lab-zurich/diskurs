
#' Aggregate discourse graph
#'
#' @name aggregate_discourse_graph
#' @param disc_g The discourse graph to aggregate
#' @param keep_only_highest Should only the most prevalent category of edges per actor-statement pair be kept?
#'
#' @return An object of type discourse_graph with property aggregated set to TRUE
#' @export
#'
#' @examples
aggregate_discourse_graph <- function(disc_g,keep_only_highest = FALSE){
  if (disc_g@aggregated){
    stop("discourse graph is already aggregated")
  }
  else{
    tbl_g <- disc_g@graph
    edgelist_agg <-
      tbl_g |>
      tidygraph::activate(rlang::.data$edges) |>
      tidygraph::as_tibble() |>
      dplyr::group_by(rlang::.data$from,rlang::.data$to) |>
      dplyr::count(rlang::.data$stance) |>
      dplyr::rename(n_stances = rlang::.data$n) |>
      dplyr::mutate(timestamp = max(disc_g@edgelist$timestamp))
    if(keep_only_highest){
      edgelist_agg <-
        edgelist_agg |>
        dplyr::group_by(rlang::.data$from,rlang::.data$to) |>
        dplyr::slice_max(rlang::.data$n_stances)
    }
    disc_g_aggregated <-
      discourse_graph(
        nodelist = disc_g@nodelist,
        edgelist = edgelist_agg,
        aggregated = TRUE
      )
    return(disc_g_aggregated)
  }
}

#' Time-slice graph
#'
#' @param disc_g Discourse graph object
#' @param start_date The beginning of the time slice in a format convertible by lubridate::as_date
#' @param end_date The end of the time slice in a format convertible by lubridate::as_date
#'
#' @return A discourse graph object subset to include only edges within the time slice given by start_date and end_date
#' @export
#'
#' @examples
time_slice_graph <- function(disc_g,
                             start_date,
                             end_date){
  if (is.discourse_graph(disc_g)){
    tbl_g <- disc_g@graph
    tbl_g_subset <-
      tbl_g |>
      tidygraph::activate(rlang::.data$edges) |>
      dplyr::filter(rlang::.data$timestamp > lubridate::as_date(start_date) &
                      rlang::.data$timestamp < lubridate::as_date(end_date))

    disc_g_subset <-
      discourse_graph(
        get_nodelist(tbl_g_subset),
        get_edgelist(tbl_g_subset)
      )

    return(disc_g_subset)
  }
}
