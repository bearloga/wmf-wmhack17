library(shiny)
library(shinyjs)

shinyUI(fluidPage(
  useShinyjs(),  # Include shinyjs
  titlePanel("Sentiment Analysis of Talk Pages"),
  sidebarLayout(
    sidebarPanel(
      textInput("page_name", "Page Name",
                placeholder = "Talk:Cross-wiki Search Result Improvements"),
      helpText("Page must use Flow, parser does not support classic talk pages."),
      radioButtons("source", "Source", selected = "api",
                   choices = c("API" = "api", "Project & Language" = "proj")),
      conditionalPanel("input.source == 'api'",
                       textInput("api", "URL to api.php",
                                 placeholder = "www.mediawiki.org/w/api.php")),
      conditionalPanel("input.source == 'proj'",
                       selectInput("project", "Project",
                                   choices = c("MediaWiki" = "mediawiki")),
                       selectInput("language", "Language Code",
                                   choices = c("None" = "-"))),
      fluidRow(
        column(actionButton("demo_btn", "Demo", icon = icon("eye")), align = "center", width = 6),
        column(actionButton("random_btn", "Random", icon = icon("random")), align = "center", width = 6)
      ),
      br(),
      div(actionButton("analyze_btn", "Analyze Talk Page", icon = icon("refresh")), style = "text-align: center;"),
      br(),
      div(textOutput("message"), style = "text-align: center;")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Overall Sentiment",
                 plotOutput("breakdown_overall"), icon = icon("bar-chart")),
        tabPanel("Sentiment by Topic",
                 br(),
                 fluidRow(
                   column(uiOutput("topics_container"), width = 8),
                   column(checkboxInput("topics_include", "Include \"none/other\"", TRUE), width = 4)
                 ),
                 br(),
                 plotOutput("breakdown_topic")),
        tabPanel("Sentiment by Participant",
                 br(),
                 fluidRow(
                   column(uiOutput("participants_container"), width = 8),
                   column(checkboxInput("participants_include", "Include \"none/other\"", TRUE), width = 4)
                 ),
                 br(),
                 plotOutput("breakdown_participant")),
        tabPanel("API Endpoint Usage",
                 br(),
                 p("You can access the raw output using the API endpoint:"),
                 htmlOutput("api_call"),
                 p("It will output JSON-formatted sentiment breakdown. See",
                   a("GitHub/bearloga/wmf-wmhack17/api", href = "https://github.com/bearloga/wmf-wmhack17/tree/master/api"),
                   "for more details."))
      )
    )
  ),
  theme = shinythemes::shinytheme("cosmo")
))
