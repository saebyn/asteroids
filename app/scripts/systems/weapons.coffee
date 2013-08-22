# weapons system
define ['systems/base', 'underscore', 'utils', 'THREE'], (System, _, utils, THREE) ->
  fireWeapon = (app, entity) ->
    speed = entity.fireable.speed or 1.0
    size = entity.fireable.size or 1.0

    z = app.entities.player.renderable.mesh.rotation.z
    direction = new THREE.Vector3(Math.cos(z), Math.sin(z), 0)

    app.emit('fire')

    # move the position so that the entire projectile is outside of
    #  the player mesh

    # From player position
    position = new THREE.Vector3(
      app.entities.player.position.x,
      app.entities.player.position.y,
      app.entities.player.position.z or 0)

    # move away size amount
    position.add(direction.multiplyScalar(size))

    projectile = 
      position:
        x: position.x
        y: position.y
        z: position.z
        direction: {x: 0, y: 0, z: z}
      movement:
        direction: direction.multiplyScalar(speed / 1000.0)
        spin: {x: 0, y: 0, z: 0}
    
    app.addEntity(
      _.defaults(projectile, utils.clone(entity.fireable.extraComponents)))

  class WeaponsSystem extends System
    constructor: (@app) ->
      @processOurEntities = _.throttle(@unthrottledProcess, 150, {trailing: false})

    unthrottledProcess: (entities, elapsedTime) =>
      if @app.controlFiring
        fireWeapon(@app, components) for [id, components] in entities when components?.position