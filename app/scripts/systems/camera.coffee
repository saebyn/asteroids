define ['systems/base', 'THREE', 'shaders/radar'], (System, THREE, radarShader) ->
  class CameraSystem extends System
    attachCamera: (camera) ->
      if not camera.instance.parent?
        @app.scene.add camera.instance

    registerCamera: (id, camera) ->
      if camera.type == 'perspective'
        cameraInst = new THREE.PerspectiveCamera(camera.viewAngle, camera.aspect, camera.nearDistance, camera.farDistance)
      else if camera.type = 'ortho'
        cameraInst = new THREE.OrthographicCamera(camera.left, camera.right, camera.top, camera.bottom, camera.nearDistance, camera.farDistance)
      else
        throw new Exception('Unknown camera type: ' + camera.type)

      if camera.position?
        cameraInst.position.x = camera.position.x
        cameraInst.position.y = camera.position.y
        cameraInst.position.z = camera.position.z

      cameraInst.name = id
      camera.instance = cameraInst
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
      camera.radar.uniforms.time.value += elapsedTime

    updateAspect: (camera) ->
      aspect = camera.instance.aspect
      camera.instance.aspect = @app.getGameWidth() / @app.getGameHeight()
      if aspect != camera.instance.aspect
        camera.instance.updateProjectionMatrix()
        @updateRadarSize(camera)

    render: (camera) ->
      windowWidth = @app.getGameWidth()
      windowHeight = @app.getGameHeight()
      # From http://mrdoob.github.io/three.js/examples/webgl_multiple_views.html
      if camera.view?
        left = Math.floor(windowWidth * camera.view.left)
        bottom = Math.floor(windowHeight * camera.view.bottom)
        width = Math.floor(windowWidth * camera.view.width)
        height = Math.floor(windowHeight * camera.view.height)
      else
        left = 0
        bottom = 0
        width = windowWidth
        height = windowHeight

      @app.renderer.setViewport(left, bottom, width, height)
      @app.renderer.setScissor(left, bottom, width, height)
      @app.renderer.enableScissorTest(true)
      @app.renderer.setClearColor(
        camera.view?.background or '#000000', 
        camera.view?.backgroundAlpha or 1
      )

      if camera.material?
        @app.scene.overrideMaterial = camera.material
      else
        @app.scene.overrideMaterial = undefined

      if camera.composer?
        @app.renderPass.camera = camera.instance
        @app.composer.render()
      else
        @app.renderer.render(@app.scene, camera.instance)

    shake: (camera, elapsed) ->
      # queue a series of movements
      camera.instance.position.x += (Math.random() - 0.5) * camera.shake
      camera.instance.position.y += (Math.random() - 0.5) * camera.shake
      camera.instance.position.z += (Math.random() - 0.5) * camera.shake

    process: (entity, id, elapsed) ->
      if not entity.camera.registered?
        @registerCamera(id, entity.camera)

      @attachCamera(entity.camera)
      @updateAspect(entity.camera)

      if entity.camera.shake?
        @shake(entity.camera, elapsed)

      if entity.camera.radar?
        @updateRadarTime(entity.camera, elapsed)

    processOurEntities: (entities, elapsed) ->
      @process(entity, id, elapsed) for [id, entity] in entities

      orderedCameras = _.chain(entities)
                        .filter(([id, components]) ->
                          components.camera.instance?
                        ).sortBy(([id, components]) ->
                          components.camera.order or Number.MAX_VALUE
                        ).value()

      console.time('camera render')
      @render(components.camera) for [id, components] in orderedCameras
      console.timeEnd('camera render')
