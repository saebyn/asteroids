define [], ->
  class System
    constructor: (@app) ->

    # the problem with this is that it only gets called for new
    # entities, but not existing entities that have a new component
    # added.
    registerEntity: (entity) ->
      entity

    processOurEntities: (entities, elapsedTime) ->
