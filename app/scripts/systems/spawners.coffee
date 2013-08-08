# spawners system
define ['underscore', 'utils'], (_, utils) ->
  pickEntity = (id, entity, elapsedTime) ->
    rate = entity.spawnable.rate * elapsedTime / 1000.0
    rate > Math.random()

  addEntity = (app, id, entity) ->
    radius = entity.spawnable.radius

    # Spawn radius distance from the origin
    sourceRotation = Math.PI * 2.0 * Math.random()
    x = Math.cos(sourceRotation) * radius
    y = Math.sin(sourceRotation) * radius

    speed = Math.random() * 0.05 + 0.01

    direction = new THREE.Vector2(-x, -y).normalize().multiplyScalar(speed)

    spawn =
      position:
        x: x
        y: y
        z: null
        direction:
          x: 0
          y: 0
          z: Math.atan2(direction.y, direction.x)
      moveable:
        direction:
          x: direction.x
          y: direction.y

    app.addEntity(_.defaults(spawn, utils.clone(entity.spawnable.extraComponents)))

  updateRates = (entity, elapsedTime) ->
    entity.spawnable.rate += entity.spawnable.rateChange * entity.spawnable.rate * elapsedTime / 1000.0

  (app, entities, elapsedTime) ->
    # pick which ones we want to spawn
    picks = _.filter(
      entities,
      ([id, components]) ->
        pickEntity(id, components, elapsedTime)
    )

    # add entities for the selected spawned objects
    addEntity(app, id, components) for [id, components] in picks

    # update rates for all entities
    updateRates(components, elapsedTime) for [id, components] in entities
