sentimentalk: Sentiment Analysis of Talk Pages as Service
================

[plumber](https://plumber.trestletech.com/)-based API for tidy sentiment analysis[1] of [MediaWiki talk pages](https://www.mediawiki.org/wiki/Help:Talk_pages) on [MediaWiki](https://www.mediawiki.org/wiki/MediaWiki)-powered websites in R.

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

``` r
sentiment_breakdown <- sentimentalk::process(
  page_name = "Talk:Cross-wiki Search Result Improvements",
  api = "www.mediawiki.org/w/api.php"
)
str(sentiment_breakdown)
```

    ## List of 2
    ##  $ status : chr "success"
    ##  $ message: chr "successfully retrieved"

### Endpoint

We start the endpoint for local use via `Rscript endpoint.R`

#### GET

``` bash
curl -s -G \
  --data-urlencode "page_name=Talk:Cross-wiki Search Result Improvements" \
  --data-urlencode "api=www.mediawiki.org/w/api.php" \
  "http://localhost:8000/analyze"
```

    ## ["{\"status\":\"success\",\"message\":\"successfully retrieved\"}"]

#### POST

``` bash
curl -s \
  --data-urlencode "page_name=Talk:Cross-wiki Search Result Improvements" \
  --data-urlencode "api=www.mediawiki.org/w/api.php" \
  "http://localhost:8000/analyze"
```

    ## ["{\"status\":\"success\",\"message\":\"successfully retrieved\"}"]

#### POST with JSON data

``` bash
curl -s \
  --data '{"page_name":"Talk:Cross-wiki Search Result Improvements", "api":"www.mediawiki.org/w/api.php"}' \
  "http://localhost:8000/analyze"
```

    ## ["{\"status\":\"success\",\"message\":\"successfully retrieved\"}"]

Additional Information
----------------------

The sentiment analysis is performed using the National Research Council Canada (NRC) Word-Emotion Association Lexicon from Saif Mohammad and Peter Turney.[2]

[1] <http://tidytextmining.com/sentiment.html>

[2] <http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm>
