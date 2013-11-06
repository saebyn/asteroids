define ['systems', 'playerstats', 'assetmanager', 'scene', 'definitions', 'THREE', 'Physijs', 'jquery', 'underscore', 'utils', 'THREE.EffectComposer', 'THREE.RenderPass', 'THREE.ShaderPass', 'THREE.VignetteShader', 'THREE.RGBShiftShader', 'THREE.FilmShader'], (systems, PlayerStats, AssetManager, Scene, gameDefinitions, THREE, Physijs, $, _, utils) ->
  class Game
    fullscreen: false
    paused: true
    currentWeapon: 'plasma'

    lastTime: 0

    eventSubscribers: {}

    constructor: (@container, statsContainer) ->
      @assetManager = new AssetManager()
      @systems = systems.register(this)
      @playerStats = new PlayerStats(statsContainer, this)
      @scene = new Scene(this)

    setup: ->
      @setupThree()

      @subscribe 'controls:start', (action, detail) =>
        player = @scene.getObjectById('player')
        if action == 'steer'
          if player?.controllable?
            player.controllable.controlDirection = detail
        else if action == 'thrust'
          if player?.controllable?
            # TODO tune this
            player.controllable.controlThrust = 100.0
        else if action == 'fire'
          if player?.controllable?
            player.controllable.controlFiring = true
        else if action == 'pause'
          if @container.is(':visible')
            @togglePause()
        else if action == 'fullscreen'
          $('[data-fullscreen]').click()

      @subscribe 'controls:rotate', (x, y) =>
        xStep = Math.PI / 48
        yStep = Math.PI / 24
        camera = @scene.getObjectById('camera')
        if camera?.follow?.quaternion?
          rot = new THREE.Quaternion()
          rot.setFromEuler(new THREE.Euler(xStep * x, yStep * y, 0))
          camera.follow.quaternion.multiply(rot)

      @subscribe 'controls:stop', (action) =>
        player = @scene.getObjectById('player')
        if action == 'steer'
          if player?.controllable?
            player.controllable.controlDirection = false
        else if action == 'thrust'
          if player?.controllable?
            player.controllable.controlThrust = false
        else if action == 'fire'
          if player?.controllable?
            player.controllable.controlFiring = false

      projector = new THREE.Projector()
      raycaster = new THREE.Raycaster()

      @subscribe 'controls:pick', (x, y) =>
        player = @scene.getObjectById('player')
        camera = @scene.getObjectById('camera')
        # Don't bother if there's no camera or no player targeter component
        if camera? and player?.targeter?.queue
          vector = new THREE.Vector3(x, y, 1)
          projector.unprojectVector(vector, camera)
          v2 = vector.clone()

          raycaster.set(camera.position, vector.sub(camera.position).normalize())

          intersects = raycaster.intersectObjects(@scene.children)

          excludedEntities = ['player', 'rangeFinder']

          # Debug code to draw lines showing where the picking happens.
          #geom = new THREE.Geometry()
          #geom.vertices.push(camera.position)
          #geom.vertices.push(v2)
          #@scene.add(new THREE.Line(geom))

          # Add the target name to the player's targeter queue.
          player.targeter.queue.push(intersect.object.name) for intersect in intersects when intersect.object.name and intersect.object.name not in excludedEntities

      @subscribe 'controls:selectWeapon', (weapon) =>
        @currentWeapon = weapon
        player = @scene.getObjectById('player')
        if player?
          player.fireable = utils.clone(gameDefinitions.WEAPONS[weapon])

      @subscribe 'death', =>
        # TODO show some death message
        # Reset asteroid spawn rate
        asteroidSpawner = @scene.getObjectById('asteroidSpawner')
        asteroidSpawner.spawnable.rate = gameDefinitions.ASTEROID_SPAWN_RATE
        setTimeout(=>
          @scene.addEntity(utils.clone(gameDefinitions.PLAYER), 'player')
          @emit('start')
          @emit('controls:selectWeapon', @currentWeapon)
        , 5000)

      @emit('start')

    togglePause: ->
      @paused = not @paused
      $('#pause-continue').toggleClass('active')
      if @paused
        @emit('pause')

    subscribe: (event, callback) ->
      if event not of @eventSubscribers
        @eventSubscribers[event] = []

      @eventSubscribers[event].push(callback)

    emit: (event, data...) ->
      # Send this off so that if emit is called inside of an angular
      # digest, the callbacks can consistently use scope.$apply.
      # All event handlers that want to act on angular scopes and
      # participate in the digest cycle will have to themselves
      # call scope.$apply, etc.
      setTimeout =>
        if event of @eventSubscribers
          callback(data...) for callback in @eventSubscribers[event]
      , 0

    getGameWidth: ->
      if @fullscreen
        $(document).width()
      else
        @container.width()
    getGameHeight: ->
      if @fullscreen
        $(document).height()
      else
        @container.height()

    setupThree: ->
      @renderer = new THREE.WebGLRenderer(
        antialias: true
        maxLights: 50
      )
      @renderer.setClearColor(0x000000, 1)

      # No gravity
      # TODO let levels determine this
      @scene.setGravity(new THREE.Vector3(0.0, 0.0, 0.0))
      @setupLighting @scene
      @renderer.setSize @getGameWidth(), @getGameHeight()

      # TODO let levels determine when these passes are used
      #  that means that we'll need to make this work with adding
      #  and removing passes during runtime

      @composer = new THREE.EffectComposer(@renderer)
      @composer.setSize @getGameWidth(), @getGameHeight()

      @renderPass = new THREE.RenderPass(@scene, null)
      copyPass = new THREE.ShaderPass(THREE.CopyShader)
      @composer.addPass(@renderPass)

      filmEffect = new THREE.ShaderPass(THREE.FilmShader)
      filmEffect.enabled = true
      filmEffect.uniforms['grayscale'].value = 0
      filmEffect.uniforms['sIntensity'].value = 0.1
      @composer.addPass(filmEffect)

      rgbShiftEffect = new THREE.ShaderPass(THREE.RGBShiftShader)
      rgbShiftEffect.enabled = false
      @composer.addPass(rgbShiftEffect)

      vignetteEffect = new THREE.ShaderPass(THREE.VignetteShader)
      vignetteEffect.uniforms['darkness'].value = 1.3
      @composer.addPass(vignetteEffect)

      @subscribe 'hit', (target) =>
        if target == 'player'
          camera = @scene.getObjectById('camera')

          if camera
            camera.camera.shake = 6

          filmEffect.uniforms['sIntensity'].value = 0.8
          setTimeout =>
            filmEffect.uniforms['sIntensity'].value = 0.1
            if camera
              camera.camera.shake = false
          , 900

      @subscribe 'death', ->
        rgbShiftEffect.enabled = true
        setTimeout ->
          rgbShiftEffect.enabled = false
        , 2200

      @composer.addPass(copyPass)
      copyPass.renderToScreen = true

      # On container size change, redo renderer.setSize
      $(window).on('resize', _.throttle(=>
        if @fullscreen
          @container.parent().addClass('fullscreen')
        else
          @container.parent().removeClass('fullscreen')

        # Hide the canvas so that it doesn't add extra height from
        # its previous size.
        @container.find('canvas').hide()
        @renderer.setSize @getGameWidth(), @getGameHeight()
        @composer.setSize @getGameWidth(), @getGameHeight()
        @container.find('canvas').show()
      , 500))

      @container.append @renderer.domElement

    setupLighting: (scene) ->
      # TODO level determined lighting?
      light = new THREE.HemisphereLight(0xffffff, 0x111111, 0.5)
      
      ambient = new THREE.AmbientLight(0x404040)

      # add to the scene
      scene.add light
      scene.add ambient

    loadLevel: (levelName) ->
      @emit('level:unload')
      @scene.clear()
      @scene.load(levelName)
      @emit('level:load', levelName)

    system: (name, componentName, elapsedTime) ->
      console.time('system ' + name)
      entities = @scene.filterEntities(componentName)
      if entities.length > 0
        @systems[name].processOurEntities(entities, elapsedTime)
      console.timeEnd('system ' + name)

    registerEntity: (entity, id) ->
      for systemName of @systems
        entity = @systems[systemName].registerEntity(entity, id)

      entity

    unregisterEntity: (entity) ->
      system.unregisterEntity(entity, entity.id) for system in _.values(@systems)
      null

    fpsUpdate: (currentTime) ->
      elapsedTime = currentTime - @lastTime
      @lastTime = currentTime
      elapsedTime

    updatePlayerStats: ->
      # Update stats display
      player = @scene.getObjectById('player')
      health = player?.damagable?.health or 0
      max = player?.damagable?.maxHealth or Math.Infinity
      @playerStats.render(health, max)

    gameloop: (currentTime=0) =>
      console.time('gameloop')
      elapsedTime = @fpsUpdate(currentTime)

      if not @paused
        @playerStats.session.time += elapsedTime

        # filter our entities and give them to the appropriate systems
        @system('camera', 'camera', elapsedTime)

        @system('spawners', 'spawnable', elapsedTime)
        @system('generator', 'generatable', elapsedTime)

        @system('damage', 'damagable', elapsedTime)

        @system('controls', 'controllable', elapsedTime)
        @system('weapons', 'fireable', elapsedTime)
        @system('explosion', 'explosion', elapsedTime)
        @system('debris', 'debris', elapsedTime)
        @system('render', 'renderable', elapsedTime)
        @system('expire', 'expirable', elapsedTime)

        @system('targeter', 'targeter', elapsedTime)
        @system('targeted', 'targeted', elapsedTime)

        # Note that movements need to be applied after the spawner and generator
        # systems.
        @system('movement', 'movement', elapsedTime)
        @system('seeking', 'seeking', elapsedTime)
        @system('follow', 'follow', elapsedTime)

        @scene.simulate(elapsedTime / 1000.0)

        @updatePlayerStats()
        @assetManager.maintain()

      console.timeEnd('gameloop')
      window.requestAnimationFrame @gameloop
