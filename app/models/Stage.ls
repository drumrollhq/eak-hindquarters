module.exports = (orm, db, models, BaseModel, {log}) ->
  class Stage extends BaseModel
    has-timestamps: <[createdAt updatedAt]>
    has-state: true
    table-name: \stage
    id-attribute: \id

    game: -> @belongs-to models.Game
    user: -> @belongs-to models.User .through models.Game
    levels: -> @has-many models.Level
