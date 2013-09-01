# expire system
define ['systems/base', 'THREE'], (System, THREE) ->
  class ExpireSystem extends System
    expire: (id, entity, elapsedTime) ->
      expirable = entity.expirable
      expirable.time -= elapsedTime

      if expirable.time <= 0
        if expirable.stop
          if entity.renderable?.mesh?
            object = entity.renderable.mesh
            object.setLinearVelocity(new THREE.Vector3(0, 0, 0))
            object.setAngularVelocity(new THREE.Vector3(0, 0, 0))

        if expirable.destroy
          if expirable.explodes
            @app.destroyEntity(id)
          else
            @app.removeEntity(id)

        delete entity.expirable

    processOurEntities: (entities, elapsedTime) ->
      @expire(id, components, elapsedTime) for [id, components] in entities
