module.exports = (orm, db, models, BaseModel, {log}) ->
  class Stage extends BaseModel
    table-name: \level
    id-attribute: \id
    has-state: true

    game: -> @belongs-to models.Game .through models.Stage
    stage: -> @belongs-to models.Stage
