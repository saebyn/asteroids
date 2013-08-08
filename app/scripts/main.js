require.config({
    paths: {
        jquery: '../bower_components/jquery/jquery',
        underscore: '../bower_components/underscore/underscore',
        THREE: '../bower_components/threejs/build/three',
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
        THREE: {
            exports: 'THREE'
        }
    }
});

require(['app', 'jquery', 'bootstrap', 'THREE'], function (App, $) {
    'use strict';
    var app = new App();
    app.setup($('#game'))
    app.gameloop();
});
