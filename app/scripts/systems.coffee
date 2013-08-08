define(['systems/render', 'systems/controls',
        'systems/weapons', 'systems/movement',
        'systems/expire', 'systems/spawners'],
       (render, controls, weapons, movement, expire, spawners) ->
         render: render
         controls: controls
         weapons: weapons
         movement: movement
         expire: expire
         spawners: spawners
)
