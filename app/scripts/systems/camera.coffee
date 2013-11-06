define ['systems/base', 'THREE', 'shaders/radar', 'underscore'], (System, THREE, radarShader, _) ->
  class CameraSystem extends System
    registerCamera: (camera) ->
      if camera.camera.type == 'perspective'
        cameraInst = new THREE.PerspectiveCamera(camera.viewAngle, camera.aspect, camera.nearDistance, camera.farDistance)
      else if camera.camera.type = 'ortho'
        cameraInst = new THREE.OrthographicCamera(camera.left, camera.right, camera.top, camera.bottom, camera.nearDistance, camera.farDistance)
      else
        throw new Exception('Unknown camera type: ' + camera.camera.type)

      if camera.camera.radar
        shaders = radarShader.shaders
        camera.camera.radar = {}
        camera.camera.radar.uniforms = THREE.UniformsUtils.clone(radarShader.uniforms)
        @updateRadarSize(camera)
        radarMaterial = new THREE.ShaderMaterial(
          fragmentShader: shaders.fragmentShader
          vertexShader: shaders.vertexShader
          uniforms: camera.camera.radar.uniforms
          transparent: true
        )
        camera.camera.material = radarMaterial

      camera.camera.registered = true
      @app.scene.replaceEntity(camera, cameraInst)

    updateRadarSize: (camera) ->
      if camera.radar?
        camera.radar.uniforms.resolution.value.x = @app.getGameWidth() * (camera.view?.width or 1)
        camera.radar.uniforms.resolution.value.y = @app.getGameHeight() * (camera.view?.height or 1)

    updateRadarTime: (camera, elapsedTime) ->
      camera.radar.uniforms.time.value += elapsedTime

    updateAspect: (camera) ->
      aspect = camera.camera.aspect
      camera.camera.aspect = @app.getGameWidth() / @app.getGameHeight()
      if aspect != camera.camera.aspect
        camera.updateProjectionMatrix()
        @updateRadarSize(camera.camera)

    render: (camera) ->
      windowWidth = @app.getGameWidth()
      windowHeight = @app.getGameHeight()
      # From http://mrdoob.github.io/three.js/examples/webgl_multiple_views.html
      view = camera.camera.view
      if view?
        left = Math.floor(windowWidth * view.left)
        bottom = Math.floor(windowHeight * view.bottom)
        width = Math.floor(windowWidth * view.width)
        height = Math.floor(windowHeight * view.height)
      else
        left = 0
        bottom = 0
        width = windowWidth
        height = windowHeight

      @app.renderer.setViewport(left, bottom, width, height)
      @app.renderer.setScissor(left, bottom, width, height)
      @app.renderer.enableScissorTest(true)
      @app.renderer.setClearColor(
        view?.background or '#000000', 
        view?.backgroundAlpha or 1
      )

      if camera.camera.material?
        @app.scene.overrideMaterial = camera.camera.material
      else
        @app.scene.overrideMaterial = undefined

      if camera.camera.composer?
        @app.renderPass.camera = camera
        @app.composer.render()
      else
        @app.renderer.render(@app.scene, camera)

    shake: (camera, elapsed) ->
      # queue a series of movements
      camera.position.x += (Math.random() - 0.5) * camera.shake
      camera.position.y += (Math.random() - 0.5) * camera.shake
      camera.position.z += (Math.random() - 0.5) * camera.shake

    process: (entity, elapsed, id) ->
      if not entity.camera.registered?
        @registerCamera(entity)
        return

      @updateAspect(entity)

      if entity.camera.shake?
        @shake(entity.camera, elapsed)

      if entity.camera.radar?
        @updateRadarTime(entity.camera, elapsed)

    processOurEntities: (entities, elapsed) ->
      orderedCameras = _.chain(entities)
                        .filter(([id, components]) ->
                          components.camera.registered?
                        ).sortBy(([id, components]) ->
                          components.camera.order or Number.MAX_VALUE
                        ).value()

      console.time('camera render')
      @render(camera) for [id, camera] in orderedCameras
      console.timeEnd('camera render')

      @process(entity, elapsed, id) for [id, entity] in entities
