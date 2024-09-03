
SUPPORTED_STANCE_CLASSES <- c("support","opposition","irrelevant")

# TODO: check timestamp class and set to default terry pratchett birthday if not present
prop_edgelist_df <- S7::new_property(class = S7::class_data.frame,
                                          validator = function(value){
                                            if (!("from" %in% colnames(value))){
                                              "edgelist must contain a integer column named from"
                                            } else if (!("to" %in% colnames(value))){
                                              "edgelist must contain a integer column named to"
                                            } else if (!("stance" %in% colnames(value))){
                                              "edgelist must contain a character column named stance"
                                            } else if (!(is.numeric(value$from))){
                                              "edgelist column from must be a list of node ids as integers"
                                            } else if (!(is.numeric(value$to))){
                                              "edgelist column to must be a list of node ids as integers"
                                            } else if (!(is.character(value$stance))){
                                              "edgelist column stance must be a list of stances as characters"
                                            } else if(!(all(value$stance %in% SUPPORTED_STANCE_CLASSES))){
                                              glue::glue('Only stance classes {paste(SUPPORTED_STANCE_CLASSES, collapse = ", ")}
                                                         are supported')
                                            } #else if("timestamp" %in% colnames(value)){
                                              #if(!(lubridate::is.Date(value$timestamp))){
                                              #  "timestamp needs to be of class date"
                                              #}
                                            #}
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
                                   graph = S7::new_property(
                                     getter = function(self){
                                       tidygraph::tbl_graph(nodes = self@nodelist,
                                                            edges = self@edgelist,
                                                            directed = TRUE)
                                     }
                                   )
                                 ))

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
#' @examples diskurs::load_discourse_graph(diskurs::nodelist,diskurs::edgelist)
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
