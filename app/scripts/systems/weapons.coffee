# weapons system
define ['underscore', 'utils'], (_, utils) ->
  fireWeapon = (app, entity) ->
    speed = entity.fireable.speed or 1.0
    direction =
      x: Math.cos(app.entities.player.position.direction.z) * speed
      y: Math.sin(app.entities.player.position.direction.z) * speed

    projectile = 
      position: utils.clone app.entities.player.position
      moveable:
        direction: direction
      renderable: _.clone(entity.fireable.renderable)

    if entity.fireable.expireTime?
      projectile.expirable =
        time: entity.fireable.expireTime

    app.addEntity(projectile)

  _.throttle((app, entities, elapsedTime) ->
    if app.controlFiring
      fireWeapon(app, components) for [id, components] in entities when components?.position
  , 150, {trailing: false})
