define ['systems/base', 'THREE'], (System, THREE) ->
  class FollowSystem extends System
    process: (entity, elapsed, id) ->
      if not entity.follow.quaternion?
        entity.follow.quaternion = new THREE.Quaternion()

      # get position of entity
      followedObj = @app.scene.getObjectByName(entity.follow.entity)
      thisObj = @app.scene.getObjectByName(id)
      if followedObj? and thisObj?
        # move this object to a position relative to it
        position = new THREE.Vector3(
          entity.follow.x, entity.follow.y, entity.follow.z)

        position.add(followedObj.position)
        position.applyQuaternion(entity.follow.quaternion)

        # Make the movement of the following smooth
        # by transitioning between the current position and the desired
        # position.
        position.sub(thisObj.position).divideScalar(elapsed)

        thisObj.position.add(position)
        # look at the entity
        thisObj.lookAt(followedObj.position)
