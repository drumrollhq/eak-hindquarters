module.exports = (models, store, config) ->

  {
    verify-email: (user) ->
      status = user.get 'status'
      update = verified-email: true
      if status is 'pending' then update.status = 'active'

      user.save update, patch: true
  }
