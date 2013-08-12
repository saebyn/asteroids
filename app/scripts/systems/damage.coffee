# damage system
define ['systems/base'], (System) ->
  class DamageSystem extends System
    registerCollisions: (id, entity) ->
      # listen for collisions on this mesh
      entity.renderable.mesh.addEventListener('collision', (damagerMesh) =>
        if damagerMesh.name of @app.entities
          damager = @app.entities[damagerMesh.name]
          if damager.damaging?.health?
            entity.damagable.health -= damager.damaging.health

          if damager.damaging?.destroysSelf?
            @app.destroyEntity(damagerMesh.name)

        if entity.damagable.health <= 0
          @app.destroyEntity(id)
      )
      entity.damagable._registered = true

    processOurEntities: (entities, elapsedTime) ->
      @registerCollisions(id, entity) for [id, entity] in entities when entity.renderable?.mesh? and not entity.damagable._registered?
