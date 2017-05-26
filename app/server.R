library(magrittr)
library(shiny)
library(shinyjs)
library(ggplot2)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  setBookmarkExclude(c("demo", "topics_include", "participants_include"))

  msg <- reactiveVal()
  page_name <- reactiveVal()
  sentiment_breakdown <- reactiveVal()
  endpoint_output <- reactiveVal()

  observe({
    updateTextInput(session, "page_name", value = input$demo)
    updateRadioButtons(session, "source", selected = "proj")
    updateTextInput(session, "project", value = "mediawiki")
    updateTextInput(session, "api", value = "www.mediawiki.org/w/api.php")
  })

  observe({
    if (input$random_btn > 0) {
      updateRadioButtons(session, "source", selected = "proj")
      updateTextInput(session, "project", value = "mediawiki")
      updateTextInput(session, "api", value = "www.mediawiki.org/w/api.php")
      msg("...checking random page for Flow...")
      isolate({
        flow_disabled <- TRUE
        while (flow_disabled) {
          random_page <- WikipediR::random_page(domain = "www.mediawiki.org/w/api.php", namespaces = 1, as_wikitext = TRUE)[[1]]
          if (grepl('^\\{"flow-workflow"\\:', random_page$wikitext$`*`)) {
            flow_disabled <- FALSE
          }
        }
        msg("found a valid random page")
        updateTextInput(session, "page_name", value = random_page$title)
        runjs('$("button#analyze_btn").trigger("click")')
      })
    }
  })

  observe({
    if (input$analyze_btn > 0) {
      msg("...downloading and parsing talk page...")
      isolate({
        page_name(input$page_name)
        results <- NULL
        tryCatch({
          if (input$source == "proj" && input$project == "mediawiki") {
            results <- sentimentalk::process(
              page_name = input$page_name,
              api = "www.mediawiki.org/w/api.php"
            )
          } else if (input$source == "api") {
            results <- sentimentalk::process(
              page_name = input$page_name,
              api = input$api
            )
          } else {
            results <- sentimentalk::process(
              page_name = input$page_name,
              project = input$project,
              language = input$language
            )
          }
          sentiment_breakdown(results)
          msg(sprintf("%.0f topics parsed", length(unique(results$topic))))
          endpoint_output(NULL)
        }, error = function(e) {
          msg("encountered an issue")
        })
      })
    }
  })

  output$message <- renderText({
    msg()
  })

  output$breakdown_overall <- renderPlot({
    sentiment_data <- sentiment_breakdown()
    isolate({
      sentiment_data %>%
        dplyr::filter(sentiment != "none/other") %>%
        dplyr::group_by(sentiment) %>%
        dplyr::summarize(
          `relative expression` = round(sum(`instances of expression`)/sum(`total non-stopwords`), 4)
        ) %>%
        ggplot(aes(x = sentiment, y = `relative expression`)) +
        geom_bar(stat = "identity") +
        scale_y_continuous(labels = scales::percent_format()) +
        ggtitle("Overall relative sentiment expression",
                subtitle = page_name()) +
        theme_minimal(base_size = 14)
    })
  })

  output$topics_container <- renderUI({
    selectInput("topic", "Topic", choices = unique(sentiment_breakdown()$topic))
  })

  output$participants_container <- renderUI({
    selectInput("participant", "Participant", choices = unique(sentiment_breakdown()$participant))
  })

  output$breakdown_topic <- renderPlot({
    topic <- dplyr::filter(sentiment_breakdown(), topic == input$topic)
    total_posts <- max(topic$post)
    total_words <- sum(topic$`total non-stopwords`)
    total_participants <- length(unique(topic$participant))
    if (!input$topics_include) {
      topic <- dplyr::filter(topic, sentiment != "none/other")
    }
    isolate({
      relative_expression <- topic %>%
        dplyr::group_by(sentiment) %>%
        dplyr::summarize(
          `relative expression` = round(sum(`instances of expression`)/sum(`total non-stopwords`), 4)
        )
      ggplot(relative_expression, aes(x = sentiment, y = `relative expression`)) +
        geom_bar(stat = "identity") +
        scale_y_continuous(labels = scales::percent_format()) +
        ggtitle("Sentiment expression within topic",
                subtitle = sprintf("%.0f word(s) across %.0f post(s) by %.0f participant(s)",
                                   total_words, total_posts, total_participants)) +
        theme_minimal(base_size = 14)
    })
  })

  output$breakdown_participant <- renderPlot({
    participant <- dplyr::filter(sentiment_breakdown(), participant == input$participant)
    total_posts <- max(participant$post)
    total_words <- sum(participant$`total non-stopwords`)
    total_topics <- length(unique(participant$topic))
    if (!input$participants_include) {
      participant <- dplyr::filter(participant, sentiment != "none/other")
    }
    isolate({
      relative_expression <- participant %>%
        dplyr::group_by(sentiment) %>%
        dplyr::summarize(
          `relative expression` = round(sum(`instances of expression`)/sum(`total non-stopwords`), 4)
        )
      ggplot(relative_expression, aes(x = sentiment, y = `relative expression`)) +
        geom_bar(stat = "identity") +
        scale_y_continuous(labels = scales::percent_format()) +
        ggtitle("Sentiment expression by participant",
                subtitle = sprintf("%.0f word(s) across %.0f post(s) and %.0f topic(s)",
                                   total_words, total_posts, total_topics)) +
        theme_minimal(base_size = 14)
    })
  })

  output$api_call <- renderUI({
    pre(sprintf("https://sentimentalk.wmflabs.org/analyze?page_name=%s&api=%s", urltools::url_encode(input$page_name), input$api))
  })

  output$api_output <- renderText({
    endpoint_output()
  })

  observe({
    if (input$use_api > 0) {
      isolate({
        result <- httr::GET(
          "https://sentimentalk.wmflabs.org/analyze",
          query = list(
            page_name = input$page_name,
            api = input$api
          ),
          httr::user_agent("https://bearloga.shinyapps.io/sentimentalkr")
        )
        tryCatch({
          httr::stop_for_status(result)
          endpoint_output(jsonlite::prettify(httr::content(result, as = "text", encoding = "UTF-8")))
        },
        error = function(e) {
          msg(as.character(e))
        })
      })
    }
  })

})
