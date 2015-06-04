require! {
  '../../errors'
  'stripe': Stripe
}

module.exports = subscriptions = (models, store, config) ->
  stripe = Stripe config.STRIPE_KEY
  {User} = models

  create: (user-id, {plan, token, ip, card-country, user-country}) ->
    user = null
    country = null
    customer = null

    User.find user-id .fetch!
      .then (u) ->
        user := u
        user.set-country ip: ip, card-country: card-country, user-country: user-country
      .then (c) ->
        c := country
        user.find-or-create-stripe-customer!
      .then (cust) ->
        customer := cust


      #   stripe.customers.create {
      #     description: "User(#{user-id}) - @#{user.get \username} - #{user.get \firstName} #{user.get \lastName}"
      #     email: user.get \email
      #     metadata: user.to-json!.{id, status, username, first-name, last-name, gender}
      #     plan: plan
      #     source: token
      #   }
      # .tap (resp) -> console.log JSON.stringify resp, null, 2
      # .then (customer) ->
      #   user.save {
      #     stripe-customer-id: customer.id
      #     stripe-card-country: card-country
      #   } patch: true
