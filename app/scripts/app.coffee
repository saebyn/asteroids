define(['systems', 'THREE', 'Physijs', 'jquery'], (systems, THREE, Physijs, $) ->
  class App
    gameWidth: 800
    gameHeight: 500

    maxDistance: 340
    maxEntities: 50 

    viewAngle: 45.0
    aspect: ->
      @gameWidth / @gameHeight
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
        controllable: {left: 'left', right: 'right'}
        fireable:
          speed: 30
          size: 5
          renderable:
            model: 'laserbolt'
          expireTime: 2000
      asteroid:
        spawnable:
          radius: 200.0
          max: 15
          rate: 0.1
          rateChange: 0.005
          extraComponents:
            generatable:
              type: 'asteroid1'

    getNextEntityId: ->
      @lastEntityId += 1
      @lastEntityId

    removeEntity: (id) ->
      delete @entities[id]

    addEntity: (components) ->
      if _.keys(@entities).length < @maxEntities
        @entities[@getNextEntityId()] = components
      else
        console.log 'way too many entities'

    controlDirection: false
    controlFiring: false

    setup: (container) ->
      @setupThree()
      container.append @renderer.domElement

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

      @camera = new THREE.PerspectiveCamera(@viewAngle, @aspect(), @nearDistance, @farDistance)
      @camera.position.z = 300

      @scene = new Physijs.Scene()
      @scene.setGravity(new THREE.Vector3(0.0, 0.0, 0.0))
      @setupLighting @scene
      @scene.add(@camera)
      @renderer.setSize @gameWidth, @gameHeight

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

    system: (name, componentName, elapsed) ->
      entities = @filterEntities(componentName)
      if entities.length > 0
        systems[name](this, entities, elapsed)

    gameloop: (time=0) =>
      elapsed = time - @lastTime
      @lastTime = time

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
      @system('spawners', 'spawnable', elapsed)
      @system('generator', 'generatable', elapsed)

      @system('controls', 'controllable', elapsed)
      @system('weapons', 'fireable', elapsed)
      @system('render', 'renderable', elapsed)
      @system('expire', 'expirable', elapsed)

      # Note that movements need to be applied after the spawner and generator
      # systems.
      @system('movement', 'movement', elapsed)

      window.requestAnimationFrame @gameloop
)
