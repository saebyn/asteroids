define(['systems/render', 'systems/controls',
        'systems/weapons', 'systems/movement',
        'systems/expire', 'systems/spawners',
        'systems/generator', 'systems/damage',
        'systems/explosion', 'systems/camera',
        'systems/debris', 'systems/seeking',
        'systems/follow'],
       (render, controls, weapons, movement, expire, spawners, generator, damage, explosion, camera, debris, seeking, follow) ->
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
           debris: new debris(app)
           seeking: new seeking(app)
           follow: new follow(app)
)
