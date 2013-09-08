define ['utils'], (utils) ->
  WEAPONS =
    plasma:
      speed: 30
      size: 21 
      extraComponents:
        damagable:
          health: 0
        damaging:
          health: 10
          disappears: true
        renderable:
          model: 'laserbolt'
          mass: 0.001
        expirable:
          time: 2000
          destroy: true
    missile:
      speed: 5
      size: 21 
      extraComponents:
        damagable:
          health: 0
        damaging:
          health: 20
          disappears: true
        renderable:
          model: 'missile'
          mass: 0.1
        expirable:
          time: 3000
          destroy: true
        targeting:
          type: 'asteroidSpawner'
          force: 20
    mine:
      speed: 10
      size: 21
      extraComponents:
        damagable:
          health: 0
        damaging:
          health: 30
          disappears: true
        renderable:
          model: 'mine'
          mass: 0.2
        expirable:
          time: 1000
          destroy: false
          stop: true

  PLAYER =
    position: {x: 0, y: 0, direction: {x: 0, y: 0, z: 0}}
    renderable:
      model: 'playership'
      static: true
      convexCollision: true
    damagable:
      health: 30
      maxHealth: 30
    controllable: {left: 'left', right: 'right'}
    fireable: utils.clone(WEAPONS.plasma)

  PLAYER: PLAYER
  WEAPONS: WEAPONS
  ASTEROID_SPAWN_RATE: 0.1
  MAX_DISTANCE: 3400