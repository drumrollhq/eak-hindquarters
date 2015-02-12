require! {
  'util'
  '../../config'
  '../errors'
  '../id-gen'
  'bluebird': Promise
  'express'
  'knox'
  'twitter': Twitter
}

s3 = knox.create-client {
  key: config.AWS_S3_KEY
  secret: config.AWS_S3_SECRET
  bucket: config.ECARDS_S3_BUCKET
  region: config.ECARDS_S3_REGION
  secure: false
}

s3 = Promise.promisify-all s3

twitter = new Twitter {
  consumer_key: config.CARDS_TWITTER_CONSUMER_KEY
  consumer_secret: config.CARDS_TWITTER_CONSUMER_SECRET
  access_token_key: config.CARDS_TWITTER_ACCESS_TOKEN
  access_token_secret: config.CARDS_TWITTER_ACCESS_SECRET
}

console.log twitter

twitter = Promise.promisify-all twitter

module.exports = (models, store, config) ->
  app = express.Router!

  app.post '/' (req, res, next) ->
    unless typeof req.body.html is \string then return res.promise errors.bad-request 'You must supply html'
    result = id-gen.get-unique store, 'ecard-name'
      .tap (id) ->
        file-name = "/c/#id"
        contents = new Buffer req.body.html
        headers = {
          'Content-Type': 'text/html'
          'x-amz-acl': 'public-read'
        }
        s3.put-buffer-async contents, file-name, headers
          .then (response) ->
            console.log response
      .then (id) ->
        {success: true, file: "/c/#id"}

    res.promise result

  app.post '/share' (req, res, next) ->
    unless typeof req.body.user is \string and typeof req.body.card is \string then return res.promise errors.bad-request 'You need a user and card!'
    user = req.body.user.trim!
    if user is '' or -1 isnt user.index-of ' ' then return res.promise errors.bad-request 'Invalid user'
    unless user.0 is '@' then user = '@' + user
    tweet = "#{user} someone's sent you a valentines card! Seems you have a secret admirer... https://cards.eraseallkittens.com#{req.body.card}"

    result = twitter.post-async 'statuses/update', status: tweet
      .then ([tweet]) -> success: true, id: tweet.id, text: tweet.text

    res.promise result
