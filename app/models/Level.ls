module.exports = (orm, db, models, BaseModel) ->
  class Stage extends BaseModel
    table-name: \level
    id-attribute: \id

    game: -> @belongs-to models.Game .through models.Area
    area: -> @belongs-to models.Area
