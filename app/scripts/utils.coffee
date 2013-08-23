define ['THREE'], (THREE) ->
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
  randomVectorOnSphere: (radius) ->
    # get random rotations around sphere
    x = Math.random() * Math.PI * 2.0 - Math.PI
    y = Math.random() * Math.PI * 2.0 - Math.PI

    px = radius * Math.cos(x) * Math.sin(y)
    py = radius * Math.sin(x) * Math.sin(y)
    pz = radius * Math.cos(y)
    new THREE.Vector3(px, py, pz)
  randomVectorInSphere: (radius) ->
    r = Math.random() * radius
    theta = Math.random() * Math.PI * 2.0
    phi = Math.random() * Math.PI * 2.0
    x = r * Math.sin(theta) * Math.cos(phi)
    y = r * Math.sin(theta) * Math.sin(phi)
    z = r * Math.cos(theta)
    new THREE.Vector3(x, y, z)
