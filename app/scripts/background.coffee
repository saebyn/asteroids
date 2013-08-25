define ['THREE', 'utils'], (THREE, utils) ->
  createStars = (starType, texture) ->
    # starType: radius, count, size, minDist, color
    particles = new THREE.Geometry()
    starMaterial = new THREE.ParticleBasicMaterial(
      color: starType.color
      size: starType.size
      map: texture
      blending: THREE.AdditiveBlending
      transparent: true
    )
    particles.vertices = utils.randomPointsInSphere(starType.radius,
                                                    starType.count,
                                                    starType.minDist)
    stars = new THREE.ParticleSystem(particles, starMaterial)
    stars.sortParticles = true
    stars

  createNebula = (nebulaType, textures) ->
    nebulaParticles = new THREE.Geometry()
    nebulaMaterial = new THREE.ParticleBasicMaterial(
      color: nebulaType.color
      size: nebulaType.size
      map: textures[nebulaType.texture]
      blending: THREE.AdditiveBlending
      transparent: true
    )
    nebulaParticles.vertices = utils.randomPointsInSphere(nebulaType.radius,
                                                          nebulaType.count,
                                                          nebulaType.minDist)
    nebula = new THREE.ParticleSystem(nebulaParticles, nebulaMaterial)
    nebula.sortParticles = true
    nebula

  (assetManager, scene) ->
    starTexture = assetManager.getTexture 'images/star.png'
    nebulaTextures = [
      assetManager.getTexture('images/nebula1.png'),
      assetManager.getTexture('images/nebula2.png'),
      assetManager.getTexture('images/nebula3.png')
    ]

    nebulaTypes = [
      {texture: 0, size: 380, color: '#1221aa', count: 2, minDist: 498, radius: 499},
      {texture: 1, size: 470, color: '#22ab11', count: 2, minDist: 498, radius: 499},
      {texture: 2, size: 790, color: '#a41122', count: 2, minDist: 498, radius: 499},
    ]

    starTypes = [
      {color: '#114fe2', size: 40, count: 1000, minDist: 1000, radius: 5000},
      {color: '#e77c34', size: 15, count: 1000, minDist: 500, radius: 5000},
      {color: '#e7db65', size: 10, count: 2000, minDist: 1000, radius: 5000},
      {color: '#fefcfd', size: 20, count: 1500, minDist: 500, radius: 5000},
    ]

    scene.add(createStars(starType, starTexture)) for starType in starTypes

    scene.add(createNebula(nebulaType, nebulaTextures)) for nebulaType in nebulaTypes
