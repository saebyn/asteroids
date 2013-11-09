# weapons system
define ['systems/base', 'underscore', 'utils', 'THREE'], (System, _, utils, THREE) ->
  class WeaponsSystem extends System
    constructor: (@app) ->
      # Override fireWeapon method with throttled version.
      @fireWeapon = _.throttle(@fireWeapon, 260, {trailing: false})

    # Entity should have inventory and fireable components
    fireWeapon: (entity) =>
      if entity.fireable.inventorySource?
        if (entity.inventory[entity.fireable.inventorySource] or 0) <= 0
          @app.emit('weaponEmpty')
          return
        else
          entity.inventory[entity.fireable.inventorySource] -= 1
          @app.emit('inventory:change', entity.fireable.inventorySource, entity.inventory[entity.fireable.inventorySource])

      speed = entity.fireable.speed or 1.0
      size = entity.fireable.size or 1.0

      # Can't do anything if this stuff doesn't exist
      player = @app.scene.getObjectById('player')

      if not player?.renderable?.meshLoaded?
        return

      direction = new THREE.Vector3(1, 0, 0).applyQuaternion(player.quaternion)

      @app.emit('fire')

      # move the position so that the entire projectile is outside of
      #  the player mesh

      # From player position
      position = player.position.clone()

      # move away size amount
      position.add(direction.clone().multiplyScalar(size))
      direction.multiplyScalar(speed / 1000.0)

      projectile = _.defaults(
        position: position
        rotation: player.rotation
        movement:
          direction: direction
          spin: new THREE.Vector3(0, 0, 0)
      , utils.clone(entity.fireable.extraComponents))
      
      @app.scene.addEntity(projectile)

    drawRange: (fireable) ->
      player = @app.scene.getObjectById('player')
      if not player?.renderable?.meshLoaded?
        return

      material = new THREE.LineDashedMaterial(
        color: 0xffffff
        opacity: 0.3
        depthTest: false
        transparent: true
        linewidth: 1
        dashSize: 3
        gapSize: 3
      )
      geometry = new THREE.Geometry()
      scale = 100.0
      width = 2
      offset = 20
      far = 300.0

      geometry.vertices.push(new THREE.Vector3(offset, 0, 0))
      geometry.vertices.push(new THREE.Vector3(offset + scale, scale/width, scale/width))

      geometry.vertices.push(new THREE.Vector3(offset, 0, 0))
      geometry.vertices.push(new THREE.Vector3(offset + scale, scale/width, -scale/width))

      geometry.vertices.push(new THREE.Vector3(offset, 0, 0))
      geometry.vertices.push(new THREE.Vector3(offset + scale, -scale/width, -scale/width))

      geometry.vertices.push(new THREE.Vector3(offset, 0, 0))
      geometry.vertices.push(new THREE.Vector3(offset + scale, -scale/width, scale/width))

      geometry.vertices.push(new THREE.Vector3(offset + scale, scale/width, scale/width))
      geometry.vertices.push(new THREE.Vector3(offset + scale, scale/width, -scale/width))

      geometry.vertices.push(new THREE.Vector3(offset + scale, scale/width, -scale/width))
      geometry.vertices.push(new THREE.Vector3(offset + scale, -scale/width, -scale/width))

      geometry.vertices.push(new THREE.Vector3(offset + scale, -scale/width, -scale/width))
      geometry.vertices.push(new THREE.Vector3(offset + scale, -scale/width, scale/width))

      geometry.vertices.push(new THREE.Vector3(offset + scale, -scale/width, scale/width))
      geometry.vertices.push(new THREE.Vector3(offset + scale, scale/width, scale/width))

      geometry.vertices.push(new THREE.Vector3(offset, 0, 0))
      geometry.vertices.push(new THREE.Vector3(offset + far, 0, 0))
      geometry.computeLineDistances()

      fireable.rendered = new THREE.Line(geometry, material, THREE.LinePieces)

      player.add fireable.rendered

    processOurEntities: (entities, elapsedTime) =>
      @drawRange(components.fireable) for [id, components] in entities when not components.fireable.rendered?
      @fireWeapon(components) for [id, components] in entities when components.position? and components.controllable?.controlFiring
