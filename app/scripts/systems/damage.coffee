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
        z: origin.z
      dir:
        x: Math.cos(angle * i)
        y: Math.sin(angle * i)
        z: 0
        
    gen(i) for i in [0...number]

  damage = (system, damager, entity) ->
    if damager?
      if damager.damaging?.health?
        entity.damagable.health -= damager.damaging.health

      system.app.emit('hit', entity.id)

    if entity.damagable.health <= 0
      if entity.damagable.disappears
        system.app.scene.removeEntity(entity.id)
      else
        system.app.scene.destroyEntity(entity.id)

      # If there's a chance this object will fracture rather than
      # simply being atomized...
      if entity.damagable.fracture?.chance? and entity.renderable?.meshLoaded?
        system.app.scene.addEntity(
          debris:
            spread: 1000
            radius: entity.geometry.boundingSphere.radius
          position: entity.position.clone()
          expirable:
            time: 1500

        )

        system.fracture(entity.damagable.fracture.chance,
                        entity.damagable.fracture.generatable,
                        entity,
                        entity.position,
                        entity._movement or entity.movement,
                        entity.spawned,
                        entity.damaging.health)

  collisionHandler = (system) ->
    (damager) ->
      damage(system, damager, this)

      if damager?
        damage(system, this, damager)

  class DamageSystem extends System
    constructor: (@app) ->
      @collisionHandler = collisionHandler(this)

    fracture: (chance, generatable, mesh, position, movement, spawnType, damage) ->
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

        @app.scene.addEntity(
          spawned: spawnType
          position:
            x: positions[x].point.x
            y: positions[x].point.y
            z: positions[x].point.z
          rotation: utils.clone(position.direction)
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
    registerCollisions: (entity) ->
      # listen for collisions on this mesh
      entity.addEventListener('collision', @collisionHandler)
      entity.damagable._registered = true

    process: (entity, elapsedTime) ->
      # XXX TODO
      # This sucks because we look over all entities that have the component on
      # each game loop.
      # Instead, we should have a way of telling the gameloop how to filter out
      # the entities we are interested in...
      @registerCollisions(entity) if entity.renderable?.meshLoaded? and not entity.damagable._registered?
