define ['THREE', 'utils'], (THREE, utils) ->
  (assetManager, scene) ->
    base = 'images/sky/'
    # front, back, left, right, top, bottom
    paths = [base + 'frontmo.jpg',
             base + 'backmo.jpg',
             base + 'topmo.jpg',
             base + 'botmo.jpg',
             base + 'leftmo.jpg',
             base + 'rightmo.jpg']

    # TODO use assetManager
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

    skyboxGeom = new THREE.CubeGeometry(10000, 10000, 10000)

    skybox = new THREE.Mesh(skyboxGeom, skyboxMaterial)
    scene.add(skybox)
