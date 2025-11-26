# Test tidygraph inheritance and API compatibility
# Tests that discourse_graph objects work with tidygraph verbs

# Setup test data ----
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

# Test basic tidygraph API: activate ----
test_that("discourse_graph can be activated on nodes", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should be able to activate nodes context
  g_activated <- g |> tidygraph::activate(nodes)

  expect_true(any(grepl("tbl_graph", class(g_activated))))
})

test_that("discourse_graph can be activated on edges", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should be able to activate edges context
  g_activated <- g |> tidygraph::activate(edges)

  expect_true(any(grepl("tbl_graph", class(g_activated))))
})

# Test tidygraph API: filtering ----
test_that("can filter nodes on discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Filter to only actor nodes
  g_filtered <- g |>
    tidygraph::activate(nodes) |>
    dplyr::filter(mode == "actor")

  nodes <- g_filtered |> tidygraph::as_tibble("nodes")

  expect_equal(nrow(nodes), 3)
  expect_true(all(nodes$mode == "actor"))
})

test_that("can filter edges on discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Filter to only support stances
  g_filtered <- g |>
    tidygraph::activate(edges) |>
    dplyr::filter(stance == "support")

  edges <- g_filtered |> tidygraph::as_tibble("edges")

  expect_equal(nrow(edges), 2)
  expect_true(all(edges$stance == "support"))
})

# Test tidygraph API: mutate ----
test_that("can mutate nodes on discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Add a new column to nodes
  g_mutated <- g |>
    tidygraph::activate(nodes) |>
    dplyr::mutate(is_actor = mode == "actor")

  nodes <- g_mutated |> tidygraph::as_tibble("nodes")

  expect_true("is_actor" %in% colnames(nodes))
  expect_equal(sum(nodes$is_actor), 3)
})

test_that("can mutate edges on discourse_graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Add a new column to edges
  g_mutated <- g |>
    tidygraph::activate(edges) |>
    dplyr::mutate(is_support = stance == "support")

  edges <- g_mutated |> tidygraph::as_tibble("edges")

  expect_true("is_support" %in% colnames(edges))
  expect_equal(sum(edges$is_support), 2)
})

# Test with package example data ----
test_that("tidygraph verbs work with package example data", {
  data("edgelist_example", package = "diskurs", envir = environment())
  data("nodelist_example", package = "diskurs", envir = environment())

  g <- load_discourse_graph(
    edgelist = edgelist_example,
    nodelist = nodelist_example
  )

  # Test activate and filter chain
  g_filtered <- g |>
    tidygraph::activate(edges) |>
    dplyr::filter(stance == "support")

  edges <- g_filtered |> tidygraph::as_tibble("edges")

  expect_true(all(edges$stance == "support"))
  expect_true(nrow(edges) > 0)
})

# Test that modifications return appropriate objects ----
test_that("tidygraph operations preserve tbl_graph class", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  g_modified <- g |>
    tidygraph::activate(nodes) |>
    dplyr::filter(mode == "actor") |>
    tidygraph::activate(edges) |>
    dplyr::filter(stance == "support")

  # Should still be a tbl_graph
  expect_true(any(grepl("tbl_graph", class(g_modified))))
})

# Test as_tibble extraction ----
test_that("can extract tibbles from discourse_graph using tidygraph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Extract nodes
  nodes <- g |> tidygraph::as_tibble("nodes")
  expect_true(is.data.frame(nodes))
  expect_equal(nrow(nodes), 5)

  # Extract edges
  edges <- g |> tidygraph::as_tibble("edges")
  expect_true(is.data.frame(edges))
  expect_equal(nrow(edges), 4)
})

# Test chaining multiple operations ----
test_that("can chain multiple tidygraph operations", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Complex chain: activate, filter, mutate
  result <- g |>
    tidygraph::activate(nodes) |>
    dplyr::mutate(name_upper = toupper(name)) |>
    dplyr::filter(mode == "actor") |>
    tidygraph::activate(edges) |>
    dplyr::filter(stance != "irrelevant")

  nodes <- result |> tidygraph::as_tibble("nodes")
  edges <- result |> tidygraph::as_tibble("edges")

  expect_true("name_upper" %in% colnames(nodes))
  expect_true(all(nodes$mode == "actor"))
  expect_true(all(edges$stance %in% c("support", "opposition")))
})
