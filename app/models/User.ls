require! {
  'country-data'
  'bcrypt'
  'bluebird': Promise
  'fs'
  'geoip-lite': geoip
  'prelude-ls': {reject, empty, capitalize, count-by, id, last, sort-by, obj-to-pairs, filter, map}
  'vatrates/vatrates'
}

NoCustomerError = (e) ->
  e.type is \StripeInvalidRequest and e.message.match /^No such customer/

Promise.promisify-all bcrypt

adjectives = fs.read-file-sync "#{__dirname}/../../data/adjectives.txt" encoding: 'utf-8'
  .split '\n' |> reject empty
nouns = fs.read-file-sync "#{__dirname}/../../data/nouns.txt" encoding: 'utf-8'
  .split '\n' |> reject empty

random = (arr) -> arr[Math.floor arr.length * Math.random!]

module.exports = (orm, db, models, BaseModel, {log, services, stripe, errors}) ->
  class User extends BaseModel
    has-timestamps: true
    table-name: 'user'
    id-attribute: 'id'

    formatters:
      trim: <[email username first_name last_name]>
      lower: <[email username]>

    cast:
      subscribed-newsletter: 'boolean'

    validations:
      full:
        # first-name: <[required]>
        username:
          # * rule: \required
          #   message: 'You\'ve got to list a username! Please?'
          * rule: \alphaNumeric
            message: 'Hey! Letters and numbers only in your username.'
          * rule: \unique
            params: <[user username trim lower]>
            message: 'Some one has already taken that username. How could they?'
        email:
          * rule: \required
            message: 'You need to enter an email I\'m afraid :/'
          * rule: \email
            message: 'That email address... doesn\'t look like an email address'
          * rule: \unique
            params: <[user email trim lower]>
            message: 'Some one has already taken that email! How dare they!'
      password:
        password:
          * rule: \required
            message: 'You gotta come up with a password! DO IT!'
          * rule: \minLength
            params: <[4]>
            message: 'You can do better than that! A longer password, please!'
        password-confirm:
          * rule: 'required'
            message: 'Confirm your password. Or else.'
          * rule: 'matchesField'
            params: <[password]>
            message: 'Your confirmation doesn\'t match your password! FIX IT FIX IT FIX IT!'

    oauths: -> @has-many models.OAuth
    games: -> @has-many models.Game

    adult: -> @get 'assumeAdult'

    to-safe-json: ->
      user = @to-JSON!
      safe = user.{id, status, username, email, first-name, last-name, gender, subscribed-newsletter, created-at, updated-at, assume-adult, verified-email, eak-settings}
      safe.has-password = !!user.password-digest
      safe.oauths = @related 'oauths' .to-JSON! .map (oauth) -> oauth.{provider, provider-id}
      safe.name = @name!
      safe.country = @country!
      safe

    name: ->
      {first-name, last-name, username, email} = @to-json!
      switch
      | first-name and last-name => "#first-name #last-name"
      | first-name => first-name
      | username => username
      | email => email
      | otherwise => throw new Error "Cannot get name for user #{@id}: no first-name, last-name, or username"

    mail-metadata: -> @to-json!.{id, username, gender}

    hash-password: ->
      pw = @get 'password'
      unless pw then return Promise.resolve @get 'passwordDigest'
      @unset 'password'
      @unset 'passwordConfirm'

      bcrypt.gen-salt-async 10
        .then (salt) -> bcrypt.hash-async pw, salt
        .tap (hash) ~> @set 'passwordDigest', hash

    check-password: (pw = '') ->
      if @get 'passwordDigest'
        bcrypt.compare-async pw, that
          .then (res) ->
            unless res then errors.bad-request 'Incorrect password!'
      else
        errors.bad-request "Gosh darn it! We don't have a password for #{@get 'username'}. Did you sign up with google or facebook?"

    save: ->
      sup = super
      args = arguments
      @hash-password!
        .then ~> sup.apply @, args

    send-mail: (template-name, data) ->
      services.mail.send template-name, this, data

    # because of shitty VATMOSS stuff, we need to collect the users country. VATMOSS requires that
    # we have 2 non-conflicting pieces of evidence of the users country, so we collect three: ip
    # address, card country, and user-supplied country. As long as at least two of these match,
    # we're good. Otherwise, panic and cry a bit?
    set-country: ({ip, card-country, user-country}) ->
      ip-country = if ip?
        geoip.lookup ip .country.to-lower-case!
      else @get \ipCountry

      if typeof user-country is \string and user-country.length isnt 2
        user-country = country-data.lookup.countries name: user-country .{}0.alpha2

      card-country ?= card-country or @get \stripeCardCountry
      user-country ?= user-country or @get \userCountry

      if card-country then card-country .= to-lower-case!
      if user-country then user-country .= to-lower-case!

      [country, count] = @country [ip-country, card-country, user-country], include-count: true

      if count < 2 then return errors.bad-request "Conflicting country information: at least 2 countrys should match"

      # save country info for later
      @save {ip-country, stripe-card-country: card-country, user-country}, patch: true
        .then -> country

    country: (country-list, {include-count = false} = {}) ->
      country-list ?= [\ipCountry \stripeCardCountry \userCountry]
        |> map ~> @get it

      try
        [country, count] = country-list
          |> filter -> it? # reject null/undefined
          |> count-by id # count number of each country
          |> obj-to-pairs
          |> sort-by last
          |> last # find the country that occurs the most
      catch e
        [country, count] = [null, 0]

      if include-count then return [country, count] else return country

    calculate-vat-rate: ->
      country = @country!
      if country and vatrates[country.to-upper-case!] then that.rates.standard / 100 else 0

    find-or-create-stripe-customer: (token) ->
      customer-id = @get \stripeCustomerId
      if customer-id?
        stripe.customers.retrieve customer-id
          .then (customer) ~>
            if customer.deleted
              log.info 'stripe customer deleted' {customer-id, user: @id}
              @unset \stripeCustomerId
              @find-or-create-stripe-customer token
            else if token
              log.info 'add stripe token' {customer-id, user: @id, token}
              stripe.customers.update customer.id, source: token
            else
              customer
          .catch NoCustomerError, (e) ~>
            log.info 'bad cusomter' {customer-id, user: @id}
            @unset \stripeCustomerId
            @find-or-create-stripe-customer token
      else
        stripe.customers
          .create {
            description: "User(#{@id}) - @#{@get \username} - #{@name!}"
            email: @get \email
            metadata: @to-safe-json!{id, username, email, first-name, last-name, gender, created-at, country}
            tax_percent: @calculate-vat-rate! * 100
            source: token
          }
          .tap (customer) ~>
            log.info 'created stripe customer' {customer-id: customer.id, user: @id}
            @save {stripe-customer-id: customer.id}, {patch: true}

    subscribe-plan: (plan, token) ->
      save-plan = true
      plan-data = plan: plan, tax_percent: @calculate-vat-rate! * 100
      @find-or-create-stripe-customer token
        .then (customer) ~>
          if customer.subscriptions?.data?.length > 0
            subscription = customer.subscriptions.data.0
            if subscription.plan.id is plan
              log.info 'subscribe-plan: already subscribed' {user: @id, subscription: subscription.id}
              save-plan := false
              subscription
            else
              log.info 'subscribe-plan: update subscription' {user: @id, subscription: subscription.id, old-plan: subscription.plan.id, plan: plan-data}
              stripe.customers.update-subscription customer.id, subscription.id, plan-data
          else
            log.info 'subscribe-plan: create subscription' {user: @id, plan: plan-data}
            stripe.customers.create-subscription customer.id, plan-data
        .tap (subscription) ~>
          if save-plan
            @save {
              plan: subscription.plan.id
              plan-end: new Date subscription.current_period_end * 1000
            }, patch: true

    @username = -> "#{capitalize random adjectives}#{capitalize random nouns}#{Math.floor 100 * Math.random!}"

    @unused-username = ->
      username = User.username!
      User.exists username
        .then (exists) -> if exists then User.unused-username! else username

    @get-id-spec = (user-id) ->
      spec = switch (typeof user-id)
      | 'number' => id: user-id
      | 'string' => (if (user-id.index-of '@') isnt -1 then email: user-id else username: user-id)
      | 'object' => user-id

      if spec.username then spec.username .= trim!.to-lower-case!
      if spec.email then spec.email .= trim!.to-lower-case!

      spec

    @exists = (user-id) ->
      db.first 'id'
        .from User::table-name
        .where User.get-id-spec user-id
        .then (row) -> !!row

    @find = (user-id) ->
      User.forge User.get-id-spec user-id

    @ensure-logged-in = (req, res, next) ->
      if req.user?
        next!
      else
        res.promise errors.unauthorized 'You must be logged in to access this resource'
