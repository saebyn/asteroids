# movement system
define ['systems/base', 'THREE'], (System, THREE) ->
  moveEntity = (entity, elapsedTime) ->
    if entity?.renderable?.mesh?
      mesh = entity.renderable.mesh

      mesh.setLinearVelocity(
        x: entity.movement.direction.x * 1000.0,
        y: entity.movement.direction.y * 1000.0,
        z: (entity.movement.direction.z or 0) * 1000.0)

      if entity.movement.spin
        mesh.setAngularVelocity(
          new THREE.Vector3(
            entity.movement.spin.x * 1000.0,
            entity.movement.spin.y * 1000.0,
            (entity.movement.spin.z or 0) * 1000.0))

      delete entity.movement

  class MovementSystem extends System
    processOurEntities: (entities, elapsedTime) ->
      moveEntity(components, elapsedTime) for [id, components] in entities
