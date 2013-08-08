# render system
define ['THREE'], (THREE) ->
  meshes = {}
  # TODO cache the geometries and materials for each model
  # TODO find any loaded entities that aren't in the app anymore, and remove them
  loader = new THREE.JSONLoader()

  loadModel = (app, id, entity) ->
    model = entity.renderable.model
    meshes[id] = null
    loader.load '/resources/' + model + '.json', (geom, materials) ->
      obj = new THREE.Mesh(geom, materials[0])
      meshes[id] = obj
      app.scene.add obj

  updatePosition = (id, entity) ->
    mesh = meshes[id]
    if mesh
      mesh.position.x = entity.position.x
      mesh.position.y = entity.position.y
      mesh.rotation.x = entity.position.direction.x
      mesh.rotation.y = entity.position.direction.y
      mesh.rotation.z = entity.position.direction.z

  (app, entities) ->
    loadModel(app, id, components) for [id, components] in entities when id not of meshes
    updatePosition(id, components) for [id, components] in entities when components?.position
    app.renderer.render app.scene, app.camera
