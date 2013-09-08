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


require ['game', 'keys', 'utils', 'jquery', 'Physijs', 'vendor/fullscreen', 'sounds', 'music', 'bootstrap'], (Game, Keys, utils, $, Physijs, FullScreen, sounds, Music) ->
  root.mixpanel.track('Game load')

  Physijs.scripts.worker = 'bower_components/Physijs/physijs_worker.js'
  Physijs.scripts.ammo = '../../bower_components/ammo.js/builds/ammo.js'

  window.game = game = new Game($('#game'), $('#player-stats'))

  window.music = music = new Music(game.assetManager)

  keys = new Keys(game)

  showAction = (action) ->
    root.mixpanel.track('Select ' + action)

    if action is 'game'
      $('.btn[data-action="game"]').text('Continue Game')
      game.togglePause()

    if action is 'stats'
      game.playerStats.renderLifetime($('#stats'))

    $('.all > .fade.in').removeClass('in').addClass('hide')
    $('#' + action).removeClass('hide').addClass('in')

  preload = ->
    game.assetManager.preload(
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
          if not utils.checkFeatures([Modernizr.webgl, '.check-webgl']
                                     [Modernizr.webworkers, '.check-workers'])
            return

          all = utils.checkFeatures [Modernizr.audio, '.check-audio'],
                                    [Modernizr.localstorage, '.check-localstorage']

          game.setup()
          # Start the game (it defaults to being paused)
          game.gameloop()
          if Modernizr.audio
            music.start()

          if not Modernizr.localstorage
            $('button[data-action="stats"]').attr(
              disabled: 'disabled'
              title: 'Requires HTML5 local storage'
            )

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
      if game.fullscreen
        FullScreen.cancel()
      else
        FullScreen.request($('.container.all')[0])

    $(window).on 'resize', ->
      game.fullscreen = FullScreen.activated()

  # Hook up weapon selectors to game.
  $('#toolbar .selector').on 'click', ->
    $('#toolbar .selector.active').removeClass('active')
    weapon = $(this).data('weapon-selector')
    if weapon
      game.emit('controls:selectWeapon', weapon)
      $(this).addClass('active')

  $(document).on 'keypress', (event) ->
    key = String.fromCharCode(event.charCode)
    offset = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'].indexOf(key)
    if offset != -1
      $('#toolbar .selector').eq(offset).click()


  # Hook up the pause button to the game
  $('#pause-continue').on 'click', ->
    game.togglePause()

  # Make pausing the game show the menu
  game.subscribe 'pause', ->
    showAction('menu')

  preload()

  # Hook up sounds
  game.subscribe('death', sounds.death)
  game.subscribe('fire', sounds.fire)
  game.subscribe('kill', sounds.kill)
  game.subscribe('hit', sounds.hit)
