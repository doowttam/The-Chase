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

class Entity
  #  x1, y1 ---- x2, y1
  #  |
  #  |
  #  x2, y1 ---- x2, y2

  constructor: ( @x, @y, @width, @height ) ->

  getBounds: ->
    x1: @x
    y1: @y
    x2: @x + @width
    y2: @y + @height

  collidesWith: (entity) ->
    myBounds    = @getBounds()
    theirBounds = entity.getBounds()

    if ( myBounds.x1 <= theirBounds.x2 and
         myBounds.x2 >= theirBounds.x1 and
         myBounds.y1 <= their.y2 and
         myBounds.y2 >= their.y1 )
      return true
    return false

class Building extends Entity
  sizeMult: 1

  effectiveWidth: -> @width * @sizeMult
  effectiveHeight: -> @height * @sizeMult

  # Bounds are kind of confusing here since we anchor the building at its bottom left
  getBounds: ->
    x1: @x
    y1: @y - @effectiveHeight()
    x2: @x + @effectiveWidth()
    y2: @y

  draw: (context, drawX, drawY) ->
    # draw a negative height, so it draws upwards
    context.fillStyle = "black"
    context.fillRect drawX, drawY, @effectiveWidth(), @effectiveHeight() * -1

class Map
  constructor: (@context, @canvas) ->

  furthestY: 0
  lineGap: 20
  horizon: 100

  buildings: []

  getHorizonY: (y, drawY) ->
    distanceToHorizon = drawY - @horizon
    return y - distanceToHorizon

  addNewBuildings: (y)->
    if Math.random() < 0.01
      randX = Math.ceil Math.random() * @canvas.width
      console.log "new building at #{randX}, #{y}"
      @buildings.push new Building randX, y, 100, 30

  draw: (x, y, drawY) ->
    offset = (y % @lineGap) * -1

    offset += @horizon

    count = 0
    for line in [offset..@canvas.height] by @lineGap
      @context.beginPath()
      @context.lineWidth = ++count
      @context.moveTo(0, line)
      @context.lineTo(@canvas.width, line)
      @context.closePath()
      @context.stroke()

    # we're moving ahead
    if @furthestY > y
      @furthestY = y
      horizonY = @getHorizonY y, drawY
      @addNewBuildings horizonY

    for building in @buildings
      distance = building.y - y

      if  Math.abs(distance - @horizon) <= ( drawY ) + building.height
        currentY = ( drawY ) + distance

        # Lie a little bit, it's slightly past the horizon
        distanceToHorizon = drawY - @horizon + 15
        if distance < 0
          sizeMult = 1 - ( 1 / distanceToHorizon ) * Math.abs(distance)
        else
          sizeMult = 1

        # Update size multiplier
        building.sizeMult = sizeMult

        building.draw @context, building.x, currentY

    @context.fillStyle = "red"
    @context.fillRect 0, 0, @canvas.width, @horizon

    return true

# Inspired by http://nokarma.org/2011/02/27/javascript-game-development-keyboard-input/index.html
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

class Elle extends Entity
  constructor: (@context, @canvas, @map, @key) ->
    @x = ( @canvas.width - @width ) / 2
    @y = 0
    @drawY = (@canvas.height - @height ) / 2

  width: 16
  height: 16

  move: ->
    if @key.isDown(@key.codes.LEFT) and @x > 0
      @x = @x - 1
    if @key.isDown(@key.codes.RIGHT) and @x < @canvas.width - @width
      @x = @x + 1
    if @key.isDown(@key.codes.UP)
      @y = @y - 1
    if @key.isDown(@key.codes.DOWN)
      @y = @y + 1

  draw: ->
    @map.draw @x, @y, @drawY
    @context.fillStyle = "orange"
    @context.fillRect @x, @drawY, @width, @height

window.onload = ->
  chase = new Chase window.document, window
  chase.drawFrame()
  chase.play()

