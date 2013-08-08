define(['systems/render', 'systems/controls', 'systems/weapons', 'systems/movement', 'systems/expire', 'THREE', 'jquery'], (render, controls, weapons, movement, expire, THREE, $) ->
  class App
    gameWidth: 800
    gameHeight: 500
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
        renderable: {model: 'playership'}
        controllable: {left: 'left', right: 'right'}
        fireable:
          speed: 0.1
          renderable:
            model: 'laserbolt'
          expireTime: 2000

    getNextEntityId: ->
      @lastEntityId += 1
      @lastEntityId

    removeEntity: (id) ->
      delete @entities[id]

    addEntity: (components) ->
      @entities[@getNextEntityId()] = components

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

      @scene = new THREE.Scene()
      @setupLighting @scene
      @scene.add(@camera)
      @renderer.setSize @gameWidth, @gameHeight

    setupLighting: (scene) ->
      pointLight = new THREE.PointLight(0xffffff)

      # set its position
      pointLight.position.x = 10
      pointLight.position.y = 50
      pointLight.position.z = 130

      # add to the scene
      scene.add pointLight

    filterEntities: (component) ->
      [entityId, components] for entityId, components of @entities when component of components

    gameloop: (time=0) =>
      elapsed = time - @lastTime
      @lastTime = time

      # filter our entities and give them to the appropriate systems
      controls this, @filterEntities('controllable'), elapsed
      weapons this, @filterEntities('fireable'), elapsed
      movement this, @filterEntities('moveable'), elapsed
      render this, @filterEntities('renderable'), elapsed
      expire this, @filterEntities('expirable'), elapsed

      window.requestAnimationFrame @gameloop
)
