class Chase
  constructor: (@doc, @win) ->
    @canvas  = @doc.getElementById("game_canvas")
    @context = @canvas.getContext("2d")
    @buttons =
      start: @doc.getElementById("start")
      pause: @doc.getElementById("pause")

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

    @key = new Key
    @win.onkeyup = (e) =>
      @key.onKeyUp e
    @win.onkeydown = (e) =>
      @key.onKeyDown e

    @map  = new Map @context, @canvas
    @elle = new Elle @context, @canvas, @map, @key

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: ->
    @resetCanvas()

    @elle.move()
    @elle.draw()

  play: =>
    return if @frameInterval
    @frameInterval =
      setInterval =>
        @drawFrame()
      , 20

  pause: =>
    if @frameInterval
      clearInterval @frameInterval
      @frameInterval = null
    else
      @play()

class Map
  constructor: (@context, @canvas) ->

  lineGap: 20

  draw: (x, y) ->
    offset = (y % @lineGap) * -1
    for line in [offset..@canvas.height] by @lineGap
      @context.moveTo(0, line)
      @context.lineTo(@canvas.width, line)
    @context.stroke()

# Pulled from http://nokarma.org/2011/02/27/javascript-game-development-keyboard-input/index.html
class Key
  pressed: {}

  codes:
    "LEFT": 37
    "UP": 38
    "RIGHT": 39
    "DOWN": 40

  isDown: (keyCode) =>
    return @pressed[keyCode]

  onKeyDown: (event) =>
    @pressed[event.keyCode] = true

  onKeyUp: (event) =>
    delete @pressed[event.keyCode]

class Elle
  constructor: (@context, @canvas, @map, @key) ->
    @x = ( @canvas.width - @size ) / 2
    @y = 0

  size: 16

  move: ->
    topLeftX = ( @canvas.width - @size ) / 2;
    topLeftY = ( @canvas.height - @size ) / 2;

    if @key.isDown @key.codes.LEFT
      if @x > 0
        @x = @x - 1
    if @key.isDown @key.codes.RIGHT
      if @x < @canvas.width
        @x = @x + 1
    if @key.isDown @key.codes.UP
      @y = @y - 1
    if @key.isDown @key.codes.DOWN
      @y = @y + 1

  draw: ->
    @map.draw @x, @y
    @context.fillRect @x, ( @canvas.height - @size ) / 2, @size, @size


window.onload = ->
  chase = new Chase window.document, window

