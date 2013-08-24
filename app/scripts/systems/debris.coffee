# debris system
define ['systems/base', 'utils', 'THREE'], (System, utils, THREE) ->
  # return a list of points distributed randomly
  # within a sphere of the radius
  randomPointsInSphere = (radius, count) ->
    utils.randomVectorInSphere(radius) for i in [0...count]

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
      particles.vertices = randomPointsInSphere(radius, particleCount)
      particleCloud = new THREE.ParticleSystem(particles, pMaterial)
      particleCloud.sortParticles = true

      entity.debris.particles = particles
      entity.renderable =
        mesh: particleCloud

    evolve: (entity, elapsedTime) ->
      speed = entity.debris.spread / 1000.0
      if entity.debris.spread > 0
        entity.debris.spread -= elapsedTime * speed
        randomVector = new THREE.Vector3(0, 0, 0)
        randomVector.addScalar(1.0 + elapsedTime / 1000.0 * speed)
        vector.multiply(randomVector) for vector in entity.debris.particles.vertices
        entity.renderable.mesh.geometry.__dirtyVertices = true

    processOurEntities: (entities, elapsedTime) ->
      @setup(components) for [id, components] in entities when not components.renderable?

      # If the particle system is set, then evolve it based on the elapsed time
      @evolve(components, elapsedTime) for [id, components] in entities when components.renderable?.mesh?