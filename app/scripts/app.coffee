define ['systems', 'assetmanager', 'background', 'THREE', 'vendor/fullscreen', 'Physijs', 'jquery', 'underscore', 'utils'], (systems, AssetManager, createBackground, THREE, FullScreen, Physijs, $, _, utils) ->
  FRAME_TIME_COUNTS = 50
  ASTEROID_SPAWN_RATE = 0.1

  WEAPONS =
    plasma:
      speed: 30
      size: 21 
      extraComponents:
        damagable:
          health: 0
        damaging:
          health: 10
          disappears: true
        renderable:
          model: 'laserbolt'
          mass: 0.001
        expirable:
          time: 2000
          destroy: true
    missile:
      speed: 5
      size: 21 
      extraComponents:
        damagable:
          health: 0
        damaging:
          health: 20
          disappears: true
        renderable:
          model: 'missile'
          mass: 0.1
        expirable:
          time: 3000
          destroy: true
        targeting:
          type: 'asteroidSpawner'
          force: 20
    mine:
      speed: 10
      size: 21
      extraComponents:
        damagable:
          health: 0
        damaging:
          health: 30
          disappears: true
        renderable:
          model: 'mine'
          mass: 0.2
        expirable:
          time: 1000
          destroy: false
          stop: true

  PLAYER =
    position: {x: 0, y: 0, direction: {x: 0, y: 0, z: 0}}
    renderable:
      model: 'playership'
      static: true
      convexCollision: true
    damagable:
      health: 30
      maxHealth: 30
    controllable: {left: 'left', right: 'right'}
    fireable: utils.clone(WEAPONS.plasma)

  class App
    fullscreen: false
    paused: true
    currentWeapon: 'plasma'

    # Where we keep track of our camera entities for easy rendering
    cameras: {}

    playerStats:
      deaths: 0
      kills: 0
      time: 0

    maxDistance: 3400
    maxEntities: 250

    lastTime: 0

    lastEntityId: 0
    entities:
      player: utils.clone(PLAYER)
      camera:
        camera:
          type: 'perspective'
          viewAngle: 45.0
          aspect: 1.0
          nearDistance: 0.1
          farDistance: 10000
          position:
            x: 0
            y: 0
            z: 500
          view:
            left: 0
            bottom: 0
            width: 1
            height: 1
          order: 1
      altcamera:
        camera:
          type: 'perspective'
          viewAngle: 45.0
          aspect: 1.0
          nearDistance: 0.1
          farDistance: 1600
          radar: true
          position:
            x: 0
            y: 0
            z: 1500
          view:
            left: 0.75
            bottom: 0.75
            width: 0.15
            height: 0.15
            background: '#004400'
            backgroundAlpha: 0.5
          order: 2
          
      asteroidSpawner:
        spawnable:
          radius: 1000.0
          max: 30
          rate: ASTEROID_SPAWN_RATE
          rateChange: 0.005
          extraComponents:
            damagable:
              health: 20
              fracture:
                chance: 0.3
                generatable:
                  type: 'asteroid1'
                  texture: 'images/asteroid1.png'
                  bumpMap: 'images/asteroid1_bump.png'
                  bumpScale: 1.0
            damaging:
              health: 5
            generatable:
              type: 'asteroid1'
              texture: 'images/asteroid1.png'
              bumpMap: 'images/asteroid1_bump.png'
              bumpScale: 1.0

    eventSubscribers: {}

    constructor: (@container, @playerStatsContainer) ->
      @assetManager = new AssetManager()
      @systems = systems.register(this)

    setup: ->
      @setupThree()
      @container.append @renderer.domElement

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
          @entities.player.fireable = utils.clone(WEAPONS[weapon])

      @subscribe 'death', =>
        @playerStats.deaths += 1
        # TODO show some death message
        # Reset rate asteroid spawn rate
        @entities.asteroidSpawner.spawnable.rate = ASTEROID_SPAWN_RATE
        setTimeout(=>
          @playerStats.time = 0
          @entities.player = utils.clone(PLAYER)
          @emit('controls:selectWeapon', @currentWeapon)
        , 5000)

      @subscribe 'kill', =>
        @playerStats.kills += 1

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

    getNextEntityId: ->
      @lastEntityId += 1
      @lastEntityId

    removeEntity: (id) ->
      # Make sure to discard any unique geometries and textures, to prevent
      # accumulation of junk in memory.
      if @entities[id].renderable? and not @entities[id].renderable.particles?
        mesh = @entities[id].renderable.mesh
        if mesh? and not @entities[id].renderable.model?
          mesh.geometry.dispose()
          mesh.material.dispose()

      delete @entities[id]

    destroyEntity: (id) ->
      if id of @entities
        @addExplosionAtEntity(@entities[id])
        @removeEntity(id)

      if id == 'player'
        @emit('death')
      else
        @emit('kill')

    addExplosionAtEntity: (entity) ->
      position = false
      if entity.renderable?.mesh?
        position = entity.renderable.mesh.position
      else if entity.position?
        position = entity.position
      
      if position?
        @addEntity(
          renderable: {}
          position:
            x: position.x
            y: position.y
            z: position.z
            direction: {x: 0, y: 0, z:0}
          explosion:
            startRadius: 5.0
            speed: 2.2
          expirable:
            destroy: true
            time: 2000
        )
      else
        console.log 'Tried to explode something that did not have a position:', entity

    addEntity: (components) ->
      if _.keys(@entities).length < @maxEntities
        entity = components
        for systemName of @systems
          entity = @systems[systemName].registerEntity(entity)

        @entities[@getNextEntityId()] = entity
      else
        console.log 'way too many entities'

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

    registerCamera: (id, camera, order) ->
      @scene.add camera
      camera.name = id
      @cameras[id] = {camera: camera, order: order}

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

    setupLighting: (scene) ->
      pointLight = new THREE.PointLight(0xffffff, 1.0, @maxDistance * 50.0)

      # set its position
      pointLight.position.set(0, 0, 5000)

      # add to the scene
      scene.add pointLight

    filterEntities: (component) ->
      [entityId, components] for entityId, components of @entities when component of components

    system: (name, componentName, elapsedTime) ->
      entities = @filterEntities(componentName)
      if entities.length > 0
        @systems[name].processOurEntities(entities, elapsedTime)

    fpsUpdate: (currentTime) ->
      elapsedTime = currentTime - @lastTime
      @lastTime = currentTime
      elapsedTime

    renderCamera: (cameraId) ->
      # Load viewport info from camera entity
      cameraDef = @entities[cameraId].camera
      windowWidth = @getGameWidth()
      windowHeight = @getGameHeight()
      # From http://mrdoob.github.io/three.js/examples/webgl_multiple_views.html
      if cameraDef.view?
        left = Math.floor(windowWidth * cameraDef.view.left)
        bottom = Math.floor(windowHeight * cameraDef.view.bottom)
        width = Math.floor(windowWidth * cameraDef.view.width)
        height = Math.floor(windowHeight * cameraDef.view.height)
      else
        left = 0
        bottom = 0
        width = windowWidth
        height = windowHeight

      @renderer.setViewport(left, bottom, width, height)
      @renderer.setScissor(left, bottom, width, height)
      @renderer.enableScissorTest(true)
      @renderer.setClearColor(
        cameraDef.view?.background or '#000000', 
        cameraDef.view?.backgroundAlpha or 1
      )

      if cameraDef.material?
        @scene.overrideMaterial = cameraDef.material
      else
        @scene.overrideMaterial = undefined

      @renderer.render(@scene, @cameras[cameraId].camera)

    render: (elapsedTime) ->
      @scene.simulate(elapsedTime / 1000.0)
      # iterate over cameras, rendering to each
      orderedCameras = _.chain(@cameras)
                        .keys().sortBy(
                          (x) -> @cameras[x].order
                        , this).value()
      @renderCamera(cameraId) for cameraId in orderedCameras

    updatePlayerStats: ->
      # Update stats display
      @playerStatsContainer.find('.deaths .value').text(@playerStats.deaths)
      @playerStatsContainer.find('.kills .value').text(@playerStats.kills)
      @playerStatsContainer.find('.time .value').text((@playerStats.time / 1000.0) | 0)
      health = @entities.player?.damagable?.health or 0
      max = @entities.player?.damagable?.maxHealth or Math.Infinity
      @playerStatsContainer.find('.health .current .value').text(health)
      @playerStatsContainer.find('.health .max .value').text(max)
      @playerStatsContainer.find('.health .progress .bar').css({width: (100.0 * health / max) + '%'})

    clearDistantEntities: ->
      # Any entities more than some fixed distance off the screen should be
      # destroyed.
      stale = []
      @scene.traverse (obj) =>
        if obj.position.length() > @maxDistance and obj.name of @entities
          @removeEntity(obj.name)

        # Remove any objects in the scene but not registered as an
        # entity, if the object has a name.
        if obj.name and obj.name not of @entities
          stale.push obj

      @scene.remove(obj) for obj in stale


    gameloop: (currentTime=0) =>
      elapsedTime = @fpsUpdate(currentTime)

      if not @paused
        @playerStats.time += elapsedTime

        @clearDistantEntities()

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

        @updatePlayerStats()
        @assetManager.maintain()

      window.requestAnimationFrame @gameloop
