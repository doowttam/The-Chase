class Chase
  constructor: (@doc, @win) ->
    @canvas  = @doc.getElementById("game_canvas")
    @context = @canvas.getContext("2d")
    @buttons =
      start: @doc.getElementById("start")
      pause: @doc.getElementById("pause")

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

  drawFrame: ->
    console.info('drawing frame')

  play: =>
    return if @frameInterval
    console.info 'playing!!!!'
    @frameInterval =
      setInterval =>
        @drawFrame()
      , 20

  pause: =>
    if @frameInterval
      console.info "pausing"
      clearInterval @frameInterval
      @frameInterval = null
    else
      @play()

window.onload = ->
  chase = new Chase(window.document, window)

