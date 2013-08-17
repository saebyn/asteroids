define ['systems/base', 'THREE', 'Physijs', 'underscore'], (System, THREE, Physijs, _) ->
  randomizeVertex = (position) ->
    center = new THREE.Vector3(position.x, position.y, position.z)
    (vertex) ->
      distance = Math.random() * 2.5 - 1.25
      vertex.add(center.sub(vertex).normalize().multiplyScalar(distance))

  class GeneratorSystem extends System
    generateModel: (entity) ->
      radius = Math.random() * 10.0 + 5.0
      geom = new THREE.IcosahedronGeometry(radius, 2)
      # deform geometry randomly
      geom.vertices = _.map(geom.vertices, randomizeVertex(entity.position))
      geom.verticesNeedUpdate = true

      material = new Physijs.createMaterial(
        new THREE.MeshLambertMaterial(),
        0.6,
        0.4)
      mesh = new Physijs.SphereMesh(geom, material)

      entity.renderable =
        mesh: mesh

      delete entity.generatable

    processOurEntities: (entities, elapsed) ->
      @generateModel(components) for [id, components] in entities
