# Test transformation and plotting functions
# These tests ensure that internal functions using extract_tbl_graph work correctly

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

# Test aggregate_discourse_graph ----
test_that("aggregate_discourse_graph works and uses tidygraph internally", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should not error when using tidygraph verbs internally
  g_agg <- aggregate_discourse_graph(g)

  expect_true(is.discourse_graph(g_agg))
  expect_true(g_agg@aggregated)
  expect_true("n_stances" %in% colnames(g_agg@edgelist))
})

test_that("aggregate_discourse_graph errors on already aggregated graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  g_agg <- aggregate_discourse_graph(g)

  expect_error(aggregate_discourse_graph(g_agg), "already aggregated")
})

# Test time_slice_graph ----
test_that("time_slice_graph works and uses tidygraph internally", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should not error when using tidygraph verbs internally
  g_sliced <- time_slice_graph(g,
                                start_date = "2020-01-15",
                                end_date = "2020-03-15")

  expect_true(is.discourse_graph(g_sliced))
  # Should have filtered edges
  expect_true(nrow(g_sliced@edgelist) < nrow(g@edgelist))
  # All timestamps should be in range
  expect_true(all(g_sliced@edgelist$timestamp > lubridate::as_date("2020-01-15")))
  expect_true(all(g_sliced@edgelist$timestamp < lubridate::as_date("2020-03-15")))
})

# Test remove_isolates ----
test_that("remove_isolates works and uses tidygraph internally", {
  # Create a graph with an isolated node
  nodelist_with_isolate <- rbind(
    test_nodelist,
    tibble::tibble(
      nodeid = 6,
      name = "isolated",
      label = "Isolated Node",
      mode = "actor"
    )
  )

  g <- load_discourse_graph(nodelist = nodelist_with_isolate,
                             edgelist = test_edgelist)

  # Should not error when using tidygraph verbs internally
  g_no_isolates <- remove_isolates(g)

  expect_true(is.discourse_graph(g_no_isolates))
  # Should have removed the isolated node
  expect_true(nrow(g_no_isolates@nodelist) < nrow(g@nodelist))
})

# Test explode_graph ----
test_that("explode_graph works and uses tidygraph internally", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should not error when using tidygraph verbs internally
  exploded <- explode_graph(g)

  # explode_graph returns a discourse_graph (bipartite projection)
  expect_true(is.discourse_graph(exploded))
})

test_that("explode_graph can filter by stance", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  exploded_support <- explode_graph(g, stance_subset = c("support"))

  # Should return a discourse_graph with only support edges
  expect_true(is.discourse_graph(exploded_support))
  expect_true(all(exploded_support@edgelist$stance == "support"))
})

# Test get_incmat ----
test_that("get_incmat works and uses tidygraph internally", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should not error when using tidygraph verbs internally
  incmat <- get_incmat(g)

  expect_true(is.matrix(incmat))
  expect_equal(nrow(incmat), 3) # 3 actors
  expect_equal(ncol(incmat), 2) # 2 statements
})

test_that("get_incmat binary option works", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  incmat_binary <- get_incmat(g, make_binary = TRUE)

  expect_true(all(incmat_binary %in% c(0, 1)))
})

# Test plot method ----
test_that("plot method works and uses tidygraph internally", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Should not error when using tidygraph verbs internally
  # Plot returns a ggplot object
  expect_silent(p <- plot(g))
  expect_true(inherits(p, "ggplot"))
})

test_that("plot method works with aggregated graph", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)
  g_agg <- aggregate_discourse_graph(g)

  # Should not error
  expect_silent(p <- plot(g_agg))
  expect_true(inherits(p, "ggplot"))
})

test_that("plot method respects label_nodes parameter", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Both should work without error
  expect_silent(p1 <- plot(g, label_nodes = TRUE))
  expect_silent(p2 <- plot(g, label_nodes = FALSE))

  expect_true(inherits(p1, "ggplot"))
  expect_true(inherits(p2, "ggplot"))
})

# Test with package example data ----
test_that("transformation functions work with package example data", {
  data("edgelist_example", package = "diskurs", envir = environment())
  data("nodelist_example", package = "diskurs", envir = environment())

  g <- load_discourse_graph(
    edgelist = edgelist_example,
    nodelist = nodelist_example
  )

  # All transformations should work without error
  expect_silent(g_agg <- aggregate_discourse_graph(g))
  expect_silent(g_sliced <- time_slice_graph(g, "2012-01-01", "2015-01-01"))
  expect_silent(g_no_iso <- remove_isolates(g))
  expect_silent(exploded <- explode_graph(g))
  expect_silent(incmat <- get_incmat(g))
  expect_silent(p <- plot(g))

  # All should return appropriate types
  expect_true(is.discourse_graph(g_agg))
  expect_true(is.discourse_graph(g_sliced))
  expect_true(is.discourse_graph(g_no_iso))
  expect_true(is.discourse_graph(exploded))
  expect_true(is.matrix(incmat))
  expect_true(inherits(p, "ggplot"))
})

# Test that extract_tbl_graph helper works correctly ----
test_that("internal extract_tbl_graph preserves tbl_graph functionality", {
  g <- load_discourse_graph(nodelist = test_nodelist, edgelist = test_edgelist)

  # Extract using the internal helper (via get_tbl_graph)
  tbl_g <- get_tbl_graph(g)

  # Should be able to use tidygraph verbs on extracted graph
  expect_silent(
    result <- tbl_g |>
      tidygraph::activate(nodes) |>
      dplyr::filter(mode == "actor")
  )

  expect_true(inherits(result, "tbl_graph"))
})
