# damage system
define ['systems/base', 'THREE', 'utils'], (System, THREE, utils) ->
  randomDirection = (v) ->
    # Locking on XY plane
    new THREE.Vector3(Math.random() * v, Math.random() * v, 0).normalize()

  distant = (points, radius) ->
    _.all(points, (p) ->
      _.all(points, (q) ->
        p.distanceTo(q) > radius or p is q
      )
    )

  # Pick `number` points that are all at least 2*radius
  # distance from all other picked points.
  pickRandomPointsDistant = (radius, origin, number) ->
    angle = 2.0 * Math.PI / number
    spacing = 5.0
    spacingRadius = (radius + spacing) / (2.0 * Math.sin(angle / 2.0))
    
    gen = (i) ->
      point:
        x: origin.x + Math.cos(angle * i) * spacingRadius
        y: origin.y + Math.sin(angle * i) * spacingRadius
        z: 0
      dir:
        x: Math.cos(angle * i)
        y: Math.sin(angle * i)
        z: 0
        
    gen(i) for i in [0...number]

  class DamageSystem extends System
    registerCollisions: (id, entity) ->
      # listen for collisions on this mesh
      entity.renderable.mesh.addEventListener('collision', (damagerMesh) =>
        if damagerMesh.name of @app.entities
          damager = @app.entities[damagerMesh.name]
          if damager.damaging?.health?
            entity.damagable.health -= damager.damaging.health

          if damager.damaging?.destroysSelf?
            @app.emit('hit')
            @app.removeEntity(damagerMesh.name)

        if entity.damagable.health <= 0
          @app.destroyEntity(id)

          # If there's a chance this object will fracture rather than
          # simply being atomized...
          if entity.damagable.fracture?.chance?
            count = (Math.random() * 4 + 2) | 0
            if Math.random() < entity.damagable.fracture.chance
              generatable = utils.clone(entity.damagable.fracture.generatable)
              if not entity.renderable?.mesh?
                return

              generatable.radius = entity.renderable.mesh.geometry.boundingSphere.radius / count

              origin = new THREE.Vector3(entity.position.x,
                                         entity.position.y,
                                         entity.position.z)
              positions = pickRandomPointsDistant(2.0 * generatable.radius,
                                                  origin,
                                                  count)

              movement = entity._movement or entity.movement

              if entity.renderable.mesh?._physijs?.linearVelocity?
                originalDirection = entity.renderable.mesh._physijs.linearVelocity
              else
                originalDirection = new THREE.Vector3(movement.direction.x,
                                                      movement.direction.y,
                                                      movement.direction.z)

              getMoveDirection = (v) ->
                new THREE.Vector3(v.x, v.y, v.z).add(originalDirection).divideScalar(2.0)

              @app.addEntity(
                _type: entity._type
                position:
                  x: positions[x].point.x
                  y: positions[x].point.y
                  z: positions[x].point.z
                  direction: utils.clone(entity.position.direction)
                movement:
                  direction: getMoveDirection(positions[x].dir)
                  spin: movement.spin.clone()
                damagable:
                  health: (Math.random() * 3 + 1) | 0
                damaging:
                  health: entity.damaging.health
                generatable: generatable
              ) for x in [0...count]
      )
      entity.damagable._registered = true

    processOurEntities: (entities, elapsedTime) ->
      @registerCollisions(id, entity) for [id, entity] in entities when entity.renderable?.mesh? and not entity.damagable._registered?
