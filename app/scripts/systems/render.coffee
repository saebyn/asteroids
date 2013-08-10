# render system
define ['THREE', 'Physijs'], (THREE, Physijs) ->
  # TODO move asset fetching into an external service singleton
  # Cache models fetched
  models = {}

  # Inst the model loader
  loader = new THREE.JSONLoader()

  addModelToScene = (app, id, entity) ->
    if not entity.renderable.mesh?
      model = entity.renderable.model

      # Skip if model isn't loaded
      if model not of models or models[model] == true
        return

      [geom, material] = models[model]

      obj = new Physijs.BoxMesh(geom, material)
      if entity.renderable.collideless?
        obj._physijs.type = 'sphere'
        obj._physijs.radius = 0

      entity.renderable.mesh = obj
    else
      obj = entity.renderable.mesh

    obj.name = id
    entity.renderable.meshLoaded = true
    app.scene.add obj
    updatePosition(id, entity)

  loadModel = (app, id, entity) ->
    model = entity.renderable.model

    models[model] = true
    loader.load '/resources/' + model + '.json', (geom, materials) ->
      models[model] = [geom, new Physijs.createMaterial(materials[0], 0.8, 0.4)]

  updatePosition = (id, entity) ->
    mesh = entity.renderable.mesh
    if mesh?.position
      mesh.position.x = entity.position.x
      mesh.position.y = entity.position.y
      mesh.rotation.x = entity.position.direction.x
      mesh.rotation.y = entity.position.direction.y
      mesh.rotation.z = entity.position.direction.z
      mesh.__dirtyPosition = true

    if entity.renderable.static?
      mesh.setLinearFactor({x: 0, y: 0, z: 0})


  (app, entities) ->
    ids = (id for [id, components] in entities)

    loadModel(app, id, components) for [id, components] in entities when components.renderable.model? and components.renderable.model not of models

    addModelToScene(app, id, components) for [id, components] in entities when not components.renderable.meshLoaded

    app.scene.simulate()
    app.renderer.render app.scene, app.camera
