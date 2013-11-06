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

    addModelToScene: (entity) ->
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

      entity.renderable.meshLoaded = true

      if entity.renderable.lights?
        @addLight(obj, light) for light in entity.renderable.lights

      @app.scene.replaceEntity(entity, obj)

    setPhysics: (entity) ->
      if entity.renderable.static?
        entity.setLinearFactor?(new THREE.Vector3(0, 0, 0))
  
    processOurEntities: (entities, elapsedTime) ->
      # TODO refactor to simplify
      # if the entity has a model specified, but it's not loaded...
      @app.assetManager.loadModel(components.renderable.model) for [id, components] in entities when components.renderable.model? and not @app.assetManager.isModelLoadStarted(components.renderable.model)

      for [id, entity] in entities
        if components.renderable.meshLoaded
          @setPhysics(entity)
        else
          # if the entity has a loaded model, but it's not in the scene...
          @addModelToScene(entity)
          # After the mesh is loaded, it's not safe to use the entity until the
          # next pass of this system.

