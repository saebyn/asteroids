define ['utils', 'definitions'], (utils, gameDefinitions) ->
  station: 
    player: utils.clone(gameDefinitions.PLAYER)
    camera:
      camera:
        type: 'perspective'
        viewAngle: 90.0
        aspect: 1.0
        nearDistance: 0.1
        farDistance: 100
        position:
          x: 0
          y: 0
          z: 50
        view:
          left: 0
          bottom: 0
          width: 1
          height: 1
        order: 1
  space:
    player: utils.clone(gameDefinitions.PLAYER)
    camera:
      camera:
        type: 'perspective'
        viewAngle: 45.0
        aspect: 1.0
        nearDistance: 0.1
        farDistance: 10000
        position:
          x: 0
          y: 0
          z: 500
        view:
          left: 0
          bottom: 0
          width: 1
          height: 1
        order: 1
    altcamera:
      camera:
        type: 'perspective'
        viewAngle: 45.0
        aspect: 1.0
        nearDistance: 0.1
        farDistance: 1600
        radar: true
        position:
          x: 0
          y: 0
          z: 1500
        view:
          left: 0.75
          bottom: 0.75
          width: 0.15
          height: 0.15
          background: '#004400'
          backgroundAlpha: 0.5
        order: 2
    asteroidSpawner:
      spawnable:
        radius: 1000.0
        max: 30
        rate: gameDefinitions.ASTEROID_SPAWN_RATE
        rateChange: 0.005
        extraComponents:
          damagable:
            health: 20
            fracture:
              chance: 0.3
              generatable:
                type: 'asteroid1'
                texture: 'images/asteroid1.png'
                bumpMap: 'images/asteroid1_bump.png'
                bumpScale: 1.0
          damaging:
            health: 5
          generatable:
            type: 'asteroid1'
            texture: 'images/asteroid1.png'
            bumpMap: 'images/asteroid1_bump.png'
            bumpScale: 1.0

