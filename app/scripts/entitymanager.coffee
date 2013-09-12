define ['utils', 'definitions', 'levels'], (utils, gameDefinitions, levels) ->
  MAX_ENTITIES = 250

  class EntityManager
    lastEntityId: 0

    constructor: (@app) ->
      @_entities = []

    # Remove all entities.
    clear: ->
      # Iterate over a copy of _entities, since we manipulate it inside
      # of removeEntity.
      @removeEntity(key) for key in @_entities.slice(0)

    # Load entities from level data object
    load: (levelName) ->
      @_entities.push(key) for key of levels[levelName]
      this[key] = utils.clone(value) for key, value of levels[levelName]

    # Methods
    getNextEntityId: ->
      @lastEntityId += 1
      @lastEntityId

    removeEntity: (id) ->
      # Entity ids will always be strings.
      id = '' + id

      # Make sure to discard any unique geometries and textures, to prevent
      # accumulation of junk in memory.
      if this[id]?.renderable? and not this[id].renderable.particles?
        mesh = this[id].renderable.mesh
        if mesh?
          (child.parent = undefined) for child in mesh.children

          if not this[id].renderable.model?
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
