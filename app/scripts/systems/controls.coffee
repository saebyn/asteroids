# controls system
define ['systems/base', 'THREE'], (System, THREE) ->
  sign = (x) ->
    x / Math.abs(x)

  maxRotation = 20.0
  steerAmount = 2.0

  applyTilt = (tiltAmount, direction, lastDirection, obj) ->
    obj.rotateX(tiltAmount * (lastDirection - direction))
    obj.__dirtyRotation = true


  controlEntity = (time, entity) ->
    if not entity.controllable.rotation?
      entity.controllable.rotation = 0

    direction = entity.controllable.controlDirection

    # Keep this local for calculation
    rotation = entity.controllable.rotation
    lastDirection = entity.controllable.lastDirection

    accel = 1.0 - Math.abs(rotation / maxRotation)

    if direction == entity.controllable.left
      rotation += steerAmount / time * accel
      direction = -1
    else if direction == entity.controllable.right
      rotation -= steerAmount / time * accel
      direction = 1
    else
      direction = 0

    rotation += -rotation / steerAmount / time

    # If we have a mesh/object to operate on...
    if entity.renderable.mesh?
      # Limit the range of rotation speed
      if Math.abs(rotation) > maxRotation
        rotation = maxRotation * sign(rotation)

      # Tilt the ship, like it's an aircraft doing a coordinated turn :P
      #applyTilt 0.2, direction, lastDirection, entity.renderable.mesh

      # Apply the rotation
      if entity.controllable.controlRotation?
        x = entity.controllable.controlRotation[0]
        y = entity.controllable.controlRotation[1]
      else
        x = y = 0
      
      entity.renderable.mesh.setAngularVelocity({x: x, y: y, z: rotation})

    # Save the current rotation amount to the component
    entity.controllable.rotation = rotation
    entity.controllable.lastDirection = direction

  class ControlSystem extends System
    processOurEntities: (entities, elapsedTime) ->
      controlEntity(elapsedTime, components) for [id, components] in entities when components?.position
