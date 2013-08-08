# render system
define ['THREE'], (THREE) ->
  # TODO move asset fetching into an external service singleton
  # Cache models fetched
  models = {}

  # Inst the model loader
  loader = new THREE.JSONLoader()

  addModelToScene = (app, id, entity, model) ->
    [geom, material] = models[model]
    obj = new THREE.Mesh(geom, material)
    obj.name = id
    entity.renderable.mesh = obj
    app.scene.add obj

  loadModel = (app, id, entity) ->
    model = entity.renderable.model

    if model not of models
      entity.renderable.mesh = true
      loader.load '/resources/' + model + '.json', (geom, materials) ->
        models[model] = [geom, materials[0]]
        addModelToScene app, id, entity, model
    else
      addModelToScene app, id, entity, model

  updatePosition = (id, entity) ->
    mesh = entity.renderable.mesh
    if mesh?.position
      mesh.position.x = entity.position.x
      mesh.position.y = entity.position.y
      mesh.rotation.x = entity.position.direction.x
      mesh.rotation.y = entity.position.direction.y
      mesh.rotation.z = entity.position.direction.z

  (app, entities) ->
    ids = (id for [id, components] in entities)

    loadModel(app, id, components) for [id, components] in entities when not components.renderable.mesh?

    updatePosition(id, components) for [id, components] in entities when components?.position

    # Remove any objects in the scene but not registered as an
    # entity, if the object has a name.
    stale = []
    app.scene.traverse (obj) ->
      if obj.name and obj.name not in ids
        stale.push obj

    app.scene.remove(obj) for obj in stale

    app.renderer.render app.scene, app.camera
