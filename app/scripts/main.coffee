root = exports ? this

require.config(
    paths:
      angular: '../bower_components/angular/angular'
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
      angular:
        exports: 'angular'
      bootstrap:
        deps: ['jquery']
        exports: '$'
      underscore:
        exports: '_'
    priority: [
      'angular',
    ]
)

window.name = 'NG_DEFER_BOOTSTRAP!'

require ['angular', 'app', 'game', 'keys', 'utils', 'jquery', 'Physijs', 'vendor/fullscreen', 'sounds', 'music', 'bootstrap'], (angular, app, Game, Keys, utils, $, Physijs, FullScreen, sounds, Music) ->
  root.mixpanel.track('Game load')

  Physijs.scripts.worker = 'bower_components/Physijs/physijs_worker.js'
  Physijs.scripts.ammo = '../../bower_components/ammo.js/builds/ammo.js'

  $html = angular.element(document.getElementsByTagName('html')[0])

  angular.element().ready(->
    $html.addClass 'ng-app'
    angular.bootstrap($html, [app['name']])
  )
