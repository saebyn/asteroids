# render system
define ['THREE'], (THREE) ->
  models = {}
  loader = new THREE.JSONLoader()

  loadModel = (app, id, entity) ->
    model = entity.renderable.model
    console.log 'load model', model
    models[model] = null
    loader.load '/resources/' + model + '.json', (geom, materials) ->
      obj = new THREE.Mesh(geom, materials[0])
      models[model] = obj
      app.scene.add obj

  (app, entities) ->
    loadModel(app, id, components) for [id, components] in entities when components?.renderable?.model not of models
    app.renderer.render app.scene, app.camera
