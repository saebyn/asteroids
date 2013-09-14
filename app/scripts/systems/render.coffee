# render system
define ['systems/base', 'THREE', 'Physijs'], (System, THREE, Physijs) ->
  class RenderSystem extends System
    addLight: (obj, lightDef) ->
      light = new THREE.SpotLight(lightDef.color or 0xffffff)
      light.position.set(lightDef.x or 0, lightDef.y or 0, lightDef.z or 0)

      light.distance = lightDef.distance or 0.0
      light.intensity = lightDef.intensity or 1.0

      if lightDef.direction?
        light.lookAt(lightDef.direction.x, lightDef.direction.y, lightDef.direction.z)
      obj.add light

    addModelToScene: (id, entity) ->
      if not entity.renderable.mesh?
        modelName = entity.renderable.model

        # If we need to load the model mesh, but it's not loaded yet,
        # quit for now, and we'll try again in the next game loop.
        if not @app.assetManager.isModelLoaded(modelName)
          return

        model = @app.assetManager.getModel(modelName)
  
        mass = undefined
        if entity.renderable.mass?
          mass = entity.renderable.mass
 
        # Note that since this model geometry might be reused, this setting
        # affects any uses of this model.
        model.geom.dynamic = false

        meshType = Physijs.BoxMesh

        if entity.renderable.convexCollision?
          meshType = Physijs.ConvexMesh
  
        obj = new meshType(model.geom, model.material, mass)

        if entity.renderable.receiveShadow?
          obj.receiveShadow = true
  
        entity.renderable.mesh = obj
      else
        obj = entity.renderable.mesh
  
      obj.name = id
      entity.renderable.meshLoaded = true
      @app.scene.add obj

      if entity.renderable.lights?
        @addLight(obj, light) for light in entity.renderable.lights

      # Lock all objects on the game plane
      if obj.setLinearFactor?
        obj.setLinearFactor(new THREE.Vector3(1, 1, 0))
  
      @setPosition(id, entity)

    setPosition: (id, entity) ->
      mesh = entity.renderable.mesh
      if entity?.position
        mesh.position.x = entity.position.x
        mesh.position.y = entity.position.y
        if entity.position.z?
          mesh.position.z = entity.position.z
        mesh.__dirtyPosition = true
        if entity.position.direction?
          mesh.rotation.x = entity.position.direction.x
          mesh.rotation.y = entity.position.direction.y
          mesh.rotation.z = entity.position.direction.z
          mesh.__dirtyRotation = true
  
      if entity.renderable.static?
        mesh.setLinearFactor(new THREE.Vector3(0, 0, 0))
 
    syncPhysicsPosition: (components) ->
      if components.position?
        components.position.x = components.renderable.mesh.position.x
        components.position.y = components.renderable.mesh.position.y
        components.position.z = components.renderable.mesh.position.z

        if components.position.direction?
          components.position.direction.x = components.renderable.mesh.rotation.x
          components.position.direction.y = components.renderable.mesh.rotation.y
          components.position.direction.z = components.renderable.mesh.rotation.z
  
    processOurEntities: (entities, elapsedTime) ->
      # TODO refactor to simplify
      # if the entity has a model specified, but it's not loaded...
      @app.assetManager.loadModel(components.renderable.model) for [id, components] in entities when components.renderable.model? and not @app.assetManager.isModelLoadStarted(components.renderable.model)

      @syncPhysicsPosition(components) for [id, components] in entities when components.renderable.meshLoaded
  
      # if the entity has a loaded model, but it's not in the scene...
      @addModelToScene(id, components) for [id, components] in entities when not components.renderable.meshLoaded
