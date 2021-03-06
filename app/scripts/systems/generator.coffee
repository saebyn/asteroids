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
    asteroid1: (def, position) ->
      radius = def.radius or (Math.random() * 10.0 + 5.0)
      geom = new THREE.IcosahedronGeometry(radius, 4)
      # deform geometry randomly
      geom.vertices = _.map(geom.vertices, randomizeVertex(position, radius))
      geom.verticesNeedUpdate = true
      geom.dynamic = false
      geom.computeBoundingSphere()
      geom.computeFaceNormals()

      materialOptions = 
        shininess: 0

      if def.texture
        materialOptions.map = @app.assetManager.getTexture(def.texture)

      if def.bumpMap
        materialOptions.bumpMap = @app.assetManager.getTexture(def.bumpMap)
        materialOptions.bumpScale = def.bumpScale

      material = new Physijs.createMaterial(
        new THREE.MeshPhongMaterial(materialOptions),
        0.6,
        0.4)
      new Physijs.SphereMesh(geom, material)

    skybox: (def, position) ->
      base = 'images/sky/'
      # front, back, left, right, top, bottom
      paths = [base + 'frontmo.png',
              base + 'backmo.png',
              base + 'topmo.png',
              base + 'botmo.png',
              base + 'leftmo.png',
              base + 'rightmo.png']

      cubeTexture = THREE.ImageUtils.loadTextureCube(paths)
      shader = THREE.ShaderLib['cube']
      shader.uniforms['tCube'].value = cubeTexture

      skyboxMaterial = new THREE.ShaderMaterial(
        uniforms: shader.uniforms,
        fragmentShader: shader.fragmentShader,
        vertexShader: shader.vertexShader,
        depthWrite: false,
        side: THREE.BackSide
      )

      skyboxGeom = new THREE.CubeGeometry(2000, 2000, 2000)

      new THREE.Mesh(skyboxGeom, skyboxMaterial)

    ranger: (def, position) ->
      perimeterSegments = 64
      geom = new THREE.TorusGeometry(def.radius, 0.5, 6, perimeterSegments)
      geom2 = new THREE.CircleGeometry(def.radius, perimeterSegments)
      THREE.GeometryUtils.merge(geom, geom2, 1)
      outerMaterial = new THREE.MeshPhongMaterial(
        shininess: 0
        transparent: true
        opacity: 0.5
        emissive: 0x222222
        color: 0x000000
      )
      innerMaterial = new THREE.MeshPhongMaterial(
        shininess: 0
        transparent: true
        opacity: 0.2
        emissive: 0x222222
        color: 0x000000
        side: THREE.DoubleSide
      )

      material = new THREE.MeshFaceMaterial([
        outerMaterial,
        innerMaterial,
      ])
      new THREE.Mesh(geom, material)

    process: (entity, elapsed, id) ->
      generator = this[entity.generatable.type]
      mesh = generator.apply(this, [entity.generatable, entity.position])
      delete entity.generatable
      @app.scene.replaceEntity(entity, mesh)
