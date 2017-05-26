#' @title Parse a downloaded talk page
#' @description Parses a downloaded talk page into a tidy format with
#'   identifiers for topic and authors.
#' @param talk_page the talk page HTML code downloaded using
#'   [WikipediR::page_content]
#' @param .silent suppresses messages
#' @return A `tbl_df` (slightly fancier `data.frame`) with columns:
#' \describe{
#'   \item{topic}{identifier for linking multiple posts together}
#'   \item{post}{identifier for linking multiple rows (paragraphs) of a post together}
#'   \item{participant}{hashed name of the user who made the post, see [anonymize]}
#'   \item{text}{a paragraph from the post}
#' }
#' @export
parse_discussion <- function(talk_page, .silent = !getOption("verbose")) {
  if (!.silent) {
    message("reading fetched talk page's HTML")
  }
  talk_page <- xml2::read_html(talk_page)
  if (length(xml2::xml_find_all(talk_page, "//div[@class = 'flow-board']")) == 1) {
    if (!.silent) {
      message("parsing Flow-enabled talk page")
    }
    # Flow-enabled talk page
    # Check if empty:
    if (length(xml2::xml_find_all(talk_page, "//div[@class = 'flow-post']")) == 0) {
      stop("no posts to parse")
    } else {
      topics <- xml2::xml_find_all(talk_page, "//div[contains(@class, 'flow-topic flow-load-interactive')]")
      topic_titles <- xml2::xml_find_all(topics, ".//h2[starts-with(@class, 'flow-topic-title')]") %>%
        xml2::xml_text(trim = TRUE)
      if (!.silent) {
        message("extracting author names and post content from topics, one by one")
      }
      output <- topics %>%
        lapply(xml2::xml_find_all, xpath = ".//div[@class = 'flow-post']") %>%
        { names(.) <- topic_titles; . } %>%
        lapply(function(topic) {
          posts <- topic %>%
            xml2::xml_find_all(".//div[contains(@class, 'flow-post-main')]")
          post_content <- xml2::xml_find_all(posts, ".//div[contains(@class, 'flow-post-content')]") %>%
            lapply(xml2::xml_find_all, xpath = ".//*[self::p or self::ol or self::ul]") %>%
            lapply(xml2::xml_text, trim = TRUE) %>%
            lapply(dplyr::as_data_frame) %>%
            lapply(dplyr::rename_, .dots = list("text" = "value"))
          authors <- xml2::xml_find_all(posts, ".//span[contains(@class, 'flow-author')]") %>%
            xml2::xml_find_all(xpath = ".//a/bdi") %>%
            xml2::xml_text(trim = TRUE) %>%
            lapply(function(author) {
              return(dplyr::data_frame(author = author))
            })
          return(
            dplyr::left_join(
              dplyr::bind_rows(post_content, .id = "post"),
              dplyr::bind_rows(authors, .id = "post"),
              by = "post"
            ) %>%
              # Shuffling the order of the posts so it's more difficult to
              # connect individuals to their posts' sentiment breakdown:
              dplyr::mutate(
                post = as.numeric(post),
                post = order(runif(max(post)))[post]
              ) %>%
              dplyr::arrange(post)
          )
        }) %>%
        dplyr::bind_rows(.id = "topic") %>%
        dplyr::mutate(author = anonymize(author)) %>%
        dplyr::select(topic, post, participant = author, text)
      return(output)
    }
  } else if (length(xml2::xml_find_all(talk_page, "//div[@class = 'flow-board']")) == 0) {
    # classic talk page
    if (!.silent) {
      message("parsing classic (non-Flow) talk page")
    }
    stop("parsing for classic talk page has not been implemented yet")
    # topic_titles <- xml2::xml_find_all(talk_page, "//h2/span[@class = 'mw-headline']") %>%
    #   xml2::xml_text()
  } else {
    stop("oddly, the talk page appears to have more than one Flow board")
  }
}
