require.config({
    paths: {
        jquery: '../bower_components/jquery/jquery',
        underscore: '../bower_components/underscore/underscore',
        THREE: '../bower_components/threejs/build/three',
        Stats: '../bower_components/stats.js/src/Stats',
        Physijs: '../bower_components/Physijs/physi',
        bootstrap: 'vendor/bootstrap',
        'THREEx.FullScreen': 'vendor/THREEx.FullScreen',
        'THREEx.RendererStats': 'vendor/THREEx.RendererStats',
        SimplexNoise: '../bower_components/simplex-noise.js/simplex-noise'
    },
    shim: {
        bootstrap: {
            deps: ['jquery'],
            exports: 'jquery'
        },
        underscore: {
            exports: '_'
        },
        Physijs: {
            exports: 'Physijs',
            deps: ['THREE']
        },
        THREE: {
            exports: 'THREE'
        },
        Stats: {
            exports: 'Stats',
        },
        'THREEx.FullScreen': {
            exports: 'THREEx.FullScreen',
            deps: ['THREE']
        },
        'THREEx.RendererStats': {
            exports: 'THREEx.RendererStats',
            deps: ['THREE']
        }
    }
});

require(['app', 'jquery', 'Physijs', 'THREEx.FullScreen', 'bootstrap'], function (App, $, Physijs, FullScreen) {
    'use strict';

    var gameContainer = $('#game'),
        playerStatsContainer = $('#player-stats');

    Physijs.scripts.worker = '/bower_components/Physijs/physijs_worker.js';
    Physijs.scripts.ammo = '/bower_components/ammo.js/builds/ammo.js';

    var app = new App(gameContainer, playerStatsContainer);

    if ( FullScreen.available() ) {
      $('#go-fullscreen').removeClass('hide').on('click', function () {
        $('#go-fullscreen').button('toggle');
        if ( app.fullscreen ) {
          FullScreen.cancel();
        } else {
          FullScreen.request(gameContainer[0]);
        }
      });
    }

    app.gameloop();
});
