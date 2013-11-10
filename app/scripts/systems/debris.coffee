# debris system
define ['systems/base', 'utils', 'THREE'], (System, utils, THREE) ->
  class DebrisSystem extends System
    setup: (entity) ->
      radius = entity.debris.radius

      particleCount = 50 * (radius / 10.0)
      particles = new THREE.Geometry()
      pMaterial = new THREE.ParticleBasicMaterial(
        color: 0xFFFFFF
        size: 10
        map: @app.assetManager.getTexture('images/particle_debris.png')
        blending: THREE.AdditiveBlending
        transparent: true
      )
      particles.vertices = utils.randomPointsInSphere(radius, particleCount)
      particleCloud = new THREE.ParticleSystem(particles, pMaterial)
      particleCloud.sortParticles = true
      particleCloud.particles = true

      entity.debris.particles = particles
      @app.scene.replaceEntity(entity, particleCloud)

    evolve: (entity, elapsedTime) ->
      speed = entity.debris.spread / 1000.0
      if entity.debris.spread > 100
        entity.debris.spread -= elapsedTime * speed
        randomVector = new THREE.Vector3(0, 0, 0)
        randomVector.addScalar(1.0 + elapsedTime / 1000.0 * speed)
        vector.multiply(randomVector) for vector in entity.geometry.vertices
        entity.renderable.mesh.geometry.__dirtyVertices = true
      else
        @app.scene.removeEntity(id)

    process: (entity, elapsedTime) ->
      if not entity.particles
        @setup(entity)
      else
        # If the particle system is set, then evolve it based on the elapsed time
        @evolve(entity, elapsedTime)
