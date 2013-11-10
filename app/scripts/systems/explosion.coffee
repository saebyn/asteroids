# explosions system
define ['systems/base', 'utils', 'THREE'], (System, utils, THREE) ->
  class ExplosionSystem extends System
    # Create a particle system for the entity, and put that in
    # entity so that the render system can inject
    # it into the scene.
    setupEntity: (entity) ->
      radius = entity.explosion.startRadius
      particleCount = 100 * (radius / 10.0)
      particles = new THREE.Geometry()
      pMaterial = new THREE.ParticleBasicMaterial(
        color: 0xFFFFFF
        size: 5
        map: @app.assetManager.getTexture('images/particle.png')
        blending: THREE.AdditiveBlending
        transparent: true
      )

      particles.vertices = (utils.randomVectorOnSphere(radius) for x in [0..particleCount])
      particlesObj = new THREE.ParticleSystem(particles, pMaterial)
      particlesObj.sortParticles = true
      particlesObj.particles = true
      @app.scene.replaceEntity(entity, particlesObj)

    evolveExplosion: (entity, elapsedTime) ->
      randomVector = new THREE.Vector3(Math.random(), Math.random(), Math.random())
      randomVector.divideScalar(4.0)
      randomVector.addScalar(1.0 + elapsedTime / 1000.0 * entity.explosion.speed)
      vector.multiply(randomVector) for vector in entity.geometry.vertices
      entity.geometry.__dirtyVertices = true

    process: (entity, elapsedTime) ->
      if not entity.particles
        @setupEntity(entity)
      else
        # If the particle system is set, then evolve it based on the elapsed time
        @evolveExplosion(entity, elapsedTime)
