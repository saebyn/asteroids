define [], ->
  trackSources = [
    'resources/music/allofus.mp3',
    'resources/music/arpanauts.mp3',
    'resources/music/comeandfindme.mp3',
    'resources/music/digitalnative.mp3',
    'resources/music/hhavok-intro.mp3',
    'resources/music/hhavok-main.mp3',
    'resources/music/searching.mp3',
    'resources/music/underclocked.mp3',
    'resources/music/wereallunderthestars.mp3',
    'resources/music/weretheresistors.mp3',
  ]

  HAVE_ENOUGH_DATA = 4

  tracks = (new Audio(source) for source in trackSources)
  checkTime = 5000  # 5 seconds

  playIfCan = ->
    # if no tracks are playing
    if _.every(tracks, (track) ->
      track.ended or track.paused)
      # pick a random track and play it
      track = tracks[(Math.random() * tracks.length) | 0]
      if track.readyState == HAVE_ENOUGH_DATA
        track.currentTime = 0
        track.play()

    # set timeout
    setTimeout(playIfCan, checkTime)

  start: playIfCan
