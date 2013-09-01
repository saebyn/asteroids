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

  damage = (system, damager, entityId, entity) ->
    if damager?
      if damager.damaging?.health?
        entity.damagable.health -= damager.damaging.health

      system.app.emit('hit')

    if entity.damagable.health <= 0
      if entity.damagable.disappears
        system.app.removeEntity(entityId)
      else
        system.app.destroyEntity(entityId)

      # If there's a chance this object will fracture rather than
      # simply being atomized...
      if entity.damagable.fracture?.chance? and entity.renderable?.mesh?
        system.app.addEntity(
          debris:
            spread: 1000
            radius: entity.renderable.mesh.geometry.boundingSphere.radius
          position:
            x: entity.position.x
            y: entity.position.y
            z: entity.position.z
          expirable:
            time: 1500

        )

        system.fracture(entity.damagable.fracture.chance,
                        entity.damagable.fracture.generatable,
                        entity.renderable.mesh,
                        entity.position,
                        entity._movement or entity.movement,
                        entity._type,
                        entity.damaging.health)

  collisionHandler = (system) ->
    (damagerMesh) ->
      entity = system.app.entities[this.name]
      if not entity?
        console.log 'got collision event on non-entity'
        return

      if damagerMesh.name of system.app.entities
        damager = system.app.entities[damagerMesh.name]

      damage(system, damager, this.name, entity)

      if damager?
        damage(system, entity, damagerMesh.name, damager)

  class DamageSystem extends System
    constructor: (@app) ->
      @collisionHandler = collisionHandler(this)

    fracture: (chance, generatable, mesh, position, movement, type, damage) ->
      if Math.random() < chance
        count = (Math.random() * 4 + 2) | 0
        generatable = utils.clone(generatable)

        generatable.radius = mesh.geometry.boundingSphere.radius / count

        origin = new THREE.Vector3(position.x, position.y, position.z)
        positions = pickRandomPointsDistant(2.0 * generatable.radius,
                                            origin,
                                            count)

        if mesh._physijs?.linearVelocity?
          originalDirection = mesh._physijs.linearVelocity
        else
          originalDirection = new THREE.Vector3(movement.direction.x,
                                                movement.direction.y,
                                                movement.direction.z)

        getMoveDirection = (v) ->
          d = new THREE.Vector3(v.x, v.y, v.z)
          d.add(originalDirection.divideScalar(2.0))
          d.normalize()
          d.multiplyScalar(originalDirection.length() / 1000)
          {x: d.x, y: d.y, z: d.z}

        @app.addEntity(
          _type: type
          position:
            x: positions[x].point.x
            y: positions[x].point.y
            z: positions[x].point.z
            direction: utils.clone(position.direction)
          movement:
            direction: getMoveDirection(positions[x].dir)
            spin: movement.spin.clone()
          damagable:
            health: (Math.random() * 3 + 1) | 0
          damaging:
            health: damage
          generatable: generatable
        ) for x in [0...count]

    # Hook up collision detection
    registerCollisions: (id, entity) ->
      # listen for collisions on this mesh
      entity.renderable.mesh.addEventListener('collision', @collisionHandler)
      entity.damagable._registered = true

    processOurEntities: (entities, elapsedTime) ->
      # XXX TODO
      # This sucks because we look over all entities that have the component on
      # each game loop.
      # Instead, we should have a way of telling the gameloop how to filter out
      # the entities we are interested in...
      @registerCollisions(id, entity) for [id, entity] in entities when entity.renderable?.mesh? and not entity.damagable._registered?
