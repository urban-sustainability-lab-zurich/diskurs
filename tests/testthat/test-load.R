# Test discourse graph construction
# Following R package best practices with testthat

# Setup test data and expected values (DRY principle) ----
# Define once, use throughout all tests

# Test data
test_nodelist <- tibble::tibble(
  nodeid = c(1:5),
  name = c("actor1", "actor2", "actor3", "statement1", "statement2"),
  label = c("Actor 1", "Actor 2", "Actress 3", "Statement 1", "Statement 2"),
  mode = c("actor", "actor", "actor", "statement", "statement")
)

test_edgelist <- tibble::tibble(
  from = c(1, 1, 2, 3),
  to = c(4, 5, 4, 5),
  stance = c("support", "opposition", "support", "irrelevant"),
  timestamp = lubridate::as_date(c(
    "2020-01-01",
    "2020-02-01",
    "2020-03-01",
    "2020-04-01"
  ))
)

# Expected dimensions
EXPECTED_N_NODES <- 5
EXPECTED_N_EDGES <- 4
EXPECTED_N_ACTORS <- 3
EXPECTED_N_STATEMENTS <- 2

# Expected column names
EXPECTED_NODELIST_COLS <- c("nodeid", "name", "label", "mode")
EXPECTED_EDGELIST_COLS <- c("from", "to", "stance", "timestamp")

# Package example data dimensions (when available)
EXPECTED_EXAMPLE_N_NODES <- 5
EXPECTED_EXAMPLE_N_EDGES <- 7

# Test basic graph construction ----
test_that("load_discourse_graph creates a discourse_graph object", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  expect_s3_class(g, "discourse_graph")
  expect_true(is.discourse_graph(g))
})

test_that("discourse_graph contains correct nodelist", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  expect_equal(nrow(g@nodelist), EXPECTED_N_NODES)
  expect_true(all(EXPECTED_NODELIST_COLS %in% colnames(g@nodelist)))
  expect_equal(g@nodelist$nodeid, test_nodelist$nodeid)
})

test_that("discourse_graph contains correct edgelist", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  expect_equal(nrow(g@edgelist), EXPECTED_N_EDGES)
  expect_true(all(EXPECTED_EDGELIST_COLS %in% colnames(g@edgelist)))
  expect_equal(g@edgelist$from, test_edgelist$from)
})

test_that("discourse_graph aggregated property defaults to FALSE", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  expect_false(g@aggregated)
})

# Test graph property getter ----
test_that("graph property returns a tbl_graph object", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  graph_obj <- g@graph
  expect_s3_class(graph_obj, "tbl_graph")
})

test_that("graph property has correct number of nodes and edges", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  graph_obj <- g@graph

  nodes <- graph_obj |>
    tidygraph::activate(nodes) |>
    tidygraph::as_tibble()

  edges <- graph_obj |>
    tidygraph::activate(edges) |>
    tidygraph::as_tibble()

  expect_equal(nrow(nodes), EXPECTED_N_NODES)
  expect_equal(nrow(edges), EXPECTED_N_EDGES)
})

# Test with example data from package ----
test_that("load_discourse_graph works with package example data", {
  # Load package example data
  data("edgelist_example", package = "diskurs", envir = environment())
  data("nodelist_example", package = "diskurs", envir = environment())

  g <- load_discourse_graph(
    edgelist = edgelist_example,
    nodelist = nodelist_example
  )

  expect_s3_class(g, "discourse_graph")
  expect_true(is.discourse_graph(g))

  # Verify correct dimensions
  expect_equal(nrow(g@nodelist), EXPECTED_EXAMPLE_N_NODES)
  expect_equal(nrow(g@edgelist), EXPECTED_EXAMPLE_N_EDGES)

  # Verify the graph property works
  expect_s3_class(g@graph, "tbl_graph")
})

# Test get_edgelist generic ----
test_that("get_edgelist returns edgelist from discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  retrieved_edgelist <- get_edgelist(g)

  expect_equal(nrow(retrieved_edgelist), EXPECTED_N_EDGES)
  expect_true(all(EXPECTED_EDGELIST_COLS %in% colnames(retrieved_edgelist)))
})

test_that("get_edgelist works on tbl_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  tbl_g <- g@graph
  retrieved_edgelist <- get_edgelist(tbl_g)

  expect_true(is.data.frame(retrieved_edgelist))
  expect_true(nrow(retrieved_edgelist) > 0)
})

# Test get_nodelist generic ----
test_that("get_nodelist returns nodelist from discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  retrieved_nodelist <- get_nodelist(g)

  expect_equal(nrow(retrieved_nodelist), EXPECTED_N_NODES)
  expect_true(all(EXPECTED_NODELIST_COLS %in% colnames(retrieved_nodelist)))
})

test_that("get_nodelist works on tbl_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  tbl_g <- g@graph
  retrieved_nodelist <- get_nodelist(tbl_g)

  expect_true(is.data.frame(retrieved_nodelist))
  expect_equal(nrow(retrieved_nodelist), EXPECTED_N_NODES)
})

# Test get_tbl_graph ----
test_that("get_tbl_graph extracts tbl_graph from discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  tbl_g <- get_tbl_graph(g)

  expect_s3_class(tbl_g, "tbl_graph")
})

# Test get_igraph ----
test_that("get_igraph extracts igraph from discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  ig <- get_igraph(g)

  expect_s3_class(ig, "igraph")
  expect_equal(igraph::vcount(ig), EXPECTED_N_NODES)
  expect_equal(igraph::ecount(ig), EXPECTED_N_EDGES)
})

# Test validation: edgelist ----
test_that("edgelist validation catches missing 'from' column", {
  bad_edgelist <- test_edgelist
  bad_edgelist$from <- NULL

  expect_error(
    load_discourse_graph(nodelist = test_nodelist, edgelist = bad_edgelist),
    "from"
  )
})

test_that("edgelist validation catches missing 'to' column", {
  bad_edgelist <- test_edgelist
  bad_edgelist$to <- NULL

  expect_error(
    load_discourse_graph(nodelist = test_nodelist, edgelist = bad_edgelist),
    "to"
  )
})

test_that("edgelist validation catches missing 'stance' column", {
  bad_edgelist <- test_edgelist
  bad_edgelist$stance <- NULL

  expect_error(
    load_discourse_graph(nodelist = test_nodelist, edgelist = bad_edgelist),
    "stance"
  )
})

test_that("edgelist validation catches missing 'timestamp' column", {
  bad_edgelist <- test_edgelist
  bad_edgelist$timestamp <- NULL

  expect_error(
    load_discourse_graph(nodelist = test_nodelist, edgelist = bad_edgelist),
    "timestamp"
  )
})

test_that("edgelist validation catches invalid stance values", {
  bad_edgelist <- test_edgelist
  bad_edgelist$stance[1] <- "invalid_stance"

  expect_error(
    load_discourse_graph(nodelist = test_nodelist, edgelist = bad_edgelist),
    "support.*opposition.*irrelevant"
  )
})

test_that("edgelist validation catches non-date timestamp", {
  bad_edgelist <- test_edgelist
  bad_edgelist$timestamp <- as.character(bad_edgelist$timestamp)

  expect_error(
    load_discourse_graph(nodelist = test_nodelist, edgelist = bad_edgelist),
    "date"
  )
})

# Test validation: nodelist ----
test_that("nodelist validation catches missing 'nodeid' column", {
  bad_nodelist <- test_nodelist
  bad_nodelist$nodeid <- NULL

  expect_error(
    load_discourse_graph(nodelist = bad_nodelist, edgelist = test_edgelist),
    "nodeid"
  )
})

test_that("nodelist validation catches missing 'name' column", {
  bad_nodelist <- test_nodelist
  bad_nodelist$name <- NULL

  expect_error(
    load_discourse_graph(nodelist = bad_nodelist, edgelist = test_edgelist),
    "name"
  )
})

test_that("nodelist validation catches missing 'label' column", {
  bad_nodelist <- test_nodelist
  bad_nodelist$label <- NULL

  expect_error(
    load_discourse_graph(nodelist = bad_nodelist, edgelist = test_edgelist),
    "label"
  )
})

test_that("nodelist validation catches missing 'mode' column", {
  bad_nodelist <- test_nodelist
  bad_nodelist$mode <- NULL

  expect_error(
    load_discourse_graph(nodelist = bad_nodelist, edgelist = test_edgelist),
    "mode"
  )
})

test_that("nodelist validation catches invalid mode values", {
  bad_nodelist <- test_nodelist
  bad_nodelist$mode[1] <- "invalid_mode"

  expect_error(
    load_discourse_graph(nodelist = bad_nodelist, edgelist = test_edgelist),
    "actor.*statement"
  )
})

# Test print method ----
test_that("print method works for discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  expect_output(print(g), "discourse graph")
  expect_output(print(g), "actors")
  expect_output(print(g), "statements")
})

# Test is.discourse_graph ----
test_that("is.discourse_graph correctly identifies discourse_graph objects", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  expect_true(is.discourse_graph(g))
})

test_that("is.discourse_graph returns FALSE for non-discourse_graph objects", {
  expect_false(is.discourse_graph(test_nodelist))
  expect_false(is.discourse_graph(test_edgelist))
  expect_false(is.discourse_graph(list()))
  expect_false(is.discourse_graph(NULL))
})

# Test end-to-end workflow ----
test_that("complete workflow works as expected", {
  # This tests the exact use case from the issue
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Can access all components
  expect_s3_class(g, "discourse_graph")
  expect_s3_class(g@graph, "tbl_graph")
  expect_true(is.data.frame(g@nodelist))
  expect_true(is.data.frame(g@edgelist))

  # Can extract tbl_graph and igraph
  tbl_g <- get_tbl_graph(g)
  ig <- get_igraph(g)

  expect_s3_class(tbl_g, "tbl_graph")
  expect_s3_class(ig, "igraph")

  # Graph has correct structure
  expect_equal(igraph::vcount(ig), EXPECTED_N_NODES)
  expect_equal(igraph::ecount(ig), EXPECTED_N_EDGES)
})

test_that("graph property getter creates tbl_graph correctly", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Access graph multiple times - should work consistently
  graph1 <- g@graph
  graph2 <- g@graph

  expect_s3_class(graph1, "tbl_graph")
  expect_s3_class(graph2, "tbl_graph")

  # Should have same structure
  expect_equal(igraph::vcount(graph1), igraph::vcount(graph2))
  expect_equal(igraph::ecount(graph1), igraph::ecount(graph2))
})

test_that("methods work on tbl_graph extracted from discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  tbl_g <- get_tbl_graph(g)

  # get_edgelist should work on tbl_graph
  edges_from_tbl <- get_edgelist(tbl_g)
  expect_true(is.data.frame(edges_from_tbl))
  expect_equal(nrow(edges_from_tbl), EXPECTED_N_EDGES)

  # get_nodelist should work on tbl_graph
  nodes_from_tbl <- get_nodelist(tbl_g)
  expect_true(is.data.frame(nodes_from_tbl))
  expect_equal(nrow(nodes_from_tbl), EXPECTED_N_NODES)
})
