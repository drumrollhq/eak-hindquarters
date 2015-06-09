module.exports = (orm, db, models, BaseModel, log) ->
  class OAuth extends BaseModel
    table-name: 'oauth'
    id-attribute: 'provider_id'
    user: -> @belongs-to models.User
    update-data: (data) ->
      db.table @table-name
        .where provider: (@get 'provider'), provider_id: (@get 'providerId')
        .update provider_data: data

    @find = (provider, provider-id) -> OAuth.forge {provider, provider-id}
