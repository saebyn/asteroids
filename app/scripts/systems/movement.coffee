# movement system
define [], () ->
  moveEntity = (entity, elapsedTime) ->
    entity.position.x += entity.moveable.direction.x * elapsedTime
    entity.position.y += entity.moveable.direction.y * elapsedTime
    if entity.position.z? and entity.direction.z?
      entity.position.z += entity.moveable.direction.z * elapsedTime

  (app, entities, elapsedTime) ->
    moveEntity(components, elapsedTime) for [id, components] in entities when components?.position
