# render system
define ['systems/base', 'THREE', 'Physijs'], (System, THREE, Physijs) ->
  class RenderSystem extends System
    constructor: (@app) ->
      @models = {}

      # Inst the model loader
      @loader = new THREE.JSONLoader()

    lock2d: (mesh) ->
      mesh.setLinearFactor(new THREE.Vector3(1, 1, 0))

    addModelToScene: (id, entity) ->
      if not entity.renderable.mesh?
        model = entity.renderable.model
  
        # Skip if model isn't loaded
        if model not of @models or @models[model] == true
          return
  
        [geom, material] = @models[model]
  
        mass = undefined
        if entity.renderable.mass?
          mass = entity.renderable.mass
  
        obj = new Physijs.BoxMesh(geom, material, mass)
        if entity.renderable.collideless?
          obj._physijs.type = 'sphere'
          obj._physijs.radius = 0
  
        entity.renderable.mesh = obj
      else
        obj = entity.renderable.mesh
  
      obj.name = id
      entity.renderable.meshLoaded = true
      @app.scene.add obj
      @lock2d(obj)
  
      @updatePosition(id, entity)
  
    loadModel: (id, entity) ->
      model = entity.renderable.model
  
      @models[model] = true
      @loader.load '/resources/' + model + '.js', (geom, materials) =>
        @models[model] = [geom, new Physijs.createMaterial(materials[0], 0.8, 0.4)]
  
    updatePosition: (id, entity) ->
      mesh = entity.renderable.mesh
      if entity?.position
        mesh.position.x = entity.position.x
        mesh.position.y = entity.position.y
        mesh.__dirtyPosition = true
        if entity.position.direction?
          mesh.rotation.x = entity.position.direction.x
          mesh.rotation.y = entity.position.direction.y
          mesh.rotation.z = entity.position.direction.z
          mesh.__dirtyRotation = true
  
      if entity.renderable.static?
        mesh.setLinearFactor({x: 0, y: 0, z: 0})
        @app.scene.add new Physijs.HingeConstraint(
          mesh,
          new THREE.Vector3(0, 0, 0),
          new THREE.Vector3(0, 0, 1)
        )
  
  
    processOurEntities: (entities, elapsedTime) ->
      ids = (id for [id, components] in entities)
  
      @loadModel(id, components) for [id, components] in entities when components.renderable.model? and components.renderable.model not of @models
  
      @addModelToScene(id, components) for [id, components] in entities when not components.renderable.meshLoaded
  
      @app.scene.simulate()
      @app.renderer.render @app.scene, @app.camera
