module.exports = (orm, db, models, BaseModel) ->
  class Stage extends BaseModel
    has-timestamps: <[createdAt updatedAt]>
    table-name: \stage
    id-attribute: \id

    game: -> @belongs-to models.Game
    user: -> @belongs-to models.User .through models.Game
