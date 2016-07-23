require! {
  'bluebird': Promise
  'sendgrid': SG
}

from-email-address = 'tarquin@drumrollhq.com'
from-email-name = 'Tarquin Glitterquiff (EraseAllKittens.com)'

template-lookup = {
  'signup-confirm': '37448ad3-6a7f-4c53-8f7f-62fac7225fd1'
  'signup-confirm-parent': 'e14fca46-6216-43bd-958b-fe9cb1340691'
  'signup-welcome': '1a93da16-0264-4712-bd6b-f225f57e52f0'
}

export setup = ({config, log}) ->
  client = exports.client = new SG.SendGrid config.SENDGRID_API_KEY

  send = exports.send = (template-name, user, data = {}) -> new Promise (resolve, reject) ->
    data := {} <<< user.to-safe-json! <<< data
    unless template-lookup[template-name] then throw new Error "Unknown template #template-name"

    personalization = new SG.mail.Personalization!
      ..add-to new SG.mail.Email (user.get \email), user.name!

    for key, value of data
      personalization.add-substitution "-#{key}-": "#value"

    mail = new SG.mail.Mail!
      ..set-from new SG.mail.Email from-email-address, from-email-name
      ..set-template-id template-lookup[template-name]
      ..add-content new SG.mail.Content 'text/plain', template-name
      ..add-personalization personalization

    request = {} <<< SG.empty-request <<< {
      method: \POST
      path: \/v3/mail/send
      body: mail.to-JSON!
    }

    client.API request, (response) ->
      console.log response
      if response and response.status-code and 200 <= response.status-code <= 299
        resolve response
      else
        reject response

  exports.send = (...args) ->
    send ...args
      .tap (result) -> log.debug {args, result}
      .catch (e) ->
        log.error {args, e}
        throw e
