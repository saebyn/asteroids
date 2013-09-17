# weapons system
define ['systems/base', 'underscore', 'utils', 'THREE'], (System, _, utils, THREE) ->
  class WeaponsSystem extends System
    constructor: (@app) ->
      @fireWeapon = _.throttle(@fireWeapon, 160, {trailing: true})

    fireWeapon: (entity) =>
      speed = entity.fireable.speed or 1.0
      size = entity.fireable.size or 1.0

      # Can't do anything if this stuff doesn't exist
      if not @app.entities.player?.renderable?.mesh?
        return

      rotation = @app.entities.player.renderable.mesh.rotation
      direction = new THREE.Vector3(1, 0, 0).applyEuler(rotation)

      @app.emit('fire')

      # move the position so that the entire projectile is outside of
      #  the player mesh

      # From player position
      position = new THREE.Vector3(
        @app.entities.player.position.x,
        @app.entities.player.position.y,
        @app.entities.player.position.z or 0)

      # move away size amount
      position.add(direction.multiplyScalar(size))

      projectile = 
        position:
          x: position.x
          y: position.y
          z: position.z
          direction:
            x: rotation.x
            y: rotation.y
            z: rotation.z
        movement:
          direction: direction.multiplyScalar(speed / 1000.0)
          spin: {x: 0, y: 0, z: 0}
      
      @app.entities.addEntity(
        _.defaults(projectile, utils.clone(entity.fireable.extraComponents)))

    drawRange: (fireable) ->
      player = @app.entities.player
      if not player?.renderable?.mesh?
        return

      material = new THREE.LineDashedMaterial(
        color: 0xa5a5a5
        blending: THREE.MultiplyBlending
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

      player.renderable.mesh.add fireable.rendered
      player.renderable.mesh.addEventListener 'removed', ->
        if fireable.rendered?
          fireable.rendered.remove()

    processOurEntities: (entities, elapsedTime) =>
      @drawRange(components.fireable) for [id, components] in entities when not components.fireable.rendered?
      @fireWeapon(components) for [id, components] in entities when components.position? and components.controllable?.controlFiring
