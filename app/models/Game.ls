module.exports = (orm, db, models, BaseModel) ->
  class Game extends BaseModel
    has-timestamps: <[createdAt updatedAt]>
    has-state: true
    table-name: \game
    id-attribute: \id

    validations:
      url: <[required]>

    user: -> @belongs-to models.User
    active-stage: -> @belongs-to models.Stage, 'active_stage'
    stages: -> @has-many models.Stage
    levels: -> @has-many models.Level .through models.Stage

    @for-user = (id, {limit = null}) ->
      Game
        .query do
          where: user_id: id
          order-by: ['updated_at', 'desc']
          limit: limit
        .fetch-all!
