define ['THREE'], (THREE) ->
  uniforms:
    map: {type: 't', value: null}
    time: {type: 'f', value: 0.0}
    resolution: {type: 'v2', value: new THREE.Vector2(100, 100)}
  shaders:
    vertexShader: [
      "void main() {",
          "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
      "}"
    ].join('\n')
    fragmentShader: [
      "uniform float time;",
      "uniform vec2 resolution;",
      "void main() {",
          "gl_FragColor = vec4(0.5,1.0,0,0.9);",
      "}"
    ].join('\n')
