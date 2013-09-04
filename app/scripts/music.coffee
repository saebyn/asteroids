define [], ->
  HAVE_ENOUGH_DATA = 4

  checkTime = 5000  # 5 seconds

  playIfCan = (assetManager) ->
    next = ->
      tracks = assetManager.getTracks()
      if tracks.length > 0
        # if no tracks are playing
        if _.every(tracks, (track) ->
          track.ended or track.paused)
          # pick a random track and play it
          track = tracks[(Math.random() * tracks.length) | 0]
          track.currentTime = 0
          track.play()

      # set timeout
      setTimeout(next, checkTime)

    next()

  start: playIfCan
