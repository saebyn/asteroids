define ['THREE', 'Physijs'], (THREE, Physijs) ->
  class AssetManager
    maxCachedModels: 10
    models: {}
    textures: {}

    constructor: ->
      # Inst the model loader
      @loader = new THREE.JSONLoader()

    preload: (models, textures, images, success) ->
      # load models and textures
      # when all are complete, call success with no args
      # always call success, even if no assets or they are
      # already loaded
      totalAssets = models.length + textures.length
      loadedAssets = 0
      callback = ->
        loadedAssets += 1
        if loadedAssets == totalAssets
          success()

      if totalAssets == 0
        success()
      else
        @loadModel(name, callback) for name in models
        @getTexture(path, callback) for path in textures
        @loadImage(name, callback) for path in images

    loadImage: (name, callback) ->
      # TODO

    loadModel: (modelName, callback, friction=0.8, restitution=0.4) ->
      if modelName not of @models
        @models[modelName] = true
        @loader.load 'resources/' + modelName + '.js', (geom, materials) =>
          @models[modelName] =
            geom: geom
            material: new Physijs.createMaterial(materials[0], friction, restitution)
            useCount: 0

          if callback
            callback()

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

    getTexture: (path, callback) ->
      if path not of @textures
        @textures[path] = new THREE.ImageUtils.loadTexture(path, undefined, callback)

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
