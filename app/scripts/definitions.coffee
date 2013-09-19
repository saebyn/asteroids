define ['utils'], (utils) ->
  WEAPONS =
    plasma:
      inventorySource: 'energy'
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
      inventorySource: 'missile'
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
        seeking:
          type: 'asteroidSpawner'
          force: 20
    mine:
      inventorySource: 'mine'
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
    position: {x: 0, y: 0, z: 0, direction: {x: -Math.PI / 2, y: 0, z: Math.PI / 2}}
    inventory:
      energy: 1000
      missile: 50
      mine: 30
    renderable:
      lights: [
        {
          color: 0xff0000
          distance: 30.0
          intensity: 1
          x: 0.1
          y: 0.0
          z: 0.0
          direction:
            x: 1.0
            y: 0
            z: 0
        }
        {
          color: 0xff0000
          distance: 40.0
          intensity: 1
          x: -0.26
          y: 0.0
          z: 0.0
          direction:
            x: -1.0
            y: 0
            z: 0
        }
      ]
      model: 'playership'
      static: true
      convexCollision: true
    damagable:
      health: 100
      maxHealth: 100
    controllable:
      left: 'left'
      right: 'right'
      up: 'up'
      down: 'down'
      tiltLeft: 'tiltLeft'
      tiltRight: 'tiltRight'
    fireable: utils.clone(WEAPONS.plasma)

  PLAYER: PLAYER
  WEAPONS: WEAPONS
  ASTEROID_SPAWN_RATE: 0.1
  MAX_DISTANCE: 3400
  ASSETS:
    models: ['playership', 'laserbolt', 'missile', 'mine']
    textures: [
      'images/asteroid1.png', 'images/asteroid1_bump.png', 'images/particle.png',
      'images/particle_debris.png', 'images/star.png',
      'resources/missile_texture.png', 'resources/MetalBase0121_9_S.jpg']
    images: [
      'images/sky/backmo.png', 'images/sky/botmo.png', 'images/sky/frontmo.png',
      'images/sky/leftmo.png', 'images/sky/rightmo.png', 'images/sky/topmo.png']
    misc: [
      'bower_components/ammo.js/builds/ammo.js',
      'bower_components/Physijs/physijs_worker.js']
    music: [
      'resources/music/allofus.mp3', 'resources/music/arpanauts.mp3',
      'resources/music/comeandfindme.mp3', 'resources/music/digitalnative.mp3',
      'resources/music/hhavok-intro.mp3', 'resources/music/hhavok-main.mp3',
      'resources/music/searching.mp3', 'resources/music/underclocked.mp3',
      'resources/music/wereallunderthestars.mp3',
      'resources/music/weretheresistors.mp3']
