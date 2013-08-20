define(['systems', 'THREE', 'THREEx.FullScreen', 'THREEx.RendererStats', 'Stats', 'Physijs', 'jquery', 'underscore', 'utils'], (systems, THREE, FullScreen, RendererStats, Stats, Physijs, $, _, utils) ->
  FRAME_TIME_COUNTS = 50
  ASTEROID_SPAWN_RATE = 0.1

  PLAYER =
    position: {x: 0, y: 0, direction: {x: 0, y: 0, z: 0}}
    renderable:
      model: 'playership'
      static: true
    damagable:
      health: 30
      maxHealth: 30
    controllable: {left: 'left', right: 'right'}
    fireable:
      speed: 30
      size: 21 
      extraComponents:
        damaging:
          health: 1
          destroysSelf: true
        renderable:
          model: 'laserbolt'
          mass: 0.001
        expireTime: 2000

  class App
    fullscreen: false
    paused: false

    # Where we keep track of our camera entities for easy rendering
    cameras: {}

    playerStats:
      deaths: 0
      kills: 0
      time: 0

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

    maxDistance: 3400
    maxEntities: 250

    backgroundDistance: 10

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
          farDistance: 10000
          position:
            x: 0
            y: 0
            z: 1500
          view:
            left: 0.75
            bottom: 0.75
            width: 0.15
            height: 0.15
            background: '#aaaaaa'
          order: 2
          
      asteroidSpawner:
        spawnable:
          radius: 200.0
          max: 30
          rate: ASTEROID_SPAWN_RATE
          rateChange: 0.005
          extraComponents:
            damagable:
              health: 3
            damaging:
              health: 1
            generatable:
              type: 'asteroid1'

    getNextEntityId: ->
      @lastEntityId += 1
      @lastEntityId

    removeEntity: (id) ->
      # Make sure to discard any unique geometries and textures, to prevent
      # accumulation of junk in memory.
      if @entities[id].renderable? and @entities[id].renderable.mesh? and not @entities[id].renderable.model?
        @entities[id].renderable.mesh.geometry.dispose()
        @entities[id].renderable.mesh.material.dispose()

      delete @entities[id]

    destroyEntity: (id) ->
      if @entities[id]
        @addExplosionAtEntity(@entities[id])
        @removeEntity(id)

      if id == 'player'
        @playerStats.deaths += 1
        # Remove all asteroids, reset rate
        @entities.asteroidSpawner.spawnable.rate = ASTEROID_SPAWN_RATE
        @removeEntity(id) for id of @entities when @entities[id]._type == 'asteroidSpawner'

        # TODO show some death message

        setTimeout(=>
          @playerStats.time = 0
          @entities.player = utils.clone(PLAYER)
        , 5000)
      else
        @playerStats.kills += 1

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
            time: 5000
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

    controlDirection: false
    controlFiring: false

    constructor: (@container, @playerStatsContainer) ->
      @systems = systems.register(this)
      @setupThree()
      @container.append @renderer.domElement

      document.addEventListener 'keydown', (event) =>
        if event.which == 65
          @controlDirection = 'left'
        else if event.which == 68
          @controlDirection = 'right'
        else if event.which == 32
          @controlFiring = true
        else if event.which == 79 # o
          $('#go-fullscreen').click()
        else if event.which == 80 # p
          @paused = not @paused
          $('#pause-continue').button('toggle')
      
      document.addEventListener 'keyup', (event) =>
        if event.which in [65, 68]
          @controlDirection = false
        else if event.which == 32
          @controlFiring = false

    registerCamera: (id, camera, order) ->
      @scene.add camera
      camera.name = id
      @cameras[id] = {camera: camera, order: order}

    setupThree: ->
      @renderer = new THREE.WebGLRenderer(
        antialias: true
      )
      @renderer.setClearColor(0x000000, 1)

      @stats = new Stats()
      @stats.setMode(0)
      @rendererStats = new RendererStats()
      $('#stats-container').append(@stats.domElement).append(@rendererStats.domElement)

      @scene = new Physijs.Scene()
      @scene.setGravity(new THREE.Vector3(0.0, 0.0, 0.0))
      @setupLighting @scene
      @renderer.setSize @getGameWidth(), @getGameHeight()

      # On container size change, redo renderer.setSize
      $(window).on('resize', _.throttle(=>
        @fullscreen = FullScreen.activated()

        if @fullscreen
          @container.addClass('fullscreen')
        else
          @container.removeClass('fullscreen')

        # Hide the canvas so that it doesn't add extra height from
        # its previous size.
        @container.find('canvas').hide()
        @renderer.setSize @getGameWidth(), @getGameHeight()
        @container.find('canvas').show()
      , 500))

    setupLighting: (scene) ->
      pointLight = new THREE.PointLight(0xffffff)

      # set its position
      pointLight.position.x = 0
      pointLight.position.y = 0
      pointLight.position.z = 300

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
      @renderer.setClearColor(cameraDef.view?.background or '#000000')
      @renderer.render(@scene, @cameras[cameraId].camera)

    render: (elapsedTime) ->
      @scene.simulate(elapsedTime / 1000.0)
      # iterate over cameras, rendering to each
      orderedCameras = _.chain(@cameras)
                        .keys().sortBy(
                          (x) -> @cameras[x].order
                        , this).value()
      @renderCamera(cameraId) for cameraId in orderedCameras
      @rendererStats.update(@renderer)

    updatePlayerStats: ->
      # Update stats display
      @playerStatsContainer.find('.deaths .value').text(@playerStats.deaths)
      @playerStatsContainer.find('.kills .value').text(@playerStats.kills)
      @playerStatsContainer.find('.time .value').text((@playerStats.time / 60.0) | 0)
      health = @entities.player?.damagable?.health or 0
      max = @entities.player?.damagable?.maxHealth or Math.Infinity
      @playerStatsContainer.find('.health .current .value').text(health)
      @playerStatsContainer.find('.health .max .value').text(max)
      @playerStatsContainer.find('.health .progress .bar').css({width: (100.0 * health / max) + '%'})


    gameloop: (currentTime=0) =>
      @stats.begin()
      elapsedTime = @fpsUpdate(currentTime)

      if not @paused
        @playerStats.time += elapsedTime

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

        # filter our entities and give them to the appropriate systems
        @system('camera', 'camera', elapsedTime)

        @system('spawners', 'spawnable', elapsedTime)
        @system('generator', 'generatable', elapsedTime)

        @system('damage', 'damagable', elapsedTime)

        @system('controls', 'controllable', elapsedTime)
        @system('weapons', 'fireable', elapsedTime)
        @system('explosion', 'explosion', elapsedTime)
        @system('render', 'renderable', elapsedTime)
        @system('expire', 'expirable', elapsedTime)

        # Note that movements need to be applied after the spawner and generator
        # systems.
        @system('movement', 'movement', elapsedTime)


        @updatePlayerStats()

      @stats.end()

      window.requestAnimationFrame @gameloop
)
