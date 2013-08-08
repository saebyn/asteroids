# controls system
define [], () ->
  controlEntity = (direction, time, entity) ->
    # TODO use an acceleration system for turning, so it's not so
    # choppy.
    if direction == entity.controllable.left
      entity.position.direction.z += 1.5 / time
    else if direction == entity.controllable.right
      entity.position.direction.z -= 1.5 / time

  (app, entities, elapsedTime) ->
    controlEntity(app.controlDirection, elapsedTime, components) for [id, components] in entities when components?.position
