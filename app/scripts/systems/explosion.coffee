# explosions system
define ['systems/base', 'utils', 'THREE'], (System, utils, THREE) ->
  class ExplosionSystem extends System
    # Create a particle system for the entity, and put that in
    # entity.renderable.mesh so that the render system can inject
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
      entity.renderable.mesh = new THREE.ParticleSystem(particles, pMaterial)
      entity.renderable.particles = true
      entity.renderable.mesh.sortParticles = true
      entity.explosion.particles = particles

    evolveExplosion: (entity, elapsedTime) ->
      randomVector = new THREE.Vector3(Math.random(), Math.random(), Math.random())
      randomVector.divideScalar(4.0)
      randomVector.addScalar(1.0 + elapsedTime / 1000.0 * entity.explosion.speed)
      vector.multiply(randomVector) for vector in entity.explosion.particles.vertices
      entity.renderable.mesh.geometry.__dirtyVertices = true

    processOurEntities: (entities, elapsedTime) ->
      # If the entity is renderable but has no "mesh" (particle system)...
      @setupEntity(components) for [id, components] in entities when components.renderable? and not components.renderable.mesh?

      # If the particle system is set, then evolve it based on the elapsed time
      @evolveExplosion(components, elapsedTime) for [id, components] in entities when components.renderable?.mesh?
