require! 'joi'

export body = joi.object!.keys {
  user: joi.string!.trim!.min 1 .required!
  card: joi.string!.required!
}

export handler = ({body: {user, card}, services: {twitter}}) ->
  unless user.0 is '@' then user = "@#user"
  tweet = "#{user} someone's sent you a valentines card! Seems you have a secret admirer... https://cards.eraseallkittens.com#{card}"
  twitter.glitterquiff.post-async 'statuses/update', status: tweet
    .then ([tweet]) -> success: true, id: tweet.id, text: tweet.text
