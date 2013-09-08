define ['systems', 'playerstats', 'assetmanager', 'entitymanager', 'definitions', 'background', 'THREE', 'vendor/fullscreen', 'Physijs', 'jquery', 'underscore', 'utils'], (systems, PlayerStats, AssetManager, EntityManager, gameDefinitions, createBackground, THREE, FullScreen, Physijs, $, _, utils) ->
  class App
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
        else if action == 'fullscreen'
          $('#go-fullscreen').click()
        else if action == 'pause'
          if @container.is(':visible')
            @togglePause()

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
      $('#pause-continue').button('toggle')
      if @paused
        @emit('pause')

    subscribe: (event, callback) ->
      if event not of @eventSubscribers
        @eventSubscribers[event] = []

      @eventSubscribers[event].push(callback)

    emit: (event, data...) ->
      if event of @eventSubscribers
        callback(data...) for callback in @eventSubscribers[event]

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
      )
      @renderer.setClearColor(0x000000, 1)

      @scene = new Physijs.Scene()
      @scene.setGravity(new THREE.Vector3(0.0, 0.0, 0.0))
      @setupLighting @scene
      @renderer.setSize @getGameWidth(), @getGameHeight()

      createBackground(@assetManager, @scene)

      # On container size change, redo renderer.setSize
      $(window).on('resize', _.throttle(=>
        @fullscreen = FullScreen.activated()

        if @fullscreen
          @container.parent().addClass('fullscreen')
        else
          @container.parent().removeClass('fullscreen')

        # Hide the canvas so that it doesn't add extra height from
        # its previous size.
        @container.find('canvas').hide()
        @renderer.setSize @getGameWidth(), @getGameHeight()
        @container.find('canvas').show()
      , 500))

      @container.append @renderer.domElement

    setupLighting: (scene) ->
      pointLight = new THREE.PointLight(0xffffff, 1.0, gameDefinitions.MAX_DISTANCE * 50.0)

      # set its position
      pointLight.position.set(0, 0, 5000)

      # add to the scene
      scene.add pointLight

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

        @scene.simulate(elapsedTime / 1000.0)

        @updatePlayerStats()
        @assetManager.maintain()

      window.requestAnimationFrame @gameloop
