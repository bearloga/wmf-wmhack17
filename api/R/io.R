#' @title Complete sentiment analysis pipeline
#' @description Outputs sentiment breakdown of (currently English) comments
#'   either as a list for use in R or as a JSON string for use as an endpoint.
#' @param page_name the title of the page you want to retrieve
#' @param project project you wish to query, if appropriate (e.g. "wikiquote")
#' @param language language code of the project you wish to query,
#'   if appropriate (e.g. "de" for German)
#' @param api as an alternative to a `language` and `project` combination
#'   (e.g. "wiki.mozilla.org/api.php" or "www.gutenberg.org/w/api.php")
#' @param .lexicon lexicon object provided by [tidytext::get_sentiments]
#' @param .format "list" when used in an endpoint or "df" (default) if using
#'   this function in R
#' @param .silent suppresses messages
#' @examples \dontrun{
#' process(
#'   page_name = "Talk:Cross-wiki Search Result Improvements",
#'   api = "www.mediawiki.org/w/api.php",
#'   .silent = FALSE
#' )
#'
#' # Classic talk pages don't work yet:
#' process(
#'   page_name = "Talk:Wikimedia_Foundation",
#'   project = "wikipedia", language = "en",
#' )
#' }
#' @export
process <- function(
  page_name = NULL,
  project = NULL,
  language = NULL,
  api = NULL,
  .lexicon = NULL,
  .format = "df",
  .silent = !getOption("verbose")
) {
  msg <- ""
  if (is.null(page_name)) {
    output <- list(
      status = "error",
      message = "need: page_name",
      results = NA
    )
    return(output)
  }
  if (!is.null(api)) {
    if (!.silent) {
      message("fetching '", page_name, "' from '", api, "'")
    }
    tryCatch({
      result <- WikipediR::page_content(
        page_name = page_name,
        domain = api,
        as_wikitext = FALSE
      )$parse$text$`*`
    }, error = function(e) {
      msg <<- as.character(e)
    }, finally = {
      result <<- NULL
    })
  } else if (!is.null(project) && !is.null(language)) {
    if (!.silent) {
      message("fetching '", page_name, "' from '", language, ".", project, "'")
    }
    tryCatch({
      result <- WikipediR::page_content(
        page_name = page_name,
        project = project,
        language = language,
        as_wikitext = FALSE
      )$parse$text$`*`
    }, error = function(e) {
      msg <<- as.character(e)
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
      message = "successfully retrieved",
      results = NA
    )
    if (is.null(.lexicon)) {
      if (!.silent) {
        message("loading NRC emotion lexicon")
      }
      data("sentiments", package = "tidytext")
      .lexicon <- sentiments[sentiments$lexicon == "nrc", c("word", "sentiment")]
    }
    tryCatch({
      foo <- function(x, y) {
        z <- as.list(x)
        names(z) <- y
        return(z)
      }
      if (!.silent) {
        message("processing the fetched talk page (parsing and analyzing)")
      }
      sentiment_breakdown <- result %>%
        parse_discussion(talk_page = ., .silent = .silent) %>%
        analyze(parsed_talk = ., lexicon = .lexicon, .silent = .silent)
      if (!.silent) {
        message("received analyzed sentiment data")
      }
      if (.format == "list") {
        if (!.silent) {
          message("performing additional data wrangling for optimal JSON output")
        }
        output$results <<- sentiment_breakdown %>%
          dplyr::group_by(topic, post, participant) %>%
          tidyr::nest(.key = "sentiments") %>%
          dplyr::mutate(
            `total non-stopwords` = purrr::map_int(sentiments, ~ unique(.$total_non_stop_words)),
            `sentiment expression` = purrr::map(sentiments, ~ foo(.$relative_expression, .$sentiment))
          ) %>%
          dplyr::select(-sentiments) %>%
          dplyr::group_by(topic) %>%
          tidyr::nest(.key = "posts") %>%
          { list(topics = .) }
      } else {
        if (!.silent) {
          message("returning a nice and tidy dataset")
        }
        output$results <<- sentiment_breakdown %>%
          dplyr::select(
            topic, post, participant, sentiment,
            `total non-stopwords` = total_non_stop_words,
            `instances of expression` = instances
          )
      }
    }, error = function(e) {
      message("encountered an issue")
      output$status <<- "error"
      output$message <<- as.character(e)
    })
  } else {
    output <- list(
      status = "error",
      message = msg,
      results = NA
    )
  }
  if (.format == "list") {
    return(output)
  } else if (.format == "df") {
    return(output$results)
  }
}
