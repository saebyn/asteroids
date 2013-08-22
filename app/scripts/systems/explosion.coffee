# explosions system
define ['systems/base', 'THREE'], (System, THREE) ->
  randomVectorOnSphere = (radius) ->
    # get random rotations around sphere
    x = Math.random() * Math.PI * 2.0 - Math.PI
    y = Math.random() * Math.PI * 2.0 - Math.PI

    px = radius * Math.cos(x) * Math.sin(y)
    py = radius * Math.sin(x) * Math.sin(y)
    pz = radius * Math.cos(y)
    new THREE.Vector3(px, py, pz)

  class ExplosionSystem extends System
    # Create a particle system for the entity, and put that in
    # entity.renderable.mesh so that the render system can inject
    # it into the scene.
    setupEntity: (entity) ->
      particleCount = 500
      particles = new THREE.Geometry()
      pMaterial = new THREE.ParticleBasicMaterial(
        color: 0xFFFFFF
        size: 5
        map: THREE.ImageUtils.loadTexture('images/particle.png')
        blending: THREE.AdditiveBlending
        transparent: true
      )

      particles.vertices = (randomVectorOnSphere(entity.explosion.startRadius) for x in [0..particleCount])
      entity.renderable.mesh = new THREE.ParticleSystem(particles, pMaterial)
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
