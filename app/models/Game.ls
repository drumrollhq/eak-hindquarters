module.exports = (orm, db, models, BaseModel) ->
  class Game extends BaseModel
    has-timestamps: <[createdAt updatedAt]>
    table-name: \game
    id-attribute: \id

    validations:
      url: <[required]>

    user: -> @belongs-to models.User
    active-area: -> @belongs-to models.Area, 'active_area'

    @for-user = (id) -> Game.where user_id: id .fetch-all!
