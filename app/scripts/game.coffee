define ['systems', 'playerstats', 'assetmanager', 'entitymanager', 'definitions', 'background', 'THREE', 'Physijs', 'jquery', 'underscore', 'utils', 'THREE.EffectComposer', 'THREE.RenderPass', 'THREE.ShaderPass', 'THREE.VignetteShader', 'THREE.RGBShiftShader', 'THREE.FilmShader'], (systems, PlayerStats, AssetManager, EntityManager, gameDefinitions, createBackground, THREE, Physijs, $, _, utils) ->
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
      @entities = new EntityManager(this)

    setup: ->
      @setupThree()

      @subscribe 'controls:start', (action, detail) =>
        if action == 'steer'
          if @entities.player?.controllable?
            @entities.player.controllable.controlDirection = detail
        else if action == 'fire'
          if @entities.player?.controllable?
            @entities.player.controllable.controlFiring = true
        else if action == 'pause'
          if @container.is(':visible')
            @togglePause()
        else if action == 'fullscreen'
          $('[data-fullscreen]').click()

      @subscribe 'controls:rotate', (x, y) =>
        xStep = Math.PI / 48
        yStep = Math.PI / 24
        if @entities.camera?.follow?.quaternion?
          rot = new THREE.Quaternion()
          rot.setFromEuler(new THREE.Euler(xStep * x, yStep * y, 0))
          @entities.camera.follow.quaternion.multiply(rot)

      @subscribe 'controls:stop', (action) =>
        if action == 'steer'
          if @entities.player?.controllable?
            @entities.player.controllable.controlDirection = false
        else if action == 'fire'
          if @entities.player?.controllable?
            @entities.player.controllable.controlFiring = false

      @subscribe 'controls:selectWeapon', (weapon) =>
        @currentWeapon = weapon
        if @entities.player?
          @entities.player.fireable = utils.clone(gameDefinitions.WEAPONS[weapon])

      @subscribe 'death', =>
        # TODO show some death message
        # Reset asteroid spawn rate
        @entities.asteroidSpawner.spawnable.rate = gameDefinitions.ASTEROID_SPAWN_RATE
        setTimeout(=>
          @emit('start')
          @entities.addEntity(utils.clone(gameDefinitions.PLAYER), 'player')
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

      @scene = new Physijs.Scene()
      @scene.setGravity(new THREE.Vector3(0.0, 0.0, 0.0))
      @setupLighting @scene
      @renderer.setSize @getGameWidth(), @getGameHeight()

      @composer = new THREE.EffectComposer(@renderer)
      @composer.setSize @getGameWidth(), @getGameHeight()

      @renderPass = new THREE.RenderPass(@scene, null)
      copyPass = new THREE.ShaderPass(THREE.CopyShader)
      @composer.addPass(@renderPass)

      filmEffect = new THREE.ShaderPass(THREE.FilmShader)
      filmEffect.enabled = true
      filmEffect.uniforms['grayscale'].value = 0
      filmEffect.uniforms['sIntensity'].value = 0.6
      @composer.addPass(filmEffect)

      rgbShiftEffect = new THREE.ShaderPass(THREE.RGBShiftShader)
      rgbShiftEffect.enabled = false
      @composer.addPass(rgbShiftEffect)

      vignetteEffect = new THREE.ShaderPass(THREE.VignetteShader)
      vignetteEffect.uniforms['darkness'].value = 1.3
      @composer.addPass(vignetteEffect)

      @subscribe 'death', ->
        filmEffect.uniforms['sIntensity'].value = 0.8
        rgbShiftEffect.enabled = true
        setTimeout ->
          filmEffect.uniforms['sIntensity'].value = 0.6
          rgbShiftEffect.enabled = false
        , 2200


      @composer.addPass(copyPass)
      copyPass.renderToScreen = true

      createBackground(@assetManager, @scene)

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
      light = new THREE.HemisphereLight(0xffffff, 0x111111, 0.5)

      # add to the scene
      scene.add light

    loadLevel: (levelName) ->
      @emit('level:unload')
      @entities.clear()
      @entities.clearDistantEntities(@scene)
      @entities.load(levelName)
      @emit('level:load', levelName)

    system: (name, componentName, elapsedTime) ->
      entities = @entities.filterEntities(componentName)
      if entities.length > 0
        @systems[name].processOurEntities(entities, elapsedTime)

    fpsUpdate: (currentTime) ->
      elapsedTime = currentTime - @lastTime
      @lastTime = currentTime
      elapsedTime

    updatePlayerStats: ->
      # Update stats display
      health = @entities.player?.damagable?.health or 0
      max = @entities.player?.damagable?.maxHealth or Math.Infinity
      @playerStats.render(health, max)

    gameloop: (currentTime=0) =>
      elapsedTime = @fpsUpdate(currentTime)

      if not @paused
        @playerStats.session.time += elapsedTime

        @entities.clearDistantEntities(@scene)

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

        # Note that movements need to be applied after the spawner and generator
        # systems.
        @system('movement', 'movement', elapsedTime)
        @system('targeting', 'targeting', elapsedTime)
        @system('follow', 'follow', elapsedTime)

        @scene.simulate(elapsedTime / 1000.0)

        @updatePlayerStats()
        @assetManager.maintain()

      window.requestAnimationFrame @gameloop
