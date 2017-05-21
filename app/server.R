library(magrittr)
library(shiny)
library(ggplot2)
library(plotly)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  page_name <- reactiveVal()
  sentiment_breakdown <- reactiveVal()

  observe({
    if (input$demo_btn > 0) {
      updateTextInput(session, "page_name", value = "Talk:Cross-wiki Search Result Improvements")
      updateRadioButtons(session, "source", selected = "api")
      updateTextInput(session, "api", value = "www.mediawiki.org/w/api.php")
    }
  })

  observe({
    if (input$analyze_btn > 0) {
      isolate({
        page_name(input$page_name)
        if (input$source == "api") {
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
      })
    }
  })

  output$n_topics <- renderText({
    if (input$analyze_btn > 0) {
      sprintf("%.0f topics parsed", length(unique(sentiment_breakdown()$topic)))
    } else {
      "press Demo and Analyze"
    }
  })

  output$breakdown_overall <- renderPlotly({
    g <- sentiment_breakdown() %>%
      dplyr::filter(sentiment != "none/other") %>%
      dplyr::group_by(sentiment) %>%
      dplyr::summarize(
        `relative expression` = round(sum(`instances of expression`)/sum(`total non-stopwords`), 4)
      ) %>%
      ggplot(aes(x = sentiment, y = `relative expression`)) +
      geom_bar(stat = "identity") +
      scale_y_continuous(labels = scales::percent_format()) +
      ggtitle("Overall relative sentiment expression",
              subtitle = page_name())
    ggplotly(g)
  })

  output$topics_container <- renderUI({
    topics <- unique(sentiment_breakdown()$topic)
    selectInput("topic", "Topic", choices = topics)
  })

  output$participants_container <- renderUI({
    participants <- unique(sentiment_breakdown()$participant)
    selectInput("participant", "Participant", choices = participants)
  })

  output$breakdown_topic <- renderPlotly({
    topic <- dplyr::filter(sentiment_breakdown(), topic == input$topic)
    total_posts <- max(topic$post)
    total_words <- sum(topic$`total non-stopwords`)
    total_participants <- length(unique(topic$participant))
    if (!input$topics_include) {
      topic <- dplyr::filter(topic, sentiment != "none/other")
    }
    relative_expression <- topic %>%
      dplyr::group_by(sentiment) %>%
      dplyr::summarize(
        `relative expression` = round(sum(`instances of expression`)/sum(`total non-stopwords`), 4)
      )
    g <- ggplot(relative_expression, aes(x = sentiment, y = `relative expression`)) +
      geom_bar(stat = "identity") +
      scale_y_continuous(labels = scales::percent_format()) +
      ggtitle("Sentiment expression within topic",
              subtitle = sprintf("%.0f word(s) across %.0f post(s) by %.0f participant(s)",
                                 total_words, total_posts, total_participants))
    ggplotly(g)
  })

  output$breakdown_participant <- renderPlotly({
    participant <- dplyr::filter(sentiment_breakdown(), participant == input$participant)
    total_posts <- max(participant$post)
    total_words <- sum(participant$`total non-stopwords`)
    total_topics <- length(unique(participant$topic))
    if (!input$participants_include) {
      participant <- dplyr::filter(participant, sentiment != "none/other")
    }
    relative_expression <- participant %>%
      dplyr::group_by(sentiment) %>%
      dplyr::summarize(
        `relative expression` = round(sum(`instances of expression`)/sum(`total non-stopwords`), 4)
      )
    g <- ggplot(relative_expression, aes(x = sentiment, y = `relative expression`)) +
      geom_bar(stat = "identity") +
      scale_y_continuous(labels = scales::percent_format()) +
      ggtitle("Sentiment expression by participant",
              subtitle = sprintf("%.0f word(s) across %.0f post(s) and %.0f topic(s)",
                                 total_words, total_posts, total_topics))
    ggplotly(g)
  })

  output$api_call <- renderUI({
    pre(sprintf("https://sentimentalk.wmflabs.org/analyze?page_name=%s&api=%s", urltools::url_encode(input$page_name), input$api))
  })

})
