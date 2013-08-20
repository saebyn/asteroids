define ['systems/base', 'THREE'], (System, THREE) ->
  class CameraSystem extends System
    registerCamera: (id, camera) ->
      if camera.type == 'perspective'
        cameraInst = new THREE.PerspectiveCamera(camera.viewAngle, camera.aspect, camera.nearDistance, camera.farDistance)
      else if camera.type = 'ortho'
        cameraInst = new THREE.OrthographicCamera(camera.left, camera.right, camera.top, camera.bottom, camera.nearDistance, camera.farDistance)

      if cameraInst
        if camera.position?
          cameraInst.position.x = camera.position.x
          cameraInst.position.y = camera.position.y
          cameraInst.position.z = camera.position.z

        @app.registerCamera(id, cameraInst, camera.order?)
        camera.registered = true

    updateAspect: (camera) ->
      if camera.aspect?
        camera.aspect = @app.getGameWidth() / @app.getGameHeight()
        camera.updateProjectionMatrix()
    
    processOurEntities: (entities, elapsed) ->
      @registerCamera(id, components.camera) for [id, components] in entities when not components.camera.registered?

      @updateAspect(@app.cameras[id]) for [id, components] in entities when components.camera.registered?
