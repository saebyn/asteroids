define [], ->
  class System
    constructor: (@app) ->

    # register and unregister methods must be idempotent, and must handle
    # entities that don't contain the component(s) of interest for the system.
    # registerEntity will be called each time a component is added
    # to the entity.
    # registerEntity MUST always return the entity.
    registerEntity: (entity, id) ->
      entity

    # unregisterEntity will only be called when the entity is removed,
    # not for individual component removals.
    unregisterEntity: (entity, id) ->
      null

    # TODO entity has the id in it, so no need to pass it around separately.
    processOurEntities: (entities, elapsedTime) ->
      @process(entity, elapsedTime, id) for [id, entity] in entities

    process: (entity, elapsedTime, id) ->

