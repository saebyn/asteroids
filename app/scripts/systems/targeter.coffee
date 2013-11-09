define ['systems/base'], (System) ->
  class TargeterSystem extends System
    process: (entity, elapsed) ->
      if entity.targeter.queue.length > 0
        # Take the most recently targeted object
        newTarget = entity.targeter.queue[entity.targeter.queue.length-1]
        # Clear out the queue of targets
        entity.targeter.queue = []

        # Same target, do nothing.
        if newTarget == entity.targeter.target
          return

        # New target doesn't exist, do nothing.
        newTargetEntity = @app.scene.getObjectById(newTarget)
        if not newTargetEntity?
          return

        # Disable the old target, if any
        oldTargetEntity = @app.scene.getObjectById(entity.targeter.target)
        if entity.targeter.target and oldTargetEntity
          if oldTargetEntity.targeted?
            oldTargetEntity.targeted.enabled = false

        # Add targeted component to new target
        if not newTargetEntity?.targeted
          @app.scene.addComponent('targeted', {enabled: true}, newTarget)
        else
          newTargetEntity.targeted.enabled = true

        # Set the current target
        entity.targeter.target = newTarget
