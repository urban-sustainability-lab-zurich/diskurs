nodelist_example <- tibble::tibble(
  nodeid = c(1:5),
  name = c("actor1","actor2","actor3","statement1","statement2"),
  label = c("Actor 1","Actor 2","Actress 3","The fascists will lose","Owls are great"),
  mode = c("actor","actor","actor","statement","statement")
)

edgelist_example = tibble::tibble(
  from = c(1,1,1,1,2,3,3),
  to = c(4,4,5,4,5,4,5),
  stance = c("support",
             "support",
             "irrelevant",
             "support",
             "opposition",
             "support",
             "support"),
  timestamp = lubridate::as_datetime(c("2012-02-01T00:00:00Z",
                "2013-02-01T00:00:00Z",
                "2014-02-01T00:00:00Z",
                "2014-04-01T00:00:00Z",
                "2016-02-01T00:00:00Z",
                "2016-02-01T00:00:00Z",
                "2016-03-01T00:00:00Z"))
)

usethis::use_data(nodelist_example, overwrite = TRUE)
usethis::use_data(edgelist_example, overwrite = TRUE)
