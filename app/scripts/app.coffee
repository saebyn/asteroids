define(['systems', 'THREE', 'THREEx', 'Physijs', 'jquery', 'underscore'], (systems, THREE, THREEx, Physijs, $, _) ->
  FRAME_TIME_COUNTS = 50

  class App
    fullscreen: false
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
    getAspect: ->
      @getGameWidth() / @getGameHeight()

    maxDistance: 340
    maxEntities: 250

    frameTimes: []

    viewAngle: 45.0
    nearDistance: 0.1
    backgroundDistance: 10
    farDistance: 10000

    lastTime: 0

    lastEntityId: 0
    entities:
      player:
        position: {x: 0, y: 0, direction: {x: 0, y: 0, z: 0}}
        renderable:
          model: 'playership'
          static: true
        damagable:
          health: 30
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
            expireTime: 2000
      asteroidSpawner:
        spawnable:
          radius: 200.0
          max: 30
          rate: 0.1
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
      delete @entities[id]

    destroyEntity: (id) ->
      console.log 'thing went boom', id
      @removeEntity(id)

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

    constructor: (@container) ->
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
      
      document.addEventListener 'keyup', (event) =>
        if event.which in [65, 68]
          @controlDirection = false
        else if event.which == 32
          @controlFiring = false

    setupThree: ->
      @renderer = new THREE.WebGLRenderer(
        antialias: true
      )
      @renderer.setClearColor(0x000000, 1)

      @camera = new THREE.PerspectiveCamera(@viewAngle, @getAspect(), @nearDistance, @farDistance)
      @camera.position.z = 300

      @scene = new Physijs.Scene()
      @scene.setGravity(new THREE.Vector3(0.0, 0.0, 0.0))
      @setupLighting @scene
      @scene.add(@camera)
      @renderer.setSize @getGameWidth(), @getGameHeight()

      # On container size change, redo renderer.setSize
      $(window).on('resize', _.throttle(=>
        @fullscreen = THREEx.FullScreen.activated()

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
      @frameTimes.push(elapsedTime)
      if @frameTimes.length > FRAME_TIME_COUNTS
        @frameTimes.splice(0, @frameTimes.length - FRAME_TIME_COUNTS)

      @lastTime = currentTime
      elapsedTime

    gameloop: (currentTime=0) =>
      elapsedTime = @fpsUpdate(currentTime)

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
      @system('spawners', 'spawnable', elapsedTime)
      @system('generator', 'generatable', elapsedTime)

      @system('damage', 'damagable', elapsedTime)

      @system('controls', 'controllable', elapsedTime)
      @system('weapons', 'fireable', elapsedTime)
      @system('render', 'renderable', elapsedTime)
      @system('expire', 'expirable', elapsedTime)

      # Note that movements need to be applied after the spawner and generator
      # systems.
      @system('movement', 'movement', elapsedTime)

      window.requestAnimationFrame @gameloop
)
