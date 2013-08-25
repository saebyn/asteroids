define [], () ->
  class Keys
    keyMap:
      A: ['steer', 'left']
      D: ['steer', 'right']
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
