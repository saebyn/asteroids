define ['THREE', 'Physijs', 'underscore', 'jquery'], (THREE, Physijs, _, $) ->
  class AssetManager
    maxCachedModels: 10
    models: {}
    textures: {}
    tracks: {}
    images: {}
    misc: {}

    constructor: ->
      # Inst the model loader
      @loader = new THREE.JSONLoader()

    preload: (assets, success) ->
      # load models and textures
      # when all are complete, call success with no args
      # always call success, even if no assets or they are
      # already loaded
      totalAssets = assets.models.length + assets.textures.length + assets.images.length + assets.misc.length
      loadedAssets = 0
      callback = (type, name) ->
        loadedAssets += 1
        console.log 'loaded', loadedAssets, 'of', totalAssets, '=', type, name
        if loadedAssets == totalAssets
          success()

      @loadTrack(path) for path in assets.music

      if totalAssets == 0
        success()
      else
        @getTexture(path, callback) for path in assets.textures
        @loadImage(path, callback) for path in assets.images
        @loadModel(name, callback) for name in assets.models
        @loadMisc(path, callback) for path in assets.misc

    loadMisc: (name, callback) ->
      $.ajax(
        url: name
        dataType: 'text'
        success: (data) =>
          @misc[name] = data
          callback('misc', name)
      )

    loadImage: (name, callback) ->
      img = new Image()
      img.src = name
      img.onload = =>
        @images[name] = img
        callback('image', name)

    loadModel: (modelName, callback, friction=0.8, restitution=0.4) ->
      if modelName not of @models
        @models[modelName] = true
        @loader.load 'resources/' + modelName + '.js', (geom, materials) =>
          # You'd think that we would be able to set this in the JSON file.
          materials[0].side = THREE.DoubleSide
          @models[modelName] =
            geom: geom
            material: new Physijs.createMaterial(materials[0], friction, restitution)
            useCount: 0

          if callback
            callback('model', modelName)

    loadTrack: (path) ->
      setTimeout =>
        track = new Audio()
        track.preload = 'auto'
        track.src = path
        track.addEventListener 'canplaythrough', =>
          @tracks[path] = track

        track.addEventListener 'error', =>
          @loadTrack(path)
      , Math.random() * 30000

    getTracks: ->
      _.values(@tracks)

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
        @textures[path] = new THREE.ImageUtils.loadTexture(path, undefined, ->
          callback('texture', path)
        )

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
