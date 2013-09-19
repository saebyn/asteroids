# seeking system
define ['systems/base', 'THREE'], (System, THREE) ->
  class TargetingSystem extends System
    # find any entities in @app.entities
    #  that have a _type == entity.seeking.type
    getEntities: (type) ->
      entity.renderable.mesh for id, entity of @app.entities when entity.renderable?.mesh? and entity._type == type

    seekNearest: (entity, elapsedTime) ->
      # We can't target if we don't have a mesh to move or a position
      if not entity.position? or not entity.renderable?.mesh?
        return

      origin = new THREE.Vector3(entity.position.x, entity.position.y, entity.position.z)

      #  calculate the distance to each one from this entity
      objects = @getEntities(entity.seeking.type)

      if objects.length > 0
        objects.sort((a, b) ->
          a.position.distanceTo(origin) - b.position.distanceTo(origin)
        )

        # take the closest one
        target = objects[0].position
        distance = target.distanceTo(origin)

        currentVector = entity.renderable.mesh.getLinearVelocity()

        # apply force in the direction of the closest one
        force = target.clone().sub(origin)
        entity.renderable.mesh.rotation.z = Math.atan2(force.y, force.x)
        entity.renderable.mesh.__dirtyRotation = true

        # Remove our current direction so that we will apply force
        # in opposition to it. Then normalize to a unit-vector for
        # the desired direction.
        force.normalize()

        # Multiply in the force we can apply in the desired direction.
        force.multiplyScalar(entity.seeking.force)

        entity.renderable.mesh.applyCentralForce(force)

    processOurEntities: (entities, elapsedTime) ->
      @seekNearest(components, elapsedTime) for [id, components] in entities
