module.exports = {
  GET: \status
  v1:
    GET: \status
    action: verify-email: _key: GET: \actions.verify-email
}
{
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
        callback: GET: \auth.oauth.callback.google
      facebook:
        GET: \auth.oauth.facebook
        callback: GET: \auth.oauth.callback.facebook

      js-return: GET: \auth.js-return
      login: POST: \auth.login
      logout: GET: \auth.logout

    count:
      _id: GET: \count.one

    sessions:
      POST: \sessions.create
      _session-id:
        POST: \sessions.checkin
        DELETE: \sessions.stop
        events:
          POST: \sessions.events.create
          _event-id:
            POST: \sessions.events.update
            DELETE: \sessions.events.stop

    users:
      usernames: GET: \user.generate-usernames
      me: GET: \user.current
      _user-id:
        customer: GET: \user.get-customer
        exists: GET: \user.exists

    cards:
      POST: \cards.publish
      share: POST: \cards.share

    games:
      POST: \games.create
      mine: GET: \games.mine
      _game-id:
        GET: \games.get
        PUT: \games.patch
        DELETE: \games.delete
        state: PUT: \game.patch-state
        stages:
          POST: \games.find-or-create-stage
          _stage-id:
            state: PUT: \games.patch-stage-state
        levels:
          _level-id:
            kittens: POST: \games.save-kitten
            state: PUT: \games.patch-level-state
}
