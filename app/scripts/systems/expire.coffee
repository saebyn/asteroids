# expire system
define ['systems/base'], (System) ->
  expire = (app, id, expirable, elapsedTime) ->
    expirable.time -= elapsedTime

    if expirable.time <= 0
      app.removeEntity(id)

  class ExpireSystem extends System
    processOurEntities: (entities, elapsedTime) ->
      expire(@app, id, components.expirable, elapsedTime) for [id, components] in entities
