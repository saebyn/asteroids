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

    if FullScreen.available()
      $('#go-fullscreen').removeClass('hide').on 'click', ->
        $('#go-fullscreen').button('toggle')
        if app.fullscreen
          FullScreen.cancel()
        else
          FullScreen.request(gameContainer[0])

    app.assetManager.preload(
      ['playership', 'laserbolt'],
      ['images/asteroid1.png', 'images/asteroid1_bump.png', 'images/particle.png'],
      ->
        $('#preloader').removeClass('in').addClass('hide')
        $('#game').removeClass('hide').addClass('in')
    )

    app.subscribe('death', sounds.death)
    app.subscribe('fire', sounds.fire)
    app.subscribe('kill', sounds.kill)
    app.subscribe('hit', sounds.hit)

    app.gameloop()
