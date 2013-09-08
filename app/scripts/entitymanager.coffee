define ['utils', 'definitions'], (utils, gameDefinitions) ->
  MAX_ENTITIES = 250

  class EntityManager
    lastEntityId: 0

    constructor: (@app) ->
      @_entities = [
        'player',
        'camera',
        'altcamera',
        'asteroidSpawner',
      ]

    # Entities
    player: utils.clone(gameDefinitions.PLAYER)
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
        rate: gameDefinitions.ASTEROID_SPAWN_RATE
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

    # Methods
    getNextEntityId: ->
      @lastEntityId += 1
      @lastEntityId

    removeEntity: (id) ->
      # Entity ids will always be strings.
      id = '' + id

      # Make sure to discard any unique geometries and textures, to prevent
      # accumulation of junk in memory.
      if this[id].renderable? and not this[id].renderable.particles?
        mesh = this[id].renderable.mesh
        if mesh? and not this[id].renderable.model?
          mesh.geometry.dispose()
          mesh.material.dispose()

      delete this[id]
      @_entities.splice(@_entities.indexOf(id), 1)

    clearDistantEntities: (scene) ->
      # Any entities more than some fixed distance off the screen should be
      # destroyed.
      stale = []
      scene.traverse (obj) =>
        if obj.position.length() > gameDefinitions.MAX_DISTANCE and obj.name in @_entities
          @removeEntity(obj.name)

        # Remove any objects in the scene but not registered as an
        # entity, if the object has a name.
        if obj.name and obj.name not in @_entities
          stale.push obj

      scene.remove(obj) for obj in stale

    destroyEntity: (id) ->
      if id of this
        @addExplosionAtEntity(this[id])
        @removeEntity(id)

      if id == 'player'
        @app.emit('death')
      else
        @app.emit('kill')

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

    addEntity: (components, id=undefined) ->
      if @_entities.length < MAX_ENTITIES
        entity = components

        # TODO too much knowledge of app internals
        for systemName of @app.systems
          entity = @app.systems[systemName].registerEntity(entity)

        if not id?
          # Entity ids will always be strings.
          id = '' + @getNextEntityId()

        @_entities.push(id)
        this[id] = entity
      else
        console.log 'Way too many entities. Dropping new ones on the floor.'

    filterEntities: (component) ->
      [id, this[id]] for id in @_entities when component of this[id]
