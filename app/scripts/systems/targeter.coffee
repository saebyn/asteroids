define ['systems/base'], (System) ->
  class TargeterSystem extends System
    process: (entity, elapsed, id) ->
      if entity.targeter.queue.length > 0
        # Take the most recently targeted object
        newTarget = entity.targeter.queue[entity.targeter.queue.length-1]
        # Clear out the queue of targets
        entity.targeter.queue = []

        # Same target, do nothing.
        if newTarget == entity.targeter.target
          return

        # New target doesn't exist, do nothing.
        if newTarget not of @app.entities
          return

        # Disable the old target, if any
        if entity.targeter.target and entity.targeter.target of @app.entities
          oldTargetEntity = @app.entities[entity.targeter.target]
          if oldTargetEntity.targeted?
            oldTargetEntity.targeted.enabled = false

        # Add targeted component to new target
        if not @app.entities[newTarget].targeted
          @app.entities.addComponent('targeted', {enabled: true}, newTarget)
        else
          @app.entities[newTarget].targeted.enabled = true

        # Set the current target
        entity.targeter.target = newTarget
