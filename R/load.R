
SUPPORTED_STANCE_CLASSES <- c("support","opposition","irrelevant")

prop_edgelist_df <- S7::new_property(class = S7::class_data.frame,
                                          validator = function(value){
                                            # validate correct column names
                                            if (!("from" %in% colnames(value))){
                                              "edgelist must contain a integer column named from"
                                            } else if (!("to" %in% colnames(value))){
                                              "edgelist must contain a integer column named to"
                                            } else if (all(value$to %in% value$from)) {
                                              "network must be bipartite. no nodes in edgelist column from may be in column to"
                                            } else if (!("stance" %in% colnames(value))){
                                              "edgelist must contain a character column named stance"
                                            } else if (!("timestamp" %in% colnames(value))){
                                              "edgelist must contain a date column named timestamp"
                                            }
                                            # validate correct column types
                                            else if (!(is.numeric(value$from))){
                                              "edgelist column from must be a list of node ids as integers"
                                            } else if (!(is.numeric(value$to))){
                                              "edgelist column to must be a list of node ids as integers"
                                            } else if (!(is.character(value$stance))){
                                              "edgelist column stance must be a list of stances as characters"
                                            } else if(!(all(value$stance %in% SUPPORTED_STANCE_CLASSES))){
                                              glue::glue('Only stance classes {paste(SUPPORTED_STANCE_CLASSES, collapse = ", ")}
                                                         are supported')
                                            } else if("timestamp" %in% colnames(value)){
                                              if(!(lubridate::is.Date(value$timestamp))){
                                                "timestamp needs to be of class date. maybe convert with lubridate::as_date()?"
                                              }
                                            }
                                          }
                                     )

discourse_edgelist <- S7::new_class("discourse_edgelist",
                                    properties = list(
                                      edgelist = prop_edgelist_df
                                    ))

prop_nodelist_df <- S7::new_property(class = S7::class_data.frame,
                                     validator = function(value){
                                       if (!("nodeid" %in% colnames(value))){
                                         "nodelist must contain a integer column named nodeid"
                                       } else if (!("name" %in% colnames(value))){
                                         "nodelist must contain a integer column named name"
                                       } else if (all(duplicated(value$name))){
                                         "all entries in nodelist column name must be unique"
                                       } else if (!("label" %in% colnames(value))){
                                         "nodelist must contain a character column named label"
                                       } else if (!("mode" %in% colnames(value))){
                                         "nodelist must contain a character column named mode"
                                       } else if (!(is.numeric(value$nodeid))){
                                         "nodelist column nodeid must be a list of node ids as integers"
                                       } else if(!(all(value$mode %in% c("actor","statement")))){
                                         glue::glue('Nodes need to be either actor or statement in column mode')
                                       }
                                     })

discourse_nodelist <- S7::new_class("discourse_nodelist",
                                    properties = list(
                                      nodelist = prop_nodelist_df
                                    ))

discourse_graph <- S7::new_class(name = "discourse_graph",
                                 properties = list(
                                   nodelist = prop_nodelist_df,
                                   edgelist = prop_edgelist_df,
                                   aggregated = S7::new_property(S7::class_logical, default = FALSE),
                                   graph = S7::new_property(
                                     class = S7::new_S3_class("tbl_graph"),
                                     getter = function(self){
                                       tidygraph::tbl_graph(nodes = self@nodelist,
                                                            edges = self@edgelist,
                                                            directed = TRUE)
                                     },
                                     setter = function(self,value){
                                       self@edgelist <- get_edgelist(value)
                                       self@nodelist <- get_nodelist(value)
                                       self
                                     }
                                   )
                                 ))

# the generic for getting edgelists from graphs, with one function argument g:
get_edgelist <- S7::new_generic("get_edgelist","g")

S7::method(get_edgelist, discourse_graph) <- function(g){
  g@edgelist
}

S7::method(get_edgelist, S7::new_S3_class("tbl_graph")) <- function(g){
  g |>
    tidygraph::activate(edges) |>
    tidygraph::as_tibble()
}

# the generic for getting nodelists from graphs, with one function argument g:
get_nodelist <- S7::new_generic("get_nodelist","g")

# the method for discourse_graph
S7::method(get_nodelist, discourse_graph) <- function(g){
  g@nodelist
}

S7::method(get_nodelist, S7::new_S3_class("tbl_graph")) <- function(g){
  g |>
    tidygraph::activate(nodes) |>
    tidygraph::as_tibble()
}


#' Load discourse graph from nodelist of actors/ statements and edgelist of expressed stances
#'
#' @param nodelist A data frame containing the following columns:
#' nodeid: integer vector of unique node identifiers
#' name: a unique name assigned to a node
#' label: the label of the node
#' mode: one of 'actor' or 'statement'
#' @param edgelist An edgelist specifying qualified relations between actors and statements.
#' Takes the form of a data frame containing the following columns:
#' from: actor node ids expressing stances
#' to: statement node ids toward which statements are expressed
#' stance: One of 'support', 'opposition' or 'irrelevant', capturing the qualifier for the stance expression
#' timestamp: A timestamp given the time the stance was expressed
#' @return A discourse graph object
#' @export
#'
#' @examples diskurs::load_discourse_graph(diskurs::nodelist_example,diskurs::edgelist_example)
load_discourse_graph <- function(nodelist, edgelist){
    return(
      discourse_graph(
        nodelist = nodelist,
        edgelist = edgelist
      )
    )
  }

# the generic for getting igraph, with one function argument g:
get_igraph <- S7::new_generic("get_igraph","g")

# The method implementation of get_igraph for the discourse_graph class:

#' Extract igraph object from discourse graph
#'
#' @name get_igraph
#' @param g The discourse graph to extract igraph object from
#'
#' @return An object of class igraph
#' @export
#'
#' @examples
S7::method(get_igraph, discourse_graph) <- function(g){
  g@graph |> tidygraph::as.igraph()
}

# the generic for getting a tbl_graph, with one function argument g:
get_tbl_graph <- S7::new_generic("get_tbl_graph","g")

# The method implementation of get_tbl_graph for the discourse_graph class:

#' Extract tidygraph object from discourse graph
#'
#' @param g The discourse graph to extract tidygraph object from
#' @name get_tbl_graph
#'
#' @return An object of class tidygraph
#' @export
#'
#' @examples
S7::method(get_tbl_graph, discourse_graph) <- function(g){
  g@graph
}

#' Check if object is of type discourse_graph
#'
#' @param object The object to evaluate
#'
#' @return boolean
#' @export
#'
#' @examples is.discourse_graph(diskurs::discourse_graph_example)
is.discourse_graph <- function(object){
  if ("discourse_graph" %in% class(object)){
    return(TRUE)
  }
  else{
    return(FALSE)
  }
}

#' Print method for discourse graph objects
#'
#' @param x A discourse graph object
#'
#' @return
#' @export
#'
#' @examples
S7::method(print,discourse_graph) <- function(x){
  if(x@aggregated){
    aggregated_status <- " aggregated"
  } else {
    aggregated_status <- ""
  }
  print(
    glue::glue("\n   ---------------------------------------- \n A{aggregated_status} discourse graph with {nrow(x@nodelist[x@nodelist$mode == 'actor',])} actors and {nrow(x@nodelist[x@nodelist$mode == 'statement',])}
               statements \n   ----------------------------------------")
  )
  print(x@graph)
}

#' Get incidence matrix of discourse graph
#'
#' @param disc_g A discourse graph object
#' @param make_binary Logical. Dichotomize/ make binary? Defaults to FALSE, which returns a valued matrix with the number of stances in entries.
#'
#' @return
#' @export
#'
#' @examples
get_incmat <- function(disc_g, make_binary = FALSE){
  g <- disc_g@graph
  edgelist <-
    g |>
    tidygraph::activate(edges) |>
    dplyr::mutate(actor_id = tidygraph::.N()$name[from]) |>
    dplyr::mutate(belief_id = tidygraph::.N()$name[to]) |>
    tidygraph::as_tibble() |>
    dplyr::group_by(actor_id,belief_id) |>
    dplyr::summarise(
      n_stances = dplyr::n()
    )
  unique_actors <- g |>
    tidygraph::activate(nodes) |>
    dplyr::filter(mode == "actor") |>
    dplyr::pull(name)
  unique_statements <- g |>
    tidygraph::activate(nodes) |>
    dplyr::filter(mode == "statement") |>
    dplyr::pull(name)
  incmat <- matrix(0,
                   nrow = length(unique_actors),
                   ncol = length(unique_statements),
                   dimnames = list(
                     unique_actors,
                     unique_statements
                   ))
  if(make_binary){
    edgelist$n_stances <- 1
  }
  incmat[cbind(
    edgelist$actor_id,
    edgelist$belief_id)] <- edgelist$n_stances
  #remove isolates?
  return(incmat)
}
