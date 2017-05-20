sentimentalk: Sentiment Analysis of Talk Pages as Service
================

[plumber](https://plumber.trestletech.com/)-based API for [tidy sentiment analysis](http://tidytextmining.com/sentiment.html) of [MediaWiki talk pages](https://www.mediawiki.org/wiki/Help:Talk_pages) on [MediaWiki](https://www.mediawiki.org/wiki/MediaWiki)-powered websites in R.

-   [Usage](#usage)
    -   [Input](#input)
    -   [Output](#output)
-   [Setup](#setup)
-   [Example](#example)
    -   [R](#r)
    -   [Endpoint](#endpoint)
        -   [GET](#get)
        -   [POST](#post)
        -   [POST with input data as JSON](#post-with-input-data-as-json)
        -   [JSON output](#json-output)
-   [Additional Information](#additional-information)

Usage
-----

### Input

The API endpoint accepts the following parameters:

-   **page\_name** (starts with "Talk:")
-   **api** is used to specify the URL for the MediaWiki api.php to query
-   **project** and **language**
    -   a Wikimedia **project** such as "wikipedia" or "wikiquote"
    -   a **language** code such as "en" (English) or "de" (German)
-   **format**:
    -   "condensed" (default)
    -   "pretty" makes the output more human-friendly

**Note**: currently, classic (non-Flow) talk pages are unsupported because they are difficult to parse. As a result, if you try to supply a classic talk page, the API will yield an error message.

### Output

If the talk page has been successfully parsed and analyzed, the JSON-formatted output will be:

-   `status`: "success" or "error"
-   `message`: helpful message in case of error
-   `results`:
    -   An array of `topics`
        -   For each topic, an array of shuffled `posts` (1st post in output is not necessarily the 1st post within the topic)
            -   For each post, the following fields:
                -   `post`: identifier of the post
                -   `participant`: salted hash of the username (for anonymity)
                -   `total non-stopwords`: number of words within the post that were not [stop words](https://en.wikipedia.org/wiki/Stop_words) such as "say", "none", "than", "haven't", "sees"
                -   `sentiment expression`: proportion of words that express a particular sentiment / total non-stopwords (may sum up to greater than 1)

Setup
-----

``` r
# install.packages("devtools")
devtools::install_github("bearloga/wmf-wmhack17/sentimentalk")
```

Example
-------

To analyze [Talk:Cross-wiki Search Result Improvements on MediaWiki](https://www.mediawiki.org/wiki/Talk:Cross-wiki_Search_Result_Improvements) we need to provide the API url "www.mediawiki.org/w/api.php"

### R

`sentimentalk::process` (used by the endpoint) outputs a tidy tibble by default, which can be used to perform additional analyses in R:

``` r
sentiment_breakdown <- sentimentalk::process(
  page_name = "Talk:Cross-wiki Search Result Improvements",
  api = "www.mediawiki.org/w/api.php"
)
head(sentiment_breakdown)
```

| topic                                                                      |  post| participant                      | sentiment    |  total non-stopwords|  instances of expression|
|:---------------------------------------------------------------------------|-----:|:---------------------------------|:-------------|--------------------:|------------------------:|
| “The Plan” needs update                                                    |     1| 928266f77ada92505be8189fa708f10e | anticipation |                   10|                        1|
| “The Plan” needs update                                                    |     1| 928266f77ada92505be8189fa708f10e | none/other   |                   10|                        8|
| “The Plan” needs update                                                    |     1| 928266f77ada92505be8189fa708f10e | positive     |                   10|                        1|
| “The Plan” needs update                                                    |     2| 8a90a3c5c9df8aa7b01118299a301a08 | none/other   |                    1|                        1|
| Do we want these new search results to work across all Wikimedia projects? |     1| 446575c6def055dc79082ece2555062f | anticipation |                   37|                        2|
| Do we want these new search results to work across all Wikimedia projects? |     1| 446575c6def055dc79082ece2555062f | fear         |                   37|                        1|

### Endpoint

We start the endpoint for local use via `Rscript endpoint.R`

#### GET

``` bash
curl -s -G \
  --data-urlencode "page_name=Talk:Cross-wiki Search Result Improvements" \
  --data-urlencode "api=www.mediawiki.org/w/api.php" \
  "http://localhost:8000/analyze"
```

#### POST

``` bash
curl -s \
  --data-urlencode "page_name=Talk:Cross-wiki Search Result Improvements" \
  --data-urlencode "api=www.mediawiki.org/w/api.php" \
  "http://localhost:8000/analyze"
```

#### POST with input data as JSON

``` bash
curl -s \
  --data '{"page_name":"Talk:Cross-wiki Search Result Improvements", "api":"www.mediawiki.org/w/api.php"}' \
  "http://localhost:8000/analyze"
```

#### JSON output

**Note**: the output has been truncated.

``` json
{
  "status": "success",
  "message": "successfully retrieved",
  "results": {
    "topics": [
      {
        "topic": "“The Plan” needs update",
        "posts": [
          {
            "post": 1,
            "participant": "928266f77ada92505be8189fa708f10e",
            "total non-stopwords": 10,
            "sentiment expression": {
              "anticipation": 0.1,
              "none/other": 0.8,
              "positive": 0.1
            }
          },
          {
            "post": 2,
            "participant": "8a90a3c5c9df8aa7b01118299a301a08",
            "total non-stopwords": 1,
            "sentiment expression": {
              "none/other": 1
            }
          }
        ]
      },
      {
        "topic": "Do we want these new search results to work across all Wikimedia projects?",
        "posts": [
          {
            "post": 1,
            "participant": "633ab52b4cd7de31ff86740cd945492f",
            "total non-stopwords": 109,
            "sentiment expression": {
              "anger": 0.0092,
              "anticipation": 0.0275,
              "fear": 0.0092,
              "joy": 0.0092,
              "negative": 0.0275,
              "none/other": 0.8991,
              "positive": 0.0275, 
          ...
```

Additional Information
----------------------

The sentiment analysis is performed using the National Research Council Canada (NRC) Word-Emotion Association Lexicon from Saif Mohammad and Peter Turney ([link](http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm)).
