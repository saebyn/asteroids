# movement system
define ['systems/base', 'THREE'], (System, THREE) ->
  moveEntity = (entity, elapsedTime) ->
    if entity._physijs? and entity?.renderable?.meshLoaded?
      entity.setLinearVelocity(
        entity.movement.direction.clone().multiplyScalar(1000.0))

      if entity.movement.spin
        entity.setAngularVelocity(
          entity.movement.spin.clone().multiplyScalar(1000.0))

      entity._movement = entity.movement
      delete entity.movement

  class MovementSystem extends System
    process: (entity, elapsedTime) ->
      moveEntity(entity, elapsedTime)
