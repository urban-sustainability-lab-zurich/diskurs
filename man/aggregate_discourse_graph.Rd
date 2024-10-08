% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/transform.R
\name{aggregate_discourse_graph}
\alias{aggregate_discourse_graph}
\title{Aggregate discourse graph}
\usage{
aggregate_discourse_graph(disc_g, keep_only_highest = FALSE)
}
\arguments{
\item{disc_g}{The discourse graph to aggregate}

\item{keep_only_highest}{Should only the most prevalent category of edges per actor-statement pair be kept?}
}
\value{
An object of type discourse_graph with property aggregated set to TRUE
}
\description{
Aggregate discourse graph
}
