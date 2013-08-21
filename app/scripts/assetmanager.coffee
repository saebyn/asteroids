define ['THREE', 'Physijs'], (THREE, Physijs) ->
  class AssetManager
    maxCachedModels: 10
    models: {}
    textures: {}

    constructor: ->
      # Inst the model loader
      @loader = new THREE.JSONLoader()

    loadModel: (modelName) ->
      if modelName not of @models
        @models[modelName] = true
        @loader.load '/resources/' + modelName + '.js', (geom, materials) =>
          @models[modelName] =
            geom: geom
            material: new Physijs.createMaterial(materials[0], 0.8, 0.4)
            useCount: 0

    # Has the model finished loading?
    isModelLoaded: (modelName) ->
      modelName of @models and @models[modelName] != true

    # Has the model load process started (includes finished)?
    isModelLoadStarted: (modelName) ->
      modelName of @models

    getModel: (modelName) ->
      model = @models[modelName]
      model.useCount += 1
      model

    releaseModel: (modelName) ->
      @models[modelName].useCount -= 1

    getTexture: (path) ->
      if path not of @textures
        @textures[path] = new THREE.ImageUtils.loadTexture(path)

      @textures[path]

    trimModelsCache: ->
      if _.keys(@models).length > @maxCachedModels
        console.log 'extra models, trimming'
        _.chain(@models)
         .map((model, name) -> [name, model.useCount])
         .sortBy((e) -> e.useCount)
         .initial(@maxCachedModels)
         .each((e) =>
           model = @models[e.name])
 
    maintain: ->
      # throw away old models, we can refetch them later if we need to
      @trimModelsCache()
