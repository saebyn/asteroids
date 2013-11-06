# spawners system
define ['systems/base', 'underscore', 'utils', 'THREE'], (System, _, utils, THREE) ->
  pickEntity = (id, entity, elapsedTime) ->
    rate = entity.spawnable.rate * elapsedTime / 1000.0
    rate > Math.random()

  addEntity = (app, id, entity) ->
    # XXX TODO replace with something else that works with app.scene
    count = _.chain(app.scene.children)
      .pluck('spawned')
      .filter((x) -> x == id)
      .size()
      .value()
    
    if count >= entity.spawnable.max
      console.log 'exceeded count'
      return

    radius = entity.spawnable.radius

    # Spawn radius distance from the origin
    position = utils.randomVectorOnSphere(radius)

    speed = Math.random() * 0.05 + 0.01

    rotationSpeed = Math.random() * 0.01

    # TODO add some jitter to the direction?
    direction = new THREE.Vector3(-position.x, -position.y, -position.z).normalize().multiplyScalar(speed)

    spawn =
      spawned: id
      position:
        x: position.x
        y: position.y
        z: position.z
        direction:
          x: Math.random() * 2.0 * Math.PI
          y: Math.random() * 2.0 * Math.PI
          z: Math.random() * 2.0 * Math.PI
      movement:
        spin: new THREE.Vector3(
                Math.random() - 0.5,
                Math.random() - 0.5,
                Math.random() - 0.5).normalize().multiplyScalar(rotationSpeed)
        direction:
          x: direction.x
          y: direction.y
          z: direction.z

    app.scene.addEntity(_.defaults(spawn, utils.clone(entity.spawnable.extraComponents)))

  updateRates = (entity, elapsedTime) ->
    entity.spawnable.rate += entity.spawnable.rateChange * entity.spawnable.rate * elapsedTime / 1000.0

  class SpawnersSystem extends System
    constructor: (@app) ->
      @app.subscribe 'death', =>
        # Remove all spawned entities
        @app.scene.removeEntity(entity) for entity in @app.scene.children when entity.spawned?

    processOurEntities: (entities, elapsedTime) ->
      # pick which ones we want to spawn
      picks = _.filter(
        entities,
        ([id, components]) ->
          pickEntity(id, components, elapsedTime)
      )

      # add entities for the selected spawned objects
      addEntity(@app, id, components) for [id, components] in picks

      # update rates for all entities
      updateRates(components, elapsedTime) for [id, components] in entities
