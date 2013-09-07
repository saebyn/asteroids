root = exports ? this

require.config(
    paths:
        jquery: '../bower_components/jquery/jquery'
        underscore: '../bower_components/underscore/underscore'
        THREE: '../bower_components/threejs/build/three'
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


require ['app', 'keys', 'jquery', 'Physijs', 'vendor/fullscreen', 'sounds', 'music', 'bootstrap'], (App, Keys, $, Physijs, FullScreen, sounds, Music) ->
  root.mixpanel.track('Game load')

  Physijs.scripts.worker = 'bower_components/Physijs/physijs_worker.js'
  Physijs.scripts.ammo = '../../bower_components/ammo.js/builds/ammo.js'

  window.app = app = new App($('#game'), $('#player-stats'))

  window.music = music = new Music(app.assetManager)

  keys = new Keys(app)

  showAction = (action) ->
    root.mixpanel.track('Select ' + action)

    if action is 'game'
      $('.btn[data-action="game"]').text('Continue Game')
      app.togglePause()

    if action is 'stats'
      app.playerStats.renderLifetime($('#stats'))

    $('.all > .fade.in').removeClass('in').addClass('hide')
    $('#' + action).removeClass('hide').addClass('in')

  checkFeatures = (features...) ->
    $(selector + ' .available').removeClass('hide') for [present, selector] in features when present
    $(selector + ' .not-available').removeClass('hide') for [present, selector] in features when not present
    $(selector + ' .unknown').addClass('hide') for [present, selector] in features
    (0 for [present, selector] in features when present).length == features.length

  preload = ->
    app.assetManager.preload(
      ['playership', 'laserbolt', 'missile', 'mine'],
      ['images/asteroid1.png', 'images/asteroid1_bump.png', 'images/particle.png',
       'images/particle_debris.png', 'images/star.png'],
      ['images/sky/backmo.png', 'images/sky/botmo.png', 'images/sky/frontmo.png',
       'images/sky/leftmo.png', 'images/sky/rightmo.png', 'images/sky/topmo.png'],
      ['resources/music/allofus.mp3', 'resources/music/arpanauts.mp3',
       'resources/music/comeandfindme.mp3', 'resources/music/digitalnative.mp3',
       'resources/music/hhavok-intro.mp3', 'resources/music/hhavok-main.mp3',
       'resources/music/searching.mp3', 'resources/music/underclocked.mp3',
       'resources/music/wereallunderthestars.mp3',
       'resources/music/weretheresistors.mp3'],
      ->
        $('#preloader .progress').hide()
        $('#preloader .status').text('Checking for browser support...')

        # check for support via modernizr
        setTimeout ->
          if not checkFeatures([Modernizr.webgl, '.check-webgl']
                               [Modernizr.webworkers, '.check-workers'])
            return

          all = checkFeatures [Modernizr.audio, '.check-audio'],
                              [Modernizr.localstorage, '.check-localstorage']

          app.setup()
          # Start the game (it defaults to being paused)
          app.gameloop()
          if Modernizr.audio
              music.start()
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

  # Hook up weapon selectors to app.
  $('#toolbar .selector').on 'click', ->
    $('#toolbar .selector.active').removeClass('active')
    weapon = $(this).data('weapon-selector')
    if weapon
      app.emit('controls:selectWeapon', weapon)
      $(this).addClass('active')

  $(document).on 'keypress', (event) ->
    key = String.fromCharCode(event.charCode)
    offset = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'].indexOf(key)
    if offset != -1
      $('#toolbar .selector').eq(offset).click()


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
