define ['utils', 'definitions', 'THREE'], (utils, gameDefinitions, THREE) ->
  sleep:
    camera:
      camera:
        type: 'ortho'
        left: -10
        right: 10
        top: -10
        bottom: 10
        nearDistance: 0.1
        farDistance: 100
        position: new THREE.Vector3(0, 0, 50)
        view:
          left: 0
          bottom: 0
          width: 1
          height: 1
        order: 1
  station: 
    player: utils.clone(gameDefinitions.PLAYER)
    camera:
      camera:
        type: 'perspective'
        viewAngle: 90.0
        aspect: 1.0
        nearDistance: 0.1
        farDistance: 100
        position: new THREE.Vector3(0, 0, 50)
        view:
          left: 0
          bottom: 0
          width: 1
          height: 1
        order: 1
  space:
    player: utils.clone(gameDefinitions.PLAYER)
    background:
      generatable:
        type: 'skybox'
      position: new THREE.Vector3(0, 0, 0)
    rangeFinder:
      generatable:
        type: 'ranger'
        radius: 100
      position: new THREE.Vector3(0, 0, 0)
      rotation: new THREE.Euler(Math.PI / 2, 0, 0)
      follow:
        entity: 'player'
        smooth: false
        vector: new THREE.Vector3(0, 0, 0)
    camera:
      position: new THREE.Vector3(0, 0, 500)
      rotation: new THREE.Euler(0, 0, Math.PI / 2)
      up: new THREE.Vector3(0, 0, 1)
      camera:
        composer: true
        type: 'perspective'
        viewAngle: 45.0
        aspect: 1.0
        nearDistance: 0.1
        farDistance: 10000
        view:
          left: 0
          bottom: 0
          width: 1
          height: 1
        order: 1
      follow:
        entity: 'player'
        smooth: true
        vector: new THREE.Vector3(0, 0, 500)
    altcamera:
      position: new THREE.Vector3(0, 0, 1500)
      camera:
        type: 'perspective'
        viewAngle: 45.0
        aspect: 1.0
        nearDistance: 0.1
        farDistance: 1600
        radar: true
        view:
          left: 0.75
          bottom: 0.75
          width: 0.15
          height: 0.15
          background: '#004400'
          backgroundAlpha: 0.5
        order: 2
    firstAsteroid:
      spawned: 'asteroidSpawner'
      position: new THREE.Vector3(150, 150, 0)
      rotation: new THREE.Euler(Math.random() * 2.0 * Math.PI, Math.random() * 2.0 * Math.PI, Math.random() * 2.0 * Math.PI)
      movement:
        spin: new THREE.Vector3(
                Math.random() - 0.5,
                Math.random() - 0.5,
                Math.random() - 0.5).normalize().multiplyScalar(0.001)
        direction: new THREE.Vector3(-0.002, -0.002, 0)
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
    asteroidSpawner:
      spawnable:
        radius: 1000.0
        max: 30
        rate: gameDefinitions.ASTEROID_SPAWN_RATE
        rateChange: 0.004
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
