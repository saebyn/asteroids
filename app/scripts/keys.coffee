define [], () ->
  class Keys
    keyMap:
      W: ['steer', 'down']
      A: ['steer', 'left']
      S: ['steer', 'up']
      D: ['steer', 'right']
      Q: ['steer', 'tiltLeft']
      E: ['steer', 'tiltRight']
      ' ': ['fire']
      O: ['fullscreen']
      P: ['pause']

    constructor: (app) ->
      document.addEventListener 'keydown', (event) =>
        key = String.fromCharCode(event.keyCode)
        if key of @keyMap
          app.emit('controls:start', @keyMap[key]...)

      document.addEventListener 'keyup', (event) =>
        key = String.fromCharCode(event.keyCode)
        if key of @keyMap
          app.emit('controls:stop', @keyMap[key]...)
