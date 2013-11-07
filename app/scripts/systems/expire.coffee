# expire system
define ['systems/base', 'THREE'], (System, THREE) ->
  class ExpireSystem extends System
    expire: (id, entity, elapsedTime) ->
      expirable = entity.expirable
      # sometimes this breaks... trying to debug it XXX
      if not expirable
        debugger
      expirable.time -= elapsedTime

      if expirable.time <= 0
        if expirable.stop
          if entity.renderable?
            entity.setLinearVelocity(new THREE.Vector3(0, 0, 0))
            entity.setAngularVelocity(new THREE.Vector3(0, 0, 0))

        if expirable.destroy
          if expirable.explodes
            @app.scene.destroyEntity(id)
          else
            @app.scene.removeEntity(id)

        delete entity.expirable

    processOurEntities: (entities, elapsedTime) ->
      @expire(id, components, elapsedTime) for [id, components] in entities
