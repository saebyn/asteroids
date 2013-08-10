define ['THREE', 'Physijs'], (THREE, Physijs) ->
  generateModel = (app, entity) ->
    radius = Math.random() * 10.0 + 5.0
    geom = new THREE.IcosahedronGeometry(radius, 2)
    # TODO deform geometry randomly
    material = new Physijs.createMaterial(
      new THREE.MeshLambertMaterial(),
      0.6,
      0.4)
    mesh = new Physijs.SphereMesh(geom, material)

    entity.renderable =
      mesh: mesh

    delete entity.generatable

  (app, entities, elapsed) ->
    generateModel(app, components) for [id, components] in entities
