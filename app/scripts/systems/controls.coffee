# controls system
define ['systems/base', 'THREE'], (System, THREE) ->
  sign = (x) ->
    x / Math.abs(x)

  maxRotation = 20.0
  steerAmount = 1.2

  tampRotation = (entity, steerAmount, time) ->
    # reduce rotating over time for all axes
    (entity.controllable.rotation[axis] += -entity.controllable.rotation[axis] / steerAmount / time) for axis in ['x', 'y', 'z']


  class ControlSystem extends System
    process: (entity, time, id) ->
      # If no position or physics, can't do anything
      if not entity.position or not entity._physijs
        return

      if not entity.controllable.rotation?
        entity.controllable.rotation = {x: 0, y: 0, z: 0}

      direction = entity.controllable.controlDirection
      # is direction + or -
      sign = 0
      if direction in [entity.controllable.left, entity.controllable.down, entity.controllable.tiltRight]
        sign = -1.0
      else if direction in [entity.controllable.right, entity.controllable.up, entity.controllable.tiltLeft]
        sign = 1.0

      # which axis is direction?
      if direction in [entity.controllable.left, entity.controllable.right]
        axis = 'z'
      else if direction in [entity.controllable.up, entity.controllable.down]
        axis = 'y'
      else if direction in [entity.controllable.tiltLeft, entity.controllable.tiltRight]
        axis = 'x'
      else
        axis = false

      tampRotation(entity, steerAmount, time)

      if axis
        # Keep this local for calculation
        rotation = entity.controllable.rotation[axis]

        accel = 1.0 - Math.abs(rotation / maxRotation)

        # apply steering
        if sign != 0
          rotation -= sign * steerAmount / time * accel

        # Save the current rotation amount to the component
        entity.controllable.rotation[axis] = rotation

      velocity = new THREE.Vector3(
        entity.controllable.rotation.x,
        entity.controllable.rotation.y,
        entity.controllable.rotation.z)

      # If we have an object to operate on...
      if entity.quaternion?
        # Limit the range of rotation speed
        if Math.abs(rotation) > maxRotation
          rotation = maxRotation * sign(rotation)

        velocity.applyQuaternion(entity.quaternion)

        entity.setAngularVelocity(velocity)

      if entity.controllable.controlThrust
        # TODO tune this
        force = new THREE.Vector3(
          entity.controllable.controlThrust * 1000.0,
          0,
          0)
        force.applyMatrix4(entity.matrix)
        entity.setLinearFactor({x: 1, y: 1, z: 1})
        entity.applyCentralForce(force)
