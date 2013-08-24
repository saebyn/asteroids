define ['THREE'], (THREE) ->
  randomSphereCoord = ->
    u = Math.random()
    v = Math.random()
    # according to http://mathworld.wolfram.com/SpherePointPicking.html
    theta = 2.0 * Math.PI * u
    phi = Math.acos(2.0 * v - 1)
    [theta, phi]
  randomVectorOnSphere = (radius) ->
    # get random rotations around sphere
    [theta, phi] = randomSphereCoord()

    x = radius * Math.cos(theta) * Math.sin(phi)
    y = radius * Math.sin(theta) * Math.sin(phi)
    z = radius * Math.cos(phi)
    new THREE.Vector3(x, y, z)

  # From http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning
  clone = (obj) ->
    if not obj? or typeof obj isnt 'object'
      return obj

    if obj instanceof Date
      return new Date(obj.getTime()) 

    if obj instanceof RegExp
      flags = ''
      flags += 'g' if obj.global?
      flags += 'i' if obj.ignoreCase?
      flags += 'm' if obj.multiline?
      flags += 'y' if obj.sticky?
      return new RegExp(obj.source, flags) 

    newInstance = new obj.constructor()

    for key of obj
      newInstance[key] = clone obj[key]

    return newInstance

  clone: clone
  randomVectorOnSphere: randomVectorOnSphere
  randomVectorInSphere: (radius) ->
    randomVectorOnSphere(Math.random() * radius)
