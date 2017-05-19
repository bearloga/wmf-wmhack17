#' @title Perform a sentiment analysis of a parsed, tidy talk page
#' @description Uses an emotion lexicon to output a breakdown of sentiments
#'   expressed.
#' @param tidy_page the output from [parse_discussion]
#' @param lexicon lexicon object provided by [tidytext::get_sentiments]
#' @export
analyze <- function(tidy_page, lexicon) {
  return(invisible(NULL))
}
