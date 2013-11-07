define ['systems/base', 'THREE'], (System, THREE) ->
  class FollowSystem extends System
    process: (entity, elapsed, id) ->
      if not entity.follow.quaternion?
        entity.follow.quaternion = new THREE.Quaternion()

      # get position of entity
      followedObj = @app.scene.getObjectById(entity.follow.entity)
      thisObj = @app.scene.getObjectById(id)
      if followedObj?.position? and thisObj?.position?
        doRotate = true
        # save some math if the follow distance is 0,0,0
        if entity.follow.vector.x == 0 and entity.follow.vector.y == 0 and entity.follow.vector.z == 0
          doRotate = false

        # move this object to a position relative to what it follows
        position = entity.follow.vector.clone()

        if doRotate
          position.applyQuaternion(entity.follow.quaternion)

        position.add(followedObj.position)
        position.sub(thisObj.position)

        if entity.follow.smooth
          # Make the movement of the following smooth
          # by transitioning between the current position and the desired
          # position.
          segmentPortions = 1000.0 / elapsed
          position.divideScalar(segmentPortions)

        thisObj.position.add(position)

        if doRotate
          # look at the entity
          thisObj.lookAt(followedObj.position)
