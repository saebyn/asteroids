define ['THREE', 'Physijs', 'utils', 'levels'], (THREE, Physijs, utils, levels) ->
  baseEntity =
    updateMatrixWorld: ->


  class Scene extends Physijs.Scene
    constructor: (@app, params) ->
      super params

    clear: ->
      @remove(obj) for obj in @children

    # Load entities from level data object
    load: (levelName) ->
      @addEntity(utils.clone(value), key) for key, value of levels[levelName]
      null

    add: (obj) ->
      if obj instanceof THREE.Object3D
        super obj
      else
        obj.parent = this
        @children.push(obj)
        obj.dispatchEvent?({type: 'added'})

    remove: (obj) ->
      if obj instanceof THREE.Object3D
        super obj
      else
        index = @children.indexOf obj
        if index != -1
          obj.parent = undefined
          obj.dispatchEvent?({type: 'removed'})
          @children.splice(index, 1)

    replaceEntity: (existing, replacement) ->
      replacement.id = existing.id
      replacement._components = existing._components or []
      for k in replacement._components
        replacement[k] = existing[k]

      @remove(existing)
      @add(replacement)

    addEntity: (components, id=undefined) ->
      if 'renderable' of components
        entity = new THREE.Object3D()
        entity.position.set(components.position) if 'position' of components
        entity.rotation.set(components.rotation) if 'rotation' of components
        delete components.position
        delete components.rotation
      else
        entity = utils.clone(baseEntity)

      if id
        # Give this entity the id provided
        entity.id = id
      else
        # Use the generated id, or generate one if not available.
        id = entity.id or THREE.Object3DIdCount++

      entity._components = []

      for k, v of components
        entity[k] = v
        entity._components.push(k)

      entity = @app.registerEntity(entity, id)
      @add(entity)

    getEntityIndexById: (id) ->
      for i in [0...@children.length]
        if @children[i].id == id
          return i

      return -1

    addComponent: (name, component, id) ->
      index = @getEntityIndexById(id)
      if index != -1
        entity = @children[index]
        if name not of entity
          entity[name] = component
          entity._components.push(name)
          @children[index] = @app.registerEntity(components, id)

    filterEntities: (component) ->
      [@children[i].id, @children[i]] for i in [0...@children.length] when component of @children[i]

    removeEntity: (idOrEntity) ->
      if idOrEntity.id
        entity = idOrEntity
      else
        entity = @getObjectById(idOrEntity, false)

      @app.unregisterEntity(entity)
      @remove(entity)

    destroyEntity: (idOrEntity) ->
      if idOrEntity.id
        entity = idOrEntity
      else
        entity = @getObjectById(idOrEntity, false)

      if entity
        @addExplosionAtEntity(entity)
        @remove(entity)

        if id == 'player'
          @app.emit('death')
        else
          @app.emit('kill')

    addExplosionAtEntity: (entity) ->
      if entity.position?
        @addEntity(
          renderable: {}
          position: entity.position
          rotation: {x: 0, y: 0, z:0}
          explosion:
            startRadius: 5.0
            speed: 2.2
          expirable:
            destroy: true
            time: 2000
        )
