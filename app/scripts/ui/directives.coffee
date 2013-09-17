root = exports ? this

define ['angular', 'game', 'music', 'sounds', 'keys', 'utils', 'vendor/fullscreen', 'underscore'], (angular, Game, Music, sounds, Keys, utils, FullScreen, _) ->
  angular.module('gameApp.directives', [])
    .directive('fullscreen', ->
      link: (scope, element, attrs) ->
        scope.supportsFullscreen = FullScreen.available()
        scope.fullscreen = false

        if scope.supportsFullscreen
            scope.fullscreen = FullScreen.activated()
            angular.element(element).on 'click', ->
              scope.$apply((scope)->
                element.toggleClass('active')
                if scope.game?.fullscreen
                  FullScreen.cancel()
                  scope.fullscreen = false
                else
                  FullScreen.request(angular.element('.container.all')[0])
                  scope.fullscreen = true
              )

            angular.element(root.window).on 'resize', ->
              scope.$apply (scope) ->
                scope.fullscreen = FullScreen.activated()

          scope.$watch 'fullscreen', (fullscreen) ->
            if scope.game?
              scope.game.fullscreen = fullscreen
    )
    .directive('game', ->
      scope:
        'container': '@'
        'playerStatsContainer': '@'
        'lifetimeStatsContainer': '@'
      restrict: 'E'
      controller: ['$scope', '$cookieStore', ($scope, $cookieStore) ->
        # TODO move this controller out of here, and tie it to
        # the settings element, rather than the game directive.
        $scope.$watch 'musicPlaying', (musicPlaying, before, scope) ->
          if not scope.musicDisabled and scope.music?
            $cookieStore.put('music', musicPlaying)
            if musicPlaying
              scope.music.start()
            else
              scope.music.stop()
      ]
      link: (scope, element, attrs) ->
        element.on 'selectstart', ->
          false

        dragging = false
        point = false

        element.on 'mousedown', ->
          element.addClass 'drag'
          dragging = true
          false

        element.on 'mouseup', ->
          element.removeClass 'drag'
          dragging = false
          point = false
          false

        element.on 'mouseleave', ->
          element.removeClass 'drag'
          dragging = false
          point = false
          false

        element.on 'mousemove', _.throttle (event) ->
          if scope.game? and dragging
            if point
              x = Math.min(10, Math.max(-10, -(event.pageY - point[1]))) / 5.0
              y = Math.min(10, Math.max(-10, -(event.pageX - point[0]))) / 5.0
              scope.game.emit 'controls:rotate', x, y

            point = [event.pageX, event.pageY]
        , 100

        scope.$watch 'container+playerStatsContainer', ->
          scope.game = new Game(
            angular.element(scope.container),
            angular.element(scope.playerStatsContainer)
          )
          scope.music = new Music(scope.game.assetManager)
          scope.keys = new Keys(scope.game)
          scope.musicDisabled = false
          scope.musicPlaying = false

        scope.renderLifetimeStats = ->
          if scope.game?
            scope.game.playerStats.renderLifetime(
              angular.element(scope.lifetimeStatsContainer)
            )

        scope.$watch 'game', (game) ->
          game.subscribe('death', sounds.death)
          game.subscribe('fire', sounds.fire)
          game.subscribe('kill', sounds.kill)
          game.subscribe('hit', sounds.hit)
    )
    .directive('preloader', ['$timeout', '$cookieStore', ($timeout, $cookieStore) ->
      restrict: 'A'
      link: (scope, element, attrs) ->
        scope.$watch 'game', (game) ->
          if not game?
            return

          game.assetManager.preload(
            ['playership', 'laserbolt', 'missile', 'mine'],
            ['images/asteroid1.png', 'images/asteroid1_bump.png', 'images/particle.png',
             'images/particle_debris.png', 'images/star.png',
             'resources/missile_texture.png', 'resources/MetalBase0121_9_S.jpg'],
            ['images/sky/backmo.png', 'images/sky/botmo.png', 'images/sky/frontmo.png',
             'images/sky/leftmo.png', 'images/sky/rightmo.png', 'images/sky/topmo.png'],
            ['bower_components/Physijs/physijs_worker.js'],
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
              $timeout ->
                if not utils.checkFeatures([Modernizr.webgl, '.check-webgl']
                                           [Modernizr.webworkers, '.check-workers'])
                  return

                all = utils.checkFeatures [Modernizr.audio, '.check-audio'],
                                          [Modernizr.localstorage, '.check-localstorage']

                scope.game.setup()
                # Start the game (it defaults to being paused)
                game.loadLevel('space')
                scope.game.gameloop()
                if Modernizr.audio
                  if $cookieStore.get('music') is not false
                    scope.musicPlaying = true
                else
                  scope.musicDisabled = true

                if not all
                  angular.element('#continue-without-feature').removeClass('hide')
                else
                  $timeout ->
                    scope.menu = 'menu'
                  , 500
              , 500
          )
    ])
    .directive('weapons', ->
      restrict: 'A'
      link: (scope, element, attrs) ->
        selectors = element.find('.selector')

        # Hook up weapon selectors to game.
        angular.element(selectors).on 'click', ->
          element.find('.selector.active').removeClass('active')
          weapon = angular.element(this).data('weapon-selector')
          if weapon and scope.game?
            scope.game.emit('controls:selectWeapon', weapon)
            $(this).addClass('active')

        angular.element(root.document).on 'keypress', (event) ->
          key = String.fromCharCode(event.charCode)
          offset = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'].indexOf(key)
          if offset != -1
            selectors.eq(offset).click()
    )
    .directive('gameMenu', ->
      restrict: 'A'
      controller: ['$scope', ($scope) ->
        $scope.Modernizr = root.Modernizr
        $scope.continued = false

        $scope.$watch 'menu', (action) ->
          if action?
            root.mixpanel.track('Select ' + action)

            if action is 'game'
              $scope.continued = true
              $scope.game.togglePause()

            if action is 'stats'
              $scope.renderLifetimeStats()
      ]
      link: (scope, element, attrs) ->
        scope.$watch 'menu', (action) ->
          if action?
            element.children('.fade.in').removeClass('in').addClass('hide')
            element.children('#' + action).removeClass('hide').addClass('in')

        scope.$watch 'game', (game) ->
          # Make pausing the game show the menu
          if game?
            game.subscribe 'pause', ->
              scope.$apply (scope) ->
                scope.menu = 'menu'
    )
