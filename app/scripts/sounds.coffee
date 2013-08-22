define ['jsfxlib'], (jsfxlib) ->
  sounds =
    shoot: ["sine",0.0000,0.4000,0.0000,0.1600,0.2430,0.3600,110.0000,1263.0000,2400.0000,-0.7220,0.0000,0.0000,0.0100,0.0003,0.0000,0.0000,0.0000,0.3205,0.0060,0.0000,0.1880,0.0900,1.0000,0.0000,0.0000,0.0720,0.0000]
    explosion1: ["noise",1.0000,0.4000,0.0000,0.2160,0.2400,0.4200,20.0000,261.0000,2400.0000,-0.0380,0.0000,0.0000,0.0100,0.0003,0.0000,0.5680,0.8070,0.0000,0.0000,0.7432,-0.1000,-0.1380,1.0000,0.0000,0.0000,0.0000,0.0000]
    explosion2: ["noise",1.0000,0.4000,0.0000,0.9240,0.4950,0.2060,20.0000,284.0000,2400.0000,-0.2360,0.0000,0.0000,0.0100,0.0003,0.0000,0.2960,0.6300,0.0000,0.0000,0.0000,0.1780,-0.0500,1.0000,0.0000,0.0000,0.0000,0.0000]
    hit: ["saw",1.0000,0.4000,0.0000,0.0480,0.0000,0.1460,20.0000,705.0000,2400.0000,-0.4000,0.0000,0.0000,0.0100,0.0003,0.0000,0.0000,0.0000,0.0000,0.0000,0.0000,0.0000,0.0000,1.0000,0.0000,0.0000,0.1720,0.0000]

  samples = jsfxlib.createWaves(sounds)

  death: ->
    samples.explosion2.play()
    samples.hit.play()
  kill: ->
    samples.explosion1.play()
  hit: ->
    samples.hit.play()
  fire: ->
    samples.shoot.play()