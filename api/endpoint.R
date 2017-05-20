#!/usr/bin/env Rscript

library(plumber)

data("sentiments", package = "tidytext")
nrc <- sentiments[sentiments$lexicon == "nrc", c("word", "sentiment")]

# Create a new router
router <- plumber::plumber$new()

endpoint_expression <- expression(
  function(page_name = NULL, project = NULL, language = NULL, api = NULL, format = "condensed") {
    return(sentimentalk::process(
      page_name, project, language, api,
      .lexicon = nrc, .json = format,
      .format = "json", .silent = TRUE
    ))
  }
)

router$addEndpoint(
  verbs = c("GET", "POST"),
  path = "/analyze",
  expr = endpoint_expression
)

router$run(port = 8000)
