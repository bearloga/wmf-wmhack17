# Sentiment Analysis of Talk Pages

> Words, words, words. (_Hamlet_, [Act II Scene II](https://en.wikisource.org/wiki/The_Tragedy_of_Hamlet,_Prince_of_Denmark/Act_2#Scene_2._A_room_in_the_castle.))

[App](app/) &amp; [API](api/) for sentiment analysis of MediaWiki talk pages made during [Wikimedia Hackathon 2017](https://www.mediawiki.org/wiki/Wikimedia_Hackathon_2017) in Vienna.

__Author:__ Mikhail Popov (Wikimedia Foundation)<br/> 
__License:__ [MIT](http://opensource.org/licenses/MIT)<br/>
__Status:__ Active

## Progress

- [x] API endpoint
    - [x] Download talk page
    - [x] Parse talk page
        - [ ] Parse classic talk pages (really hard)
        - [x] Parse [Flow](https://www.mediawiki.org/wiki/Extension:Flow)-enabled talk pages
    - [x] Tidy sentiment analysis
    - [x] Anonymize and summarize
    - [x] Output
- [x] Shiny companion app
    - [x] User inputs
    - [x] Show data and behind-the-scenes code
        - [x] Show API call
        - [ ] Show JSON output
    - [x] Data visualization

## Additional Information

Please note that this project is released with a [Contributor Code of Conduct](https://github.com/bearloga/wmf-wmhack17/blob/master/CONDUCT.md). By participating in this project you agree to abide by its terms.

### Future Work

One possible application of the service is using to calculate some sort of a "discussion civility score" based on the various sentiments expressed and the relative expressions of those sentiments.
