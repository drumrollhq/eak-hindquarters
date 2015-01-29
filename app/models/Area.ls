module.exports = (orm, db, models, BaseModel) ->
  class Area extends BaseModel
    has-timestamps: <[createdAt updatedAt]>
    table-name: \area
    id-attribute: \id

    game: -> @belongs-to models.Game
    user: -> @belongs-to models.User .through models.Game
