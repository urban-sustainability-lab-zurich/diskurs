#' Plot discourse graph
#'
#' @name plot
#' @param disc_g A discourse graph object
#' @param layout_choice Layout choice to pass to ggraph. Defaults to "kk"
#' @param label_nodes Logical: should nodes be labelled? Defaults to TRUE
#' @param edge_alpha Transparency of edges. Defaults to 1
#' @param arrow_start_cap Space from arrow start cap. Defaults to 6.
#' @param arrow_end_cap Space from end of arrow. Defaults to 10.
#'
#' @return
#' @export
#'
#' @examples
S7::method(plot,discourse_graph) <- function(disc_g,
                                 layout_choice = "kk",
                                 label_nodes = TRUE,
                                 edge_alpha = 1,
                                 arrow_start_cap = 6,
                                 arrow_end_cap = 10){
  tbl_g <- disc_g@graph
  # start viz
  viz <-
    tbl_g |>
    tidygraph::activate(nodes) |>
    dplyr::mutate(isolate = tidygraph::node_is_isolated()) |>
    dplyr::filter(!(isolate)) |>
    tidygraph::activate(edges) |>
    dplyr::mutate(stance = factor(stance, levels = c("support","opposition","irrelevant"))) |>
    ggraph::ggraph(layout = layout_choice)

  if(disc_g@aggregated == FALSE){
    viz <- viz +
      ggraph::geom_edge_fan(ggplot2::aes(color = stance),
                    arrow = ggplot2::arrow(length = ggplot2::unit(4, 'mm')),
                    start_cap = ggraph::circle(arrow_start_cap, 'mm'),
                    end_cap = ggraph::circle(arrow_end_cap, 'mm'),
                    width = 1,
                    alpha = edge_alpha)
  }
  if(disc_g@aggregated){
    edge_width_scale_ticks <-
      c(
        tbl_g |> tidygraph::activate(edges) |> dplyr::pull(n_stances) |> min(),
        tbl_g |> tidygraph::activate(edges) |> dplyr::pull(n_stances) |> max()
      )
    viz <- viz +
      ggraph::geom_edge_fan(ggplot2::aes(color = stance,
                                         width = n_stances),
                            arrow = ggplot2::arrow(length = ggplot2::unit(4, 'mm')),
                            start_cap = ggraph::circle(arrow_start_cap, 'mm'),
                            end_cap = ggraph::circle(arrow_end_cap, 'mm'),
                            alpha = edge_alpha) +
      ggraph::scale_edge_width("Number of stances expressed",
                       range = c(1,3),
                       breaks = edge_width_scale_ticks)
  }
  if(!label_nodes){
    viz <-
      viz +
      ggraph::geom_node_point(aes(color = mode))
  }
  else{
    viz <-
      viz +
      ggraph::geom_node_label(ggplot2::aes(label = name,
                                           color = mode),
                              size = 2)
  }
  viz +
    ggraph::scale_edge_color_manual("Stance edge qualifier",
                            values = c(
                              "irrelevant" = "lightgrey",
                              "support" = "darkgreen",
                              "opposition" = "red"
                            )) +
    ggplot2::scale_color_manual("Node type",
                       values = c(
                         "statement" = "black",
                         "actor" = "darkgrey",
                         "imaginary" = "blue"
                       )) +
    # ggplot2::scale_size_manual("Node type",
    #                   values = c(
    #                     "statement" = 1.5,
    #                     "actor" = 1,
    #                     "imaginary" = 5
    #                   )) +
    ggraph::theme_graph() +
    ggplot2::coord_cartesian(clip = 'off')
}
