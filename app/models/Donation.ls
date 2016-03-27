require! {
  'country-data'
  'geoip-lite': geoip
}

module.exports = (orm, db, models, BaseModel, {log, stripe}) ->
  class Donation extends BaseModel
    has-timestamps: true
    table-name: \donations
    id-attribute: \id

    formatters:
      trim: <[email]>
      lower: <[email ip_country card_country user_country]>

    @create = ({amount, email, token, ip, card-country, user-country}) ->
      ip-country = geoip.lookup ip .country.to-lower-case!
      user-country = country-data.lookup.countries name: user-country .{}0.alpha2

      db.transaction (tx) ~>
        var donation
        @forge {amount, email, ip-country, card-country, user-country}
          .save {}, transacting: tx
          .then (d) -> donation := d
          .then -> stripe.charges.create {
            amount: amount
            currency: \gbp
            description: "Donation(#{donation.id}) - #email"
            receipt_email: email
            metadata: {donation: true, email, donation-id: donation.id}
            source: token
          }
          .then (charge) -> donation.save {stripe_id: charge.id}, patch: true, transacting: tx
          .then ~> @forge id: donation.id .fetch transacting: tx
