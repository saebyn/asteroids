define ['systems/base', 'THREE'], (System, THREE) ->
  TARGETING_OBJECT_NAME = 'targeting_indicator'
  # Size of canvas width and height. Should be a power of 2.
  CANVAS_SIZE = 1024
  # Margin of target indicator, in world units
  INDICATOR_MARGIN = 10

  class TargetedSystem extends System
    unregisterEntity: (entity) ->
      if entity.targeted?.registered?
        entity.targeted.registered = false
        targetingReticuleMesh = entity.getObjectById(entity.id + ':' + TARGETING_OBJECT_NAME)
        if targetingReticuleMesh
          entity.remove(targetingReticuleMesh)

    registerEntity: (entity) ->
      # If the entity doesn't have the targeting indicator attached, attach it.
      if entity.targeted? and not entity.targeted.registered
        # We'll need to attach the canvas to the component for later access.
        # We can use its presence to determine if we added the targeting
        # indicator.

        # Create canvas
        canvas = document.createElement('canvas')
        canvas.width = CANVAS_SIZE
        canvas.height = CANVAS_SIZE
        context = canvas.getContext('2d')

        image = @app.assetManager.images['images/targeting.png']
        context.drawImage(image, 0, 0)

        #context.fillStyle = 'rgba(255,255,255,0.9)'
        #context.font = 'bold 252px sans-serif'
        #context.fillText('Hello', 50, 200)
        #context.fillText('World', 50, 600)

        # Create material from canvas
        texture = new THREE.Texture(canvas)
        material = new THREE.MeshLambertMaterial(
          map: texture
          transparent: true
          depthTest: false
        )

        # Create square geometry and targetingReticuleMesh
        geom = new THREE.PlaneGeometry(INDICATOR_MARGIN * 2, INDICATOR_MARGIN * 2)

        rotationMatrix = new THREE.Matrix4()
        rotationMatrix.makeRotationFromEuler(new THREE.Euler(0, 0, 0))
        geom.applyMatrix(rotationMatrix)

        targetingReticuleMesh = new THREE.Mesh(geom, material)

        targetingReticuleMesh.id = entity.id + ':' + TARGETING_OBJECT_NAME

        # Attach targetingReticuleMesh to parent entity
        entity.add(targetingReticuleMesh)
        texture.needsUpdate = true
        entity.targeted.registered = true

      entity

    process: (entity, elapsed) ->
      targetingReticuleMesh = entity.getObjectById(entity.id + ':' + TARGETING_OBJECT_NAME)
      if entity.targeted.registered and targetingReticuleMesh
        if not entity.targeted.enabled
          # If the targeting is disabled, hide it from the scene.
          targetingReticuleMesh.visible = false
        else
          targetingReticuleMesh.visible = true
          # Reposition on top of target entity
          targetingReticuleMesh.position.copy(entity.position)

          # Scale targetingReticuleMesh to size
          size = entity.geometry.boundingSphere.radius + INDICATOR_MARGIN * 2
          targetingReticuleMesh.scale = new THREE.Vector3(1, 1, 1).multiplyScalar(size / INDICATOR_MARGIN)

          # Draw things on canvas (distance?)

          # Billboard by looking at the camera.
          camera = @app.scene.getObjectById('camera')
          targetingReticuleMesh.lookAt(camera.position) if camera
