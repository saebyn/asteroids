define ['systems/base', 'THREE'], (System, THREE) ->
  class FollowSystem extends System
    process: (entity, elapsed, id) ->
      if not entity.follow.quaternion?
        entity.follow.quaternion = new THREE.Quaternion()

      # get position of entity
      followedObj = @app.scene.getObjectByName(entity.follow.entity)
      thisObj = @app.scene.getObjectByName(id)
      if followedObj? and thisObj?
        doRotate = true
        if entity.follow.x == 0 and entity.follow.y == 0 and entity.follow.z == 0
          doRotate = false

        # TODO save some math if the follow distance is 0,0,0
        # move this object to a position relative to it
        position = new THREE.Vector3(
          entity.follow.x, entity.follow.y, entity.follow.z)

        position.add(followedObj.position)
        if doRotate
          position.applyQuaternion(entity.follow.quaternion)

        # Make the movement of the following smooth
        # by transitioning between the current position and the desired
        # position.
        position.sub(thisObj.position).divideScalar(elapsed)

        thisObj.position.add(position)
        if doRotate
          # look at the entity
          thisObj.lookAt(followedObj.position)
