root = exports ? this

require.config(
    paths:
      angular: '../bower_components/angular/angular'
      angularCookies: '../bower_components/angular-cookies/angular-cookies'
      jquery: '../bower_components/jquery/jquery'
      underscore: '../bower_components/underscore/underscore'
      'THREE.EffectComposer': '../bower_components/threejs/examples/js/postprocessing/EffectComposer'
      'THREE.MaskPass': '../bower_components/threejs/examples/js/postprocessing/MaskPass'
      'THREE.RenderPass': '../bower_components/threejs/examples/js/postprocessing/RenderPass'
      'THREE.ShaderPass': '../bower_components/threejs/examples/js/postprocessing/ShaderPass'
      'THREE.CopyShader': '../bower_components/threejs/examples/js/shaders/CopyShader'
      'THREE.FilmShader': '../bower_components/threejs/examples/js/shaders/FilmShader'
      'THREE.RGBShiftShader': '../bower_components/threejs/examples/js/shaders/RGBShiftShader'
      'THREE.VignetteShader': '../bower_components/threejs/examples/js/shaders/VignetteShader'
      THREE: '../bower_components/threejs/build/three'
      Physijs: '../bower_components/Physijs/physi'
      SimplexNoise: '../bower_components/simplex-noise.js/simplex-noise'
      audio: '../bower_components/jsfx/lib/audio'
      jsfx: '../bower_components/jsfx/lib/jsfx'
      jsfxlib: '../bower_components/jsfx/lib/jsfxlib'
    shim:
      'THREE.EffectComposer':
        exports: 'THREE'
        deps: ['THREE', 'THREE.CopyShader', 'THREE.MaskPass']
      'THREE.MaskPass':
        exports: 'THREE'
        deps: ['THREE']
      'THREE.RenderPass':
        exports: 'THREE'
        deps: ['THREE']
      'THREE.ShaderPass':
        exports: 'THREE'
        deps: ['THREE']
      'THREE.CopyShader':
        exports: 'THREE'
        deps: ['THREE']
      'THREE.VignetteShader':
        exports: 'THREE'
        deps: ['THREE']
      'THREE.RGBShiftShader':
        exports: 'THREE'
        deps: ['THREE']
      'THREE.FilmShader':
        exports: 'THREE'
        deps: ['THREE']
      angular:
        exports: 'angular'
        deps: ['jquery']
      angularCookies:
        deps: ['angular']
      underscore:
        exports: '_'
    priority: [
      'jquery',
      'angular',
    ]
)

window.name = 'NG_DEFER_BOOTSTRAP!'

require ['jquery', 'angular', 'app', 'Physijs', 'angularCookies'], ($, angular, app, Physijs) ->
  root.mixpanel.track('Game load')

  Physijs.scripts.worker = 'bower_components/Physijs/physijs_worker.js'
  Physijs.scripts.ammo = '../../bower_components/ammo.js/builds/ammo.js'

  $html = angular.element(document.getElementsByTagName('html')[0])

  angular.element().ready(->
    $html.addClass 'ng-app'
    angular.bootstrap($html, [app['name']])
  )
