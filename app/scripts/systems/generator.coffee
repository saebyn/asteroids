define ['systems/base', 'THREE', 'Physijs'], (System, THREE, Physijs) ->
  class GeneratorSystem extends System
    generateModel: (entity) ->
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

    processOurEntities: (entities, elapsed) ->
      @generateModel(components) for [id, components] in entities
