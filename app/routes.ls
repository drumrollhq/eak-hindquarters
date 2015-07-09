module.exports = {
  v1:
    GET: \status
    hindquarters: GET: \_info
    action: verify-email: _key: GET: \actions.verify-email
    auth:
      register:
        # Rendered endpoints
        GET: \auth.page.register
        initial: POST: \auth.page.register.submit-initial
        manual: GET: \auth.page.register.manual
        oauth: GET: \auth.page.register.oauth
        complete: POST: \auth.page.register.submit-complete

        # JSON endpoints:
        POST: \auth.register

      # OAuth callbacks:
      google:
        GET: \auth.oauth.google
        callback: GET: \auth.oauth.google-callback
      facebook:
        GET: \auth.oauth.facebook
        callback: GET: \auth.oauth.facebook-callback

      js-return: GET: \auth.oauth.js-return
      login: POST: \auth.login
      logout: GET: \auth.logout

    count:
      _id: GET: \count.one

    sessions:
      POST: \sessions.create
      _session-id:
        POST: \sessions.checkin
        GET: \sessions.fetch
        DELETE: \sessions.stop
        events:
          POST: \sessions.events.create
          _event-id:
            POST: \sessions.events.update
            DELETE: \sessions.events.stop

    users:
      usernames: GET: \users.generate-usernames
      me: GET: \users.current
      _user-id:
        GET: \users.fetch
        exists: GET: \users.exists
        customer: GET: \users.get-customer
        subscription: POST: \users.subscribe

    cards:
      POST: \cards.publish
      share: POST: \cards.share

    games:
      mine: GET: \games.mine
      POST: \games.create
      _game-id:
        GET: \games.get
        PUT: \games.patch
        DELETE: \games.delete
        state: PUT: \games.patch-state
        stages:
          POST: \games.stages.find-or-create
          _stage-id:
            GET: \games.stages.get
            state: PUT: \games.stages.patch-state
        levels:
          _level-id:
            GET: \games.levels.get
            kittens: POST: \games.levels.save-kitten
            state: PUT: \games.levels.patch-state
}
