root = exports ? this

require.config(
    paths:
        jquery: '../bower_components/jquery/jquery'
        underscore: '../bower_components/underscore/underscore'
        THREE: '../bower_components/threejs/build/three'
        Stats: '../bower_components/stats.js/src/Stats'
        Physijs: '../bower_components/Physijs/physi'
        bootstrap: 'vendor/bootstrap'
        SimplexNoise: '../bower_components/simplex-noise.js/simplex-noise'
        audio: '../bower_components/jsfx/lib/audio'
        jsfx: '../bower_components/jsfx/lib/jsfx'
        jsfxlib: '../bower_components/jsfx/lib/jsfxlib'
    shim:
        bootstrap:
            deps: ['jquery']
            exports: '$'
        underscore:
            exports: '_'
)


require ['app', 'jquery', 'Physijs', 'vendor/fullscreen', 'sounds', 'bootstrap'], (App, $, Physijs, FullScreen, sounds) ->
  root.mixpanel.track('Game load')

  gameContainer = $('#game')
  playerStatsContainer = $('#player-stats')

  Physijs.scripts.worker = 'bower_components/Physijs/physijs_worker.js'
  Physijs.scripts.ammo = '../../bower_components/ammo.js/builds/ammo.js'

  app = new App(gameContainer, playerStatsContainer)
  window.app = app

  showAction = (action) ->
    root.mixpanel.track('Select ' + action)

    if action is 'game'
      $('.btn[data-action="game"]').text('Continue Game')
      app.togglePause()

    $('.all > .fade.in').removeClass('in').addClass('hide')
    $('#' + action).removeClass('hide').addClass('in')

  checkFeatures = (features...) ->
    $(selector + ' .available').removeClass('hide') for [present, selector] in features when present
    $(selector + ' .not-available').removeClass('hide') for [present, selector] in features when not present
    $(selector + ' .unknown').addClass('hide') for [present, selector] in features
    (0 for [present, selector] in features when present).length == features.length

  preload = ->
    app.assetManager.preload(
      ['playership', 'laserbolt'],
      ['images/asteroid1.png', 'images/asteroid1_bump.png', 'images/particle.png',
      'images/particle_debris.png'],
      ->
        $('#preloader .progress').hide()
        $('#preloader .status').text('Checking for browser support...')

        # check for support via modernizr
        setTimeout ->
          if not checkFeatures [Modernizr.webgl, '.check-webgl']
            return

          all = checkFeatures [Modernizr.audio, '.check-audio'],
                              [Modernizr.localstorage, '.check-localstorage']

          app.setup()
          # Start the game (it defaults to being paused)
          app.gameloop()
          if not all
            $('#continue-without-feature').removeClass('hide')
          else
            setTimeout ->
              showAction 'menu'
            , 500
        , 500
    )

  # Hook up menu buttons
  $('.menu-btn').on 'click', ->
    showAction($(this).data('action'))

  # Make the full screen button visible if that's supported.
  if FullScreen.available()
    $('#go-fullscreen').removeClass('hide').on 'click', ->
      $('#go-fullscreen').button('toggle')
      if app.fullscreen
        FullScreen.cancel()
      else
        FullScreen.request($('.container.all')[0])

  # Hook up the pause button to the app
  $('#pause-continue').on 'click', ->
    app.togglePause()

  # Make pausing the game show the menu
  app.subscribe 'pause', ->
    showAction('menu')

  preload()

  # Hook up sounds
  app.subscribe('death', sounds.death)
  app.subscribe('fire', sounds.fire)
  app.subscribe('kill', sounds.kill)
  app.subscribe('hit', sounds.hit)
