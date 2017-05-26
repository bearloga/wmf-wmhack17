#!/usr/bin/env Rscript

library(plumber)

data("sentiments", package = "tidytext")
nrc <- sentiments[sentiments$lexicon == "nrc", c("word", "sentiment")]

# Create a new router
router <- plumber::plumber$new()

endpoint_expression <- expression(
  function(page_name = NULL, project = NULL, language = NULL, api = NULL) {
    return(sentimentalk::process(
      page_name, project, language, api,
      .lexicon = nrc, .format = "list",
      .silent = TRUE
    ))
  }
)

router$addEndpoint(
  verbs = c("GET", "POST"),
  path = "/analyze",
  expr = endpoint_expression,
  serializer = function(val, req, res, errorHandler) {
    tryCatch({
      json <- jsonlite::toJSON(val, auto_unbox = TRUE)
      res$setHeader("Content-Type", "application/json")
      res$body <- json
      return(res$toResponse())
    }, error = function(e) {
      errorHandler(req, res, e)
    })
  }
)

router$run(port = 8080)
