# render system
define ['systems/base', 'THREE', 'Physijs'], (System, THREE, Physijs) ->
  class RenderSystem extends System
    models: {}
    maxCachedModels: 10

    constructor: (@app) ->
      # Inst the model loader
      @loader = new THREE.JSONLoader()

    addModelToScene: (id, entity) ->
      if not entity.renderable.mesh?
        modelName = entity.renderable.model
  
        # Skip if model isn't loaded
        if modelName not of @models or @models[modelName] == true
          return
  
        model = @models[modelName]
        model.useCount += 1
  
        mass = undefined
        if entity.renderable.mass?
          mass = entity.renderable.mass
 
        model.geom.dynamic = false
  
        obj = new Physijs.BoxMesh(model.geom, model.material, mass)
        if entity.renderable.collideless?
          obj._physijs.type = 'sphere'
          obj._physijs.radius = 0
  
        entity.renderable.mesh = obj
      else
        obj = entity.renderable.mesh
  
      obj.name = id
      entity.renderable.meshLoaded = true
      @app.scene.add obj
      
      # Lock all objects on the game plane
      if obj.setLinearFactor?
        obj.setLinearFactor(new THREE.Vector3(1, 1, 0))
  
      @updatePosition(id, entity)

    trimModelsCache: ->
      if _.keys(@models).length > @maxCachedModels
        console.log 'extra models, trimming'
        _.chain(@models)
         .map((model, name) -> [name, model.useCount])
         .sortBy((e) -> e.useCount)
         .initial(@maxCachedModels)
         .each((e) =>
           model = @models[e.name])
  
    loadModel: (id, entity) ->
      model = entity.renderable.model
  
      @models[model] = true
      @loader.load '/resources/' + model + '.js', (geom, materials) =>
        @models[model] =
          geom: geom
          material: new Physijs.createMaterial(materials[0], 0.8, 0.4)
          useCount: 0
  
    updatePosition: (id, entity) ->
      mesh = entity.renderable.mesh
      if entity?.position
        mesh.position.x = entity.position.x
        mesh.position.y = entity.position.y
        if entity.position.z?
          mesh.position.z = entity.position.z
        mesh.__dirtyPosition = true
        if entity.position.direction?
          mesh.rotation.x = entity.position.direction.x
          mesh.rotation.y = entity.position.direction.y
          mesh.rotation.z = entity.position.direction.z
          mesh.__dirtyRotation = true
  
      if entity.renderable.static?
        mesh.setLinearFactor(new THREE.Vector3(0, 0, 0))
        @app.scene.add new Physijs.HingeConstraint(
          mesh,
          new THREE.Vector3(0, 0, 0),
          new THREE.Vector3(0, 0, 1)
        )
  
  
    processOurEntities: (entities, elapsedTime) ->
      # if the entity has a model specified, but it's not loaded...
      @loadModel(id, components) for [id, components] in entities when components.renderable.model? and components.renderable.model not of @models
  
      # if the entity has a loaded model, but it's not in the scene...
      @addModelToScene(id, components) for [id, components] in entities when not components.renderable.meshLoaded

      # throw away old models, we can refetch them later if we need to
      @trimModelsCache()

      # tell the app to render
      @app.render(elapsedTime)
