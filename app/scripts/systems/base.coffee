define [], ->
  class System
    constructor: (@app) ->

    registerEntity: (entity) ->
      entity

    processOurEntities: (entities, elapsedTime) ->
