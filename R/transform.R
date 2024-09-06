
utils::globalVariables(".data")

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
aggregate_discourse_graph <- function(disc_g,
                                      keep_only_highest = FALSE){
  if (disc_g@aggregated){
    stop("discourse graph is already aggregated")
  }
  else{
    tbl_g <- disc_g@graph
    edgelist_agg <-
      tbl_g |>
      tidygraph::activate(edges) |>
      tidygraph::as_tibble() |>
      dplyr::group_by(.data$from,.data$to) |>
      dplyr::count(.data$stance) |>
      dplyr::rename(n_stances = n) |>
      dplyr::mutate(timestamp = max(disc_g@edgelist$timestamp))
    if(keep_only_highest){
      edgelist_agg <-
        edgelist_agg |>
        dplyr::group_by(.data$from,.data$to) |>
        dplyr::slice_max(.data$n_stances)
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
      tidygraph::activate(edges) |>
      dplyr::filter(.data$timestamp > lubridate::as_date(start_date) &
                      .data$timestamp < lubridate::as_date(end_date))

    disc_g_subset <-
      discourse_graph(
        get_nodelist(tbl_g_subset),
        get_edgelist(tbl_g_subset)
      )

    return(disc_g_subset)
  }
}

#' Remove isolates from discourse graph object
#'
#' @param disc_g A discourse graph object
#'
#' @return A discourse graph object with isolated nodes (actors with no expressed stances or statements with no refering stances) removed
#' @export
#'
#' @examples
remove_isolates <- function(disc_g){
  tbl_g <- disc_g@graph
  tbl_g_noisolates <-
    tbl_g |>
    tidygraph::activate(nodes) |>
    dplyr::filter(!tidygraph::node_is_isolated())
  disc_g_noisolates <-
    discourse_graph(
      get_nodelist(tbl_g_noisolates),
      get_edgelist(tbl_g_noisolates)
    )
  return(disc_g_noisolates)
}

#' Create a list of time-sliced graphs
#'
#' @param disc_g A discourse graph object
#' @param time_window The slice window as a time period object, eg. created with months(48)
#' @param step_interval The step interval for time slices. Defaults to "month".
#' @param date_range Character vector of length 2 with a start and end date coercible to date by lubridate::as_date()
#' @param aggregate Logical. Aggregate the time sliced graphs? Defaults to FALSE.
#' @param remove_isolates Logical. Remove isolates per time slices? Defaults to FALSE.
#' @param keep_only_highest Logical. If aggregate is TRUE, keep only most prevalent stance category per time slice? Defaults to FALSE.
#'
#' @return
#' @export
#'
#' @examples
time_sliced_graph_list <- function(disc_g,
                                   time_window,
                                   date_range,
                                   step_interval = "month",
                                   aggregate = FALSE,
                                   remove_isolates = FALSE,
                                   keep_only_highest = FALSE){

  time_window_halved <- time_window/2
  date_slices <- seq(min(lubridate::as_date(date_range)),
                     by = step_interval,
                     to = lubridate::as_date(max(date_range)))

  graph_slices_list <-
    pbapply::pblapply(date_slices,
                      function(date_slice){
                        disc_g |>
                          diskurs::time_slice_graph(
                            start_date = lubridate::`%m-%`(lubridate::as_date(date_slice), time_window_halved),
                            end_date = lubridate::`%m+%`(lubridate::as_date(date_slice), time_window_halved))
                      })
  if(remove_isolates){
    graph_slices_list <-
      lapply(graph_slices_list,
             function(graph_slice){
               graph_slice |>
                 remove_isolates()
             })
  }
  if(!aggregate){
    names(graph_slices_list) <- date_slices
    return(graph_slices_list)
  }
  if(aggregate){
    agg_graph_slices_list <-
      lapply(graph_slices_list,
             aggregate_discourse_graph, keep_only_highest)
    names(agg_graph_slices_list) <- date_slices
    return(agg_graph_slices_list)
  }
}

#' Explode discourse graph (make statement nodes qualified)
#'
#'This function "explodes" a discourse graph, making all statement nodes into qualified nodes.
#'
#' @param disc_g A discourse graph object
#' @param stance_subset Character vector of stance classes. Restrict explosion to a specific set of stance classes only? Defaults to all supported.
#'
#' @return
#' @export
#'
#' @examples
explode_graph <- function(disc_g,
                          stance_subset = SUPPORTED_STANCE_CLASSES){

  g <- disc_g@graph
  edgelist_exploded <-
    g |>
    tidygraph::activate(edges) |>
    dplyr::filter(stance %in% stance_subset) |>
    dplyr::mutate(actor_id =  tidygraph::.N()$name[from]) |>
    dplyr::mutate(statement_id =  tidygraph::.N()$name[to]) |>
    tidygraph::as_tibble() |>
    dplyr::select(-from,-to) |>
    dplyr::rowwise() |>
    dplyr::mutate(statement_stance_id = paste(statement_id,stance,sep = "_")) |>
    dplyr::ungroup() |>
    dplyr::relocate(actor_id,statement_stance_id)
  new_statement_nodes <-
    tibble::tibble(
      name = unique(edgelist_exploded$statement_stance_id),
      mode = "statement",
      label = name
    )
  nodelist_actors <- g |>
    get_nodelist() |>
    dplyr::filter(mode != "statement")
  nodelist_exploded <-
    nodelist_actors |>
    dplyr::bind_rows(new_statement_nodes) |>
    dplyr::arrange(nodeid)
  highest_nodeid <- max(nodelist_exploded$nodeid, na.rm = TRUE)
  new_nodeids <- c(nodelist_exploded$nodeid[!is.na(nodelist_exploded$nodeid)],c(highest_nodeid + 1:sum(is.na(nodelist_exploded$nodeid))))
  nodelist_exploded_new <-
    nodelist_exploded |>
    dplyr::mutate(nodeid = new_nodeids)
  edgelist_exploded_new <-
    edgelist_exploded |>
    dplyr::left_join(nodelist_exploded_new,
                     dplyr::join_by(actor_id == name)) |>
    dplyr::select(actor_id,stance,statement_stance_id,stance,timestamp,nodeid) |>
    dplyr::rename(from = nodeid) |>
    dplyr::left_join(nodelist_exploded_new,
                     dplyr::join_by(statement_stance_id == name)) |>
    dplyr::select(from,stance,statement_stance_id,stance,timestamp,nodeid) |>
    dplyr::rename(to = nodeid) |>
    dplyr::select(-statement_stance_id)
  disc_g_exploded <-
    discourse_graph(
      nodelist_exploded_new,
      edgelist = edgelist_exploded_new
    )
  return(disc_g_exploded)
}
