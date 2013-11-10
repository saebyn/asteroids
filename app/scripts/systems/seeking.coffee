# seeking system
define ['systems/base', 'THREE'], (System, THREE) ->
  class SeekingSystem extends System
    # find any entities in the scene
    #  that have a spawned == entity.seeking.type
    getEntities: (type) ->
      entity for entity in @app.scene.children when entity.spawned == type

    process: (entity, elapsedTime) ->
      # We can't target if we don't have a position or physics
      if not entity.position? or not entity._physijs
        return

      origin = new THREE.Vector3(entity.position.x, entity.position.y, entity.position.z)

      #  calculate the distance to each one from this entity
      objects = @getEntities(entity.seeking.type)

      if objects.length > 0
        objects.sort((a, b) ->
          a.position.distanceTo(origin) - b.position.distanceTo(origin)
        )

        # Take the closest one as the target
        target = objects[0].position

        # The direction from the seeking object to the saught object.
        targetDirection = target.clone().sub(origin).normalize()

        # The current direction of the seeking object's velocity.
        currentVelocity = entity.getLinearVelocity()
        currentDirection = currentVelocity.clone().normalize()

        # Get the normal of the plane that the current velocity vector and the
        # vector of the desired direction.
        normal = new THREE.Vector3()
        normal.crossVectors(currentDirection, targetDirection)

        # This calculated normal is the axis we want to rotate around.
        # Because we normalize both of the direction vectors into unit
        # vectors, the magnitude of the normal indicates the amount of
        # rotation.
        axis = normal.clone().normalize()
        angle = Math.asin(normal.length())

        quaternion = new THREE.Quaternion()
        quaternion.setFromAxisAngle(axis, angle)

        ## Update orientation of seeking object to face target.
        # TODO fix it so that it works
        #entity.quaternion = quaternion
        #entity.__dirtyRotation = true

        # Rotate the currente velocity towards the target.
        neededVelocity = currentVelocity.clone().applyQuaternion(quaternion)
        entity.applyCentralForce(neededVelocity.sub(currentVelocity))
