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
    gameContainer = $('#game')
    playerStatsContainer = $('#player-stats')

    Physijs.scripts.worker = 'bower_components/Physijs/physijs_worker.js'
    Physijs.scripts.ammo = '../../bower_components/ammo.js/builds/ammo.js'

    app = new App(gameContainer, playerStatsContainer)
    window.app = app

    showAction = (action) ->
      if action is 'game'
        $('.btn[data-action="game"]').text('Continue Game')
        app.togglePause()

      $('.all > .fade.in').removeClass('in').addClass('hide')
      $('#' + action).removeClass('hide').addClass('in')

    $('.menu-btn').on 'click', ->
      showAction($(this).data('action'))

    if FullScreen.available()
      $('#go-fullscreen').removeClass('hide').on 'click', ->
        $('#go-fullscreen').button('toggle')
        if app.fullscreen
          FullScreen.cancel()
        else
          FullScreen.request($('.container.all')[0])

    $('#pause-continue').on 'click', ->
      app.togglePause()

    app.subscribe 'pause', ->
      showAction('menu')

    app.assetManager.preload(
      ['playership', 'laserbolt'],
      ['images/asteroid1.png', 'images/asteroid1_bump.png', 'images/particle.png'],
      ->
        $('#preloader').removeClass('in').addClass('hide')
        $('#menu').removeClass('hide').addClass('in')
    )

    app.subscribe('death', sounds.death)
    app.subscribe('fire', sounds.fire)
    app.subscribe('kill', sounds.kill)
    app.subscribe('hit', sounds.hit)

    app.gameloop()
