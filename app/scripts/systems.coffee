define(['systems/render', 'systems/controls',
        'systems/weapons', 'systems/movement',
        'systems/expire', 'systems/spawners',
        'systems/generator'],
       (render, controls, weapons, movement, expire, spawners, generator) ->
         render: render
         controls: controls
         weapons: weapons
         movement: movement
         expire: expire
         spawners: spawners
         generator: generator
)
