define [], ->
  class PlayerStats
    session:
      deaths: 0
      kills: 0
      time: 0

    lifetime:
      deaths: 0
      kills: 0

    constructor: (@container, app) ->
      app.subscribe 'death', =>
        @session.deaths += 1
        @lifetime.deaths += 1

      app.subscribe 'start', =>
        @session.time = 0

      app.subscribe 'kill', =>
        @session.kills += 1
        @lifetime.kills += 1

      if Modernizr.localstorage
        scores = window.localStorage.getItem('saebyn.asteroids.scores')
        if scores
          try
            scores = JSON.parse(scores)
          catch e
            return

          @lifetime.deaths = scores.deaths or 0
          @lifetime.kills = scores.kills or 0

    save: ->
      if Modernizr.localstorage
        window.localStorage.setItem('saebyn.asteroids.scores', JSON.stringify(
          deaths: @lifetime.deaths
          kills: @lifetime.kills
        ))

    render: (health, max) ->
      @container.find('.deaths .value').text(@session.deaths)
      @container.find('.kills .value').text(@session.kills)
      @container.find('.time .value').text((@session.time / 1000.0) | 0)
      @container.find('.health .current .value').text(health)
      @container.find('.health .max .value').text(max)
      percent = Math.round(health / max * 100.0)
      @container.find('.health .progress .bar').css({width: percent + '%'})

      @save()

    renderLifetime: (container) ->
      container.find('.deaths .value').text(@lifetime.deaths)
      container.find('.kills .value').text(@lifetime.kills)
