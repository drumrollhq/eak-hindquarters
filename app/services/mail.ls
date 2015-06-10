require! {
  'bluebird': Promise
  'mandrill-api/mandrill': {Mandrill}
}

export setup = ({config, log}) ->
  client = exports.client = new Mandrill config.MANDRILL_API_KEY

  send = exports.send = (template-name, user, data = {}) -> new Promise (resolve, reject) ->
    data := {} <<< user.to-safe-json! <<< data

    options = {
      template_name: template-name
      template_content: []
      message:
        to: [user.to-mail-recipient!]
        track_opens: true
        track_clicks: true
        merge_language: 'handlebars'
        global_merge_vars: [{name: key, content: value} for key, value of data]
        metadata: user.mail-metadata!
    }

    client.messages.send-template options, resolve, reject

  exports.send = (...args) ->
    send ...args
      .tap (result) -> log.debug {args, result}
      .catch (e) ->
        log.error {args, e}
        throw e
