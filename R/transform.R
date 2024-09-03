
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
      tidygraph::activate(edges) |>
      tidygraph::as_tibble() |>
      dplyr::group_by(from,to) |>
      dplyr::count(stance) |>
      dplyr::rename(n_stances = n) |>
      dplyr::mutate(timestamp = max(disc_g@edgelist$timestamp))
    if(keep_only_highest){
      edgelist_agg <-
        edgelist_agg |>
        dplyr::group_by(from,to) |>
        dplyr::slice_max(n_stances)
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
