define ['underscore'], (_) ->
  average = (list) ->
    _.reduce(list, (a, b) -> a + b) / list.length

  update = (app) ->
    averageMsecPerFrame = average(app.frameTimes)
    fps = 1000 / averageMsecPerFrame
    console.log 'Stats: fps =', fps, ', entity count =', _.keys(app.entities).length

    setTimeout(->
      update app
    , 5000)

  (app) ->
    update(app)
