require.config({
    paths: {
        jquery: '../bower_components/jquery/jquery',
        underscore: '../bower_components/underscore/underscore',
        THREE: '../bower_components/threejs/build/three',
        Physijs: '../bower_components/Physijs/physi',
        bootstrap: 'vendor/bootstrap'
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
        }
    }
});

require(['app', 'devhud', 'jquery', 'Physijs', 'bootstrap', 'THREE'], function (App, DevHUD, $, Physijs) {
    'use strict';

    Physijs.scripts.worker = '/bower_components/Physijs/physijs_worker.js';
    Physijs.scripts.ammo = '/bower_components/ammo.js/builds/ammo.js';

    var app = new App($('#game'));
    app.gameloop();

    new DevHUD(app);
});
