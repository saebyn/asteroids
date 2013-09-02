define ['systems/base', 'THREE', 'shaders/radar'], (System, THREE, radarShader) ->
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

      if camera.radar
        shaders = radarShader.shaders
        camera.radar = {}
        camera.radar.uniforms = THREE.UniformsUtils.clone(radarShader.uniforms)
        @updateRadarSize(camera)
        radarMaterial = new THREE.ShaderMaterial(
          fragmentShader: shaders.fragmentShader
          vertexShader: shaders.vertexShader
          uniforms: camera.radar.uniforms
          transparent: true
        )
        camera.material = radarMaterial

    updateRadarSize: (camera) ->
      if camera.radar?
        camera.radar.uniforms.resolution.value.x = @app.getGameWidth() * (camera.view?.width or 1)
        camera.radar.uniforms.resolution.value.y = @app.getGameHeight() * (camera.view?.height or 1)

    updateRadarTime: (camera, elapsedTime) ->
      if camera.radar?
        camera.radar.uniforms.time.value += elapsedTime

    updateAspect: (camera, def) ->
      camera.camera.aspect = @app.getGameWidth() / @app.getGameHeight()
      camera.camera.updateProjectionMatrix()
      @updateRadarSize(def)
    
    processOurEntities: (entities, elapsed) ->
      @registerCamera(id, components.camera) for [id, components] in entities when not components.camera.registered?

      @updateAspect(@app.cameras[id], components.camera) for [id, components] in entities when components.camera.registered?

      @updateRadarTime(components.camera, elapsed) for [id, components] in entities when components.camera.registered?
