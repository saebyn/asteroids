define ['systems/base', 'THREE', 'Physijs', 'SimplexNoise', 'underscore'], (System, THREE, Physijs, SimplexNoise, _) ->
  noiseVector = (simplex, vector, freq, size) ->
    simplex.noise3D(vector.x / freq,
                    vector.y / freq,
                    vector.z / freq) * size

  threshold = (v, min, d) ->
    if Math.abs(v) < min then d else v

  randomizeVertex = (position, radius) ->
    center = new THREE.Vector3(position.x, position.y, position.z)
    simplex = new SimplexNoise()
    featureFrequency = 14.0
    featureSize = 2.0

    (vertex) ->
      distance = noiseVector(simplex, vertex, 14.0, 1.75) +
                 noiseVector(simplex, vertex, 7.0, 0.7) +
                 noiseVector(simplex, vertex, 1.5, 0.4)
      direction = center.sub(vertex).normalize()
      vertex.add(direction.multiplyScalar(distance))

  class GeneratorSystem extends System
    generateModel: (entity) ->
      radius = Math.random() * 10.0 + 5.0
      geom = new THREE.IcosahedronGeometry(radius, 4)
      # deform geometry randomly
      geom.vertices = _.map(geom.vertices, randomizeVertex(entity.position, radius))
      geom.verticesNeedUpdate = true
      geom.dynamic = false

      materialOptions = {}

      if entity.generatable.texture
        materialOptions.map = @app.assetManager.getTexture(entity.generatable.texture)

      material = new Physijs.createMaterial(
        new THREE.MeshLambertMaterial(materialOptions),
        0.6,
        0.4)
      mesh = new Physijs.SphereMesh(geom, material)

      entity.renderable =
        mesh: mesh

      delete entity.generatable

    processOurEntities: (entities, elapsed) ->
      @generateModel(components) for [id, components] in entities
