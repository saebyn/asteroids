define(['systems/render', 'THREE'], (render, THREE) ->

  class App
    gameWidth: 400
    gameHeight: 300
    viewAngle: 45.0
    aspect: ->
      @gameWidth / @gameHeight
    nearDistance: 0.1
    farDistance: 10000

    lastTime: 0

    entities:
      player:
        position: {x: 0, y: 0, direction: [0, 0, 0]}
        renderable: {model: 'playership'}

    setup: (container) ->
      console.log 'setup'

      # set up the drawing area
      @renderer = new THREE.WebGLRenderer()
      @camera = new THREE.PerspectiveCamera(@viewAngle, @aspect(), @nearDistance, @farDistance)
      @scene = new THREE.Scene()
      @scene.add(@camera)

      pointLight = new THREE.PointLight(0xFFFFFF)

      # set its position
      pointLight.position.x = 10
      pointLight.position.y = 50
      pointLight.position.z = 130

      # add to the scene
      @scene.add pointLight

      @camera.position.z = 300
      @renderer.setSize @gameWidth, @gameHeight
      container.append @renderer.domElement

    filterEntities: (component) ->
      [entityId, components] for entityId, components of @entities when component of components

    gameloop: (time=0) =>
      ellapsed = time - @lastTime
      @lastTime = time

      # filter our entities and give them to the appropriate systems
      render this, @filterEntities('renderable')

      window.requestAnimationFrame @gameloop
)
