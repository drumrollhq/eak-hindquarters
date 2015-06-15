require! {
  'vatrates/vatrates'
}

User = ctx.models.User
stripe = ctx.stripe

new-user = {
  first-name: 'Tarquin'
  last-name: 'Glitterquiff'
  username: 'glitterquiff'
  password: 'glitter123'
  password-confirm: 'glitter123'
  email: 'tarquin@glitterquiff.org'
  gender: 'other'
  subscribed-newsletter: true
}

country-user = {} <<< new-user <<< {
  stripe-card-country: \gb
  user-country: \gb
  ip-country: \gb
}

example-gb-ip-address = '212.58.246.104' # bbc
example-ie-ip-address = '31.13.64.0' # facebook
example-us-ip-address = '17.0.0.0' # apple

describe 'User password' ->
  user = null

  before-each ->
    user := new User new-user

  specify 'should replace passwords with digest on save' ->
    expect user.get \password .to.equal 'glitter123'
    expect user.get \password .to.equal 'glitter123'
    expect user.get \passwordDigest .to.not.exist
    user.save!.then (user) ->
      expect user.get \password .to.not.exist
      expect user.get \passwordConfirm .to.not.exist
      expect user.get \passwordDigest .to.exist
      user.destroy!

describe 'User country & tax rate' ->
  user = null
  before-each ->
    new User new-user
      .save!
      .then (u) -> user := u

  after-each -> user.destroy!

  specify 'should allow setting countries with a majority of 2 or 3' ->
    expect Promise.all [
      user.set-country ip: example-gb-ip-address, card-country: \ie, user-country: \gb
      user.set-country ip: example-gb-ip-address, card-country: \us, user-country: \us
      user.set-country card-country: \gb, user-country: \gb
      user.set-country ip: example-ie-ip-address, card-country: \ie, user-country: \ie
    ] .to.eventually.deep.equal <[gb us gb ie]>

  specify 'should reject countries with no majority' ->
    expect user.country! .to.be.null
    expect user.set-country ip: example-gb-ip-address, card-country: \us, user-country: \ie .to.be.rejected

  context 'with an existing majority of 2' ->
    before-each ->
      user.set-country ip: example-gb-ip-address, card-country: \gb, user-country: \ie

    specify 'should let setting 1 country flip the majority' ->
      expect user.country! .to.equal \gb
      expect user.set-country ip: example-ie-ip-address .to.eventually.equal \ie

    specify 'should reject setting countries to remove the majority' ->
      expect user.country! .to.equal \gb
      expect user.set-country card-country: \us .to.be.rejected

  context 'with a majority pointing to an eu country' ->
    before-each ->
      user.set-country ip: example-gb-ip-address, card-country: \gb, user-country: \gb

    specify 'should return the appropriate tax rate' ->
      expect user.country! .to.equal \gb
      expect user.calculate-vat-rate! .to.equal vatrates.GB.rates.standard/100

  context 'with a majority pointing to a non-eu country' ->
    before-each ->
      user.set-country ip: example-us-ip-address, card-country: \us, user-country: \us

    specify 'should return a tax rate of 0' ->
      expect user.country! .to.equal \us
      expect user.calculate-vat-rate! .to.equal 0

describe 'User#find-or-create-stripe-customer' ->
  user = null
  before-each -> user := new User country-user
  after-each -> if user.id then user.destroy!

  context 'without a stripe id' ->
    specify 'should create a new customer' ->
      create = sinon.stub stripe.customers, \create, (cus) ->
        expect cus.email .to.equal user.get \email
        expect cus.tax_percent .to.be.a \number
        Promise.resolve id: \cus_someid

      user.find-or-create-stripe-customer!
        .tap ->
          expect create .to.have.been.called-once
          create.restore!
        .should.eventually.deep.equal id: \cus_someid

    specify 'should pass through a token when creating' ->
      create = sinon.stub stripe.customers, \create, (cus) ->
        expect cus.source .to.equal \my-token
        Promise.resolve id: \cus_someid

      user.find-or-create-stripe-customer \my-token
        .then -> create.restore!

    specify 'should save the new stripe id' ->
      expect user.get \stripeCustomerId .to.not.exist
      create = sinon.stub stripe.customers, \create, -> Promise.resolve id: \cus_someid

      user.find-or-create-stripe-customer!
        .tap ->
          create.restore!
          expect user.get \stripeCustomerId .to.equal \cus_someid
        .should.eventually.deep.equal id: \cus_someid

  context 'with a stripe id' ->
    before-each -> user.set \stripeCustomerId \cus_initialid

    specify 'should retrieve the customer from stripe' ->
      retr = sinon.stub stripe.customers, \retrieve, (id) ->
        expect id .to.equal \cus_initialid
        Promise.resolve id: id

      user.find-or-create-stripe-customer!
        .tap ->
          expect retr .to.have.been.called-once
          retr.restore!
        .should.eventually.deep.equal id: \cus_initialid

    specify 'should update the customer with a token if one is provided' ->
      retr = sinon.stub stripe.customers, \retrieve (id) -> Promise.resolve {id}
      update = sinon.stub stripe.customers, \update (id, update) ->
        expect id .to.equal \cus_initialid
        expect update .to.deep.equal {source: \new-token}
        Promise.resolve {id}

      user.find-or-create-stripe-customer \new-token
        .tap ->
          expect retr .to.have.been.called-once
          expect update .to.have.been.called-once
          retr.restore!
          update.restore!
        .should.eventually.deep.equal id: \cus_initialid

    context 'pointing to a deleted customer' ->
      retr = null
      before-each ->
        retr := sinon.stub stripe.customers, \retrieve, (id) -> Promise.resolve id: id, deleted: true

      after-each -> retr.restore!

      specify 'should create a new stripe customer' ->
        create = sinon.stub stripe.customers, \create, (cus) ->
          expect cus.email .to.equal user.get \email
          Promise.resolve id: \cus_newid

        user.find-or-create-stripe-customer!
          .tap ->
            expect create .to.have.been.called-once
            create.restore!
          .should.eventually.deep.equal id: \cus_newid

      specify 'should create the new customer with a token if provided' ->
        create = sinon.stub stripe.customers, \create, (cus) ->
          expect cus.source .to.equal \my-token
          Promise.resolve id: \cus_newid

        user.find-or-create-stripe-customer \my-token
          .tap ->
            expect create .to.have.been.called-once
            create.restore!
          .should.eventually.deep.equal id: \cus_newid

      specify 'should save the new customer id' ->
        expect user.get \stripeCustomerId .to.equal \cus_initialid
        create = sinon.stub stripe.customers, \create, -> Promise.resolve id: \cus_newid

        user.find-or-create-stripe-customer!
          .tap ->
            expect create .to.have.been.called-once
            expect user.get \stripeCustomerId .to.equal \cus_newid
            create.restore!
          .should.eventually.deep.equal id: \cus_newid

describe 'User#subscribe-plan' ->
  user = null
  before-each ->
    user := new User country-user
    user.set \stripeCustomerId \cus_someid

  after-each ->
    if user.id then user.destroy!

  plan-resp = (id, options) -> Promise.resolve id: \sub_subid, plan: id: options.plan

  specify 'should find or create a stripe customer' ->
    sinon.stub user, \findOrCreateStripeCustomer, -> Promise.resolve id: \cus_someid
    sinon.stub stripe.customers, \createSubscription, plan-resp

    user.subscribe-plan \my-plan
      .then ->
        expect user.find-or-create-stripe-customer .to.have.been.called-once
        user.find-or-create-stripe-customer.restore!
        stripe.customers.create-subscription.restore!
      .should.be.fulfilled

  specify 'should pass a token through to find-or-create-stripe-customer' ->
    sinon.stub user, \findOrCreateStripeCustomer, -> Promise.resolve id: \cus_someid
    sinon.stub stripe.customers, \createSubscription, plan-resp

    user.subscribe-plan \my-plan, \some-token
      .then ->
        expect user.find-or-create-stripe-customer .to.have.been.called-once
        expect user.find-or-create-stripe-customer .to.have.been.called-with \some-token
        user.find-or-create-stripe-customer.restore!
        stripe.customers.create-subscription.restore!
      .should.be.fulfilled

  context 'without an existing subscription' ->
    before-each ->
      sinon.stub user, \findOrCreateStripeCustomer, -> Promise.resolve {
        id: \cus_someid
        subscriptions: data: []
      }

    after-each -> user.find-or-create-stripe-customer.restore!

    specify 'should create a subscription' ->
      sinon.stub stripe.customers, \createSubscription, (cus-id, options) ->
        expect cus-id .to.equal \cus_someid
        expect options .to.deep.equal plan: \eak-parent-monthly
        Promise.resolve id: \sub_subid, plan: id: options.plan

      user.subscribe-plan \eak-parent-monthly
        .tap ->
          expect stripe.customers.create-subscription .to.have.been.called-once
          stripe.customers.create-subscription.restore!
        .should.eventually.deep.equal id: \sub_subid, plan: id: \eak-parent-monthly

    specify 'should save the plan id' ->
      sinon.stub stripe.customers, \createSubscription, plan-resp
      expect user.get \plan .to.not.exist

      user.subscribe-plan \eak-parent-monthly
        .then ->
          expect user.get \plan .to.equal \eak-parent-monthly
          stripe.customers.create-subscription.restore!
        .should.be.fulfilled

  context 'with an existing subscription' ->
    before-each ->
      user.set \plan \eak-parent-monthly
      sinon.stub user, \findOrCreateStripeCustomer, -> Promise.resolve {
        id: \cus_someid
        subscriptions:
          data: [
            id: \sub_subid
            plan: id: \eak-parent-monthly
          ]
      }

    after-each -> user.find-or-create-stripe-customer.restore!

    specify 'should update the subscription to the new plan' ->
      sinon.stub stripe.customers, \updateSubscription, (cus-id, sub-id, options) ->
        expect cus-id .to.equal \cus_someid
        expect sub-id .to.equal \sub_subid
        expect options .to.deep.equal plan: \new-plan
        Promise.resolve id: sub-id, plan: id: options.plan

      user.subscribe-plan \new-plan
        .tap ->
          expect stripe.customers.update-subscription .to.have.been.called-once
          stripe.customers.update-subscription.restore!
        .should.eventually.deep.equal id: \sub_subid, plan: id: \new-plan

    specify 'should save the new plan id' ->
      expect user.get \plan .to.equal \eak-parent-monthly
      sinon.stub stripe.customers, \updateSubscription, (cus-id, sub-id, options) ->
        Promise.resolve id: sub-id, plan: id: options.plan

      user.subscribe-plan \new-plan
        .tap ->
          expect user.get \plan .to.equal \new-plan
          stripe.customers.update-subscription.restore!

    specify 'should do nothing when attempting to subscribe to the same plan' ->
      expect user.get \plan .to.equal \eak-parent-monthly
      sinon.spy stripe.customers, \updateSubscription
      sinon.spy user, \save

      user.subscribe-plan \eak-parent-monthly
        .tap ->
          expect stripe.customers.update-subscription .to.not.have.been.called
          expect user.save .to.not.have.been.called
          stripe.customers.update-subscription.restore!
          user.save.restore!
        .should.eventually.deep.equal id: \sub_subid, plan: id: \eak-parent-monthly
