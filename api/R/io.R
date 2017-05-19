#' @title Complete sentiment analysis pipeline
#' @description Outputs sentiment breakdown of (currently English) comments
#'   either as a list for use in R or as a JSON string for use as an endpoint.
#' @param page_name the title of the page you want to retrieve
#' @param project project you wish to query, if appropriate (e.g. "wikiquote")
#' @param language language code of the project you wish to query,
#'   if appropriate (e.g. "de" for German)
#' @param api as an alternative to a `language` and `project` combination
#'   (e.g. "wiki.mozilla.org/api.php" or "www.gutenberg.org/w/api.php")
#' @param format "json" when used in an endpoint or "list" (default) if using
#'   this function in R
#' @param lexicon lexicon object provided by [tidytext::get_sentiments]
#' @export
process <- function(
  page_name = NULL,
  project = NULL,
  language = NULL,
  api = NULL,
  format = "list",
  lexicon = NULL
) {
  if (is.null(page_name)) {
    output <- list(
      status = "error",
      message = "need: page_name",
      results = NA
    )
    if (format == "json") {
      return(jsonlite::toJSON(output, pretty = FALSE, auto_unbox = TRUE))
    } else if (format == "list") {
      return(output)
    }
  }
  if (!is.null(api)) {
    tryCatch({
      result <- WikipediR::page_content(
        page_name = page_name,
        domain = api,
        as_wikitext = FALSE
      )
    }, error = function(e) {
      msg <<- e
    }, finally = {
      result <<- NULL
    })
  } else if (!is.null(project) && !is.null(language)) {
    tryCatch({
      result <- WikipediR::page_content(
        page_name = page_name,
        project = project,
        language = language,
        as_wikitext = FALSE
      )
    }, error = function(e) {
      msg <<- e
    }, finally = {
      result <<- NULL
    })
  } else {
    result <- NULL
    msg <- "need: 'api' (e.g. 'www.mediawiki.org/w/api.php') or 'project' (e.g. 'wikiquote') & 'language' code (e.g. 'de' for German)"
  }
  if (!is.null(result)) {
    output <- list(
      status = "success",
      message = "successfully retrieved"
    )
    if (is.null(lexicon)) {
      data("sentiments", package = "tidytext")
      lexicon <- sentiments[sentiments$lexicon == "nrc", c("word", "sentiment")]
    }
    output$results <- result %>%
      parse_discussion(talk_page = .) %>%
      analyze(tidy_page = ., lexicon = lexicon)
  } else {
    output <- list(
      status = "error",
      message = msg,
      results = NA
    )
  }
  if (format == "json") {
    return(jsonlite::toJSON(output, pretty = FALSE, auto_unbox = TRUE))
  } else if (format == "list") {
    return(output)
  }
}
