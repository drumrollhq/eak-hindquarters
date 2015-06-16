require! {'twitter': Twitter}

export setup = ({config}) ->
  exports.glitterquiff = Promise.promisify-all new Twitter {
    consumer_key: config.CARDS_TWITTER_CONSUMER_KEY
    consumer_secret: config.CARDS_TWITTER_CONSUMER_SECRET
    access_token_key: config.CARDS_TWITTER_ACCESS_TOKEN
    access_token_secret: config.CARDS_TWITTER_ACCESS_SECRET
  }
