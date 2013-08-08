# expire system
define [], () ->
  expire = (app, id, expirable, elapsedTime) ->
    expirable.time -= elapsedTime

    if expirable.time <= 0
      app.removeEntity(id)

  (app, entities, elapsedTime) ->
    expire(app, id, components.expirable, elapsedTime) for [id, components] in entities
