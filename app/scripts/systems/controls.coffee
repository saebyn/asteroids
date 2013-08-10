# controls system
define ['THREE'], (THREE) ->
  sign = (x) ->
    x / Math.abs(x)

  maxRotation = 5
  rotation = 0

  controlEntity = (direction, time, entity) ->
    if direction == entity.controllable.left
      rotation += 1.5 / time
    else if direction == entity.controllable.right
      rotation -= 1.5 / time

    if entity.renderable.mesh?
      if Math.abs(rotation) > maxRotation
        rotation = maxRotation * sign(rotation)

      entity.renderable.mesh.setAngularVelocity({x: 0, y: 0, z: rotation})

  (app, entities, elapsedTime) ->
    controlEntity(app.controlDirection, elapsedTime, components) for [id, components] in entities when components?.position
