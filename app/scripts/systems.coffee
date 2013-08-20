define(['systems/render', 'systems/controls',
        'systems/weapons', 'systems/movement',
        'systems/expire', 'systems/spawners',
        'systems/generator', 'systems/damage',
        'systems/explosion', 'systems/camera'],
       (render, controls, weapons, movement, expire, spawners, generator, damage, explosion, camera) ->
         register: (app) ->
           render: new render(app)
           controls: new controls(app)
           weapons: new weapons(app)
           movement: new movement(app)
           expire: new expire(app)
           spawners: new spawners(app)
           generator: new generator(app)
           damage: new damage(app)
           explosion: new explosion(app)
           camera: new camera(app)
)
