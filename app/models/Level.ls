module.exports = (orm, db, models, BaseModel) ->
  class Stage extends BaseModel
    table-name: \level
    id-attribute: \id
    has-state: true

    game: -> @belongs-to models.Game .through models.Area
    area: -> @belongs-to models.Area
