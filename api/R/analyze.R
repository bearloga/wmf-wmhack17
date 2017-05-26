#' @title Perform a sentiment analysis of a parsed, tidy talk page
#' @description Uses an emotion lexicon to output a breakdown of sentiments
#'   expressed.
#' @param tidy_page the output from [parse_discussion]
#' @param lexicon lexicon object provided by [tidytext::get_sentiments]
#' @param .silent suppresses messages
#' @export
analyze <- function(parsed_talk, lexicon, .silent = TRUE) {
  if (!.silent) {
    message("tokenizing and counting words (for repetitions)")
  }
  tidy_posts <- parsed_talk %>%
    tidytext::unnest_tokens(word, text) %>%
    dplyr::anti_join(tidytext::stop_words, by = "word") %>%
    dplyr::group_by(topic, post, participant, word) %>%
    dplyr::count() %>%
    dplyr::ungroup()
  if (!.silent) {
    message("joining with emotion lexicon")
  }
  tidy_sentiments <- tidy_posts %>%
    dplyr::left_join(lexicon, by = "word")
  tidy_sentiments$sentiment[is.na(tidy_sentiments$sentiment)] <- "none/other"
  if (!.silent) {
    message("counting non-stopwords by topic, post, and participant")
  }
  tidy_counts <- tidy_posts %>%
    dplyr::group_by(topic, post, participant) %>%
    dplyr::summarize(total_non_stop_words = sum(n))
  if (!.silent) {
    message("calculating relative expression of sentiments")
  }
  tidy_expressions <- tidy_sentiments %>%
    dplyr::group_by(topic, post, participant, sentiment) %>%
    dplyr::summarize(n = sum(n)) %>%
    dplyr::ungroup() %>%
    dplyr::select(topic, post, participant, sentiment, instances = n) %>%
    dplyr::left_join(tidy_counts, by = c("topic", "post", "participant")) %>%
    dplyr::mutate(relative_expression = round(instances/total_non_stop_words, 4))
  if (!.silent) {
    message("returning analyzed data to processing pipeline")
  }
  return(tidy_expressions)
}
