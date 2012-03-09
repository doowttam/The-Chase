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

  getHorizonY: (y) ->
    distanceToHorizon = @canvas.height / 2 - @horizon
    return y - distanceToHorizon

  addNewBuildings: (y)->
    if Math.random() < 0.01
      randX = Math.ceil Math.random() * @canvas.width
      console.log "new building at #{randX}, #{y}"
      @buildings.push new Building randX, y, 100, 30

  draw: (x, y) ->
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
      horizonY = @getHorizonY y
      @addNewBuildings horizonY

    for building in @buildings
      distance = building.y - y

      if  Math.abs(distance - @horizon) <= ( @canvas.height / 2 ) + building.height
        currentY = ( @canvas.height / 2 ) + distance

        if distance > -@horizon
          sizeMult = (distance + @horizon) / 200
        else
          sizeMult = 0

        # Update size multiplier
        building.sizeMult = sizeMult

        building.draw @context, building.x, currentY

    @context.fillStyle = "red"
    @context.fillRect 0, 0, @canvas.width, @horizon

  canMoveUp: (topLeftX, topRightX, y) ->
    for building in @buildings
      distance = building.y - y

      # if building's y is within 1 building's height
      if  Math.abs(distance) <= building.height
        if topLeftX >= building.x and topLeftX <= building.x + building.effectiveWidth()
          if y  >= building.y - building.height and y <= building.y
            return false
        if topRightX >= building.x and topRightX <= building.x + building.effectiveWidth()
          if y >= building.y - building.height and y <= building.y
            return false

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

class Elle
  constructor: (@context, @canvas, @map, @key) ->
    @x = ( @canvas.width - @size ) / 2
    @y = 0

  size: 16

  move: ->
    topLeftX = ( @canvas.width - @size ) / 2;
    topLeftY = ( @canvas.height - @size ) / 2;

    if @key.isDown(@key.codes.LEFT) and @x > 0
      @x = @x - 1
    if @key.isDown(@key.codes.RIGHT) and @x < @canvas.width - @size
      @x = @x + 1
    if @key.isDown(@key.codes.UP) and @map.canMoveUp(@x, @x + @size, @y - (@size / 2))
      @y = @y - 1
    if @key.isDown(@key.codes.DOWN)
      @y = @y + 1

  draw: ->
    @map.draw @x, @y
    @context.fillStyle = "orange"
    @context.fillRect @x, ( @canvas.height - @size ) / 2, @size, @size

window.onload = ->
  chase = new Chase window.document, window
  chase.drawFrame()
  chase.play()

