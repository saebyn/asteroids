define [], ->
  class System
    constructor: (@app) ->

    # XXX TODO
    # the problem with this is that it only gets called for new
    # entities, but not existing entities that have a new component
    # added.
    registerEntity: (entity) ->
      entity

    processOurEntities: (entities, elapsedTime) ->
      @process(entity, elapsedTime, id) for [id, entity] in entities

    process: (entity, elapsedTime, id) ->

