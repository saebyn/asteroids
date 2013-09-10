root = exports ? this

define ['angular', 'game', 'music', 'sounds', 'keys', 'utils', 'vendor/fullscreen'], (angular, Game, Music, sounds, Keys, utils, FullScreen) ->
  angular.module('gameApp.directives', [])
    .directive('fullscreen', ->
      link: (scope, element, attrs) ->
        scope.supportsFullscreen = FullScreen.available()
        scope.fullscreen = false

        if scope.supportsFullscreen
            scope.fullscreen = FullScreen.activated()
            element.on 'click', ->
              scope.$apply((scope)->
                element.button('togggle')
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
      controller: ['$scope', ($scope) ->
        $scope.$watch 'musicPlaying', (musicPlaying, before, scope) ->
          if not scope.musicDisabled and scope.music?
            if musicPlaying
              scope.music.start()
            else
              scope.music.stop()
      ]
      link: (scope, element, attrs) ->
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
    .directive('preloader', ($timeout) ->
      restrict: 'A'
      link: (scope, element, attrs) ->
        scope.$watch 'game', (game) ->
          if not game?
            return

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
              $timeout ->
                if not utils.checkFeatures([Modernizr.webgl, '.check-webgl']
                                           [Modernizr.webworkers, '.check-workers'])
                  return

                all = utils.checkFeatures [Modernizr.audio, '.check-audio'],
                                          [Modernizr.localstorage, '.check-localstorage']

                scope.game.setup()
                # Start the game (it defaults to being paused)
                scope.game.gameloop()
                if Modernizr.audio
                  scope.musicPlaying = true
                else
                  scope.musicDisabled = true

                if not Modernizr.localstorage
                  $('button[data-action="stats"]').attr(
                    disabled: 'disabled'
                    title: 'Requires HTML5 local storage'
                  )

                if not all
                  angular.element('#continue-without-feature').removeClass('hide')
                else
                  $timeout ->
                    scope.$broadcast('showAction', 'menu')
                  , 500
              , 500
          )
    )
    .directive('weapons', ->
      restrict: 'A'
      link: (scope, element, attrs) ->
        selectors = element.find('.selector')

        # Hook up weapon selectors to game.
        selectors.on 'click', ->
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
        $scope.continued = false

        $scope.$on 'showAction', (scope, action) ->
          root.mixpanel.track('Select ' + action)

          if action is 'game'
            $scope.continued = true
            $scope.game.togglePause()

          if action is 'stats'
            $scope.renderLifetimeStats()
      ]
      link: (scope, element, attrs) ->
        element.find('.menu-btn').on 'click', ->
          scope.$emit('showAction', angular.element(this).data('action'))

        scope.$on 'showAction', (scope, action) ->
          angular.element('.all > .fade.in').removeClass('in').addClass('hide')
          angular.element('#' + action).removeClass('hide').addClass('in')

        scope.$watch 'game', (game) ->
          # Make pausing the game show the menu
          if game?
            game.subscribe 'pause', ->
              scope.$emit 'showAction', 'menu'
    )
