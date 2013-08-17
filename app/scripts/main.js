require.config({
    paths: {
        jquery: '../bower_components/jquery/jquery',
        underscore: '../bower_components/underscore/underscore',
        THREE: '../bower_components/threejs/build/three',
        Physijs: '../bower_components/Physijs/physi',
        bootstrap: 'vendor/bootstrap',
        THREEx: 'vendor/THREEx.FullScreen'
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
        THREEx: {
            exports: 'THREEx',
            deps: ['THREE']
        }
    }
});

require(['app', 'devhud', 'jquery', 'Physijs', 'THREEx', 'bootstrap'], function (App, DevHUD, $, Physijs, THREEx) {
    'use strict';

    var gameContainer = $('#game');

    Physijs.scripts.worker = '/bower_components/Physijs/physijs_worker.js';
    Physijs.scripts.ammo = '/bower_components/ammo.js/builds/ammo.js';

    if ( THREEx.FullScreen.available() ) {
      $('#go-fullscreen').removeClass('hide').on('click', function () {
        THREEx.FullScreen.request(gameContainer[0]);
      });
    }

    var app = new App(gameContainer);
    app.gameloop();

    new DevHUD(app);
});
