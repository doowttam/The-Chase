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
    elleBounds = @elle.getBounds()

    # draw map
    @map.drawBG @elle.x, @elle.y, @elle.drawY

    # draw building ahead
    # FIXME: drawY isn't really right, it's more like distance to horizon for one
    # and distance to bottom for the other, but it's a safe approximation
    @map.drawBuildings @elle.y, @elle.drawY, elleBounds.y2 - @elle.drawY, elleBounds.y2

    @map.drawHorizon()

    # draw elle
    @elle.draw()

    # draw buildings behind
    @map.drawBuildings @elle.y, @elle.drawY, elleBounds.y2 + @elle.drawY, elleBounds.y2

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
  #  x1, y2 ---- x2, y2

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

  buildings: {}

  getHorizonY: (y, drawY) ->
    distanceToHorizon = drawY - @horizon
    return y - distanceToHorizon

  addNewBuildings: (y)->
    if Math.random() < 0.01
      randX = Math.ceil Math.random() * @canvas.width
      console.log "new building at #{randX}, #{y}"
      @buildings[y] = new Building randX, y, 100, 30

  getCloseBuildings: (y2, speed) ->
    @buildings[point] for point in [ y2 - speed .. y2 + speed] when @buildings[point]?

  drawBG: (x, y, drawY) ->
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

  drawHorizon: ->
    @context.fillStyle = "red"
    @context.fillRect 0, 0, @canvas.width, @horizon

  drawBuildings: (y, drawY, lower, upper) ->
    for point in [ lower .. upper ]
      if @buildings[point]?
        building = @buildings[point]
        distance = building.y - y
        currentY = drawY + distance

        # Lie a little bit, it's slightly past the horizon
        distanceToHorizon = drawY - @horizon + 15
        if distance < 0
          sizeMult = 1 - ( 1 / distanceToHorizon ) * Math.abs(distance)
        else
          sizeMult = 1

        # Update size multiplier
        building.sizeMult = sizeMult
        building.draw @context, building.x, currentY


# Inspired by http://nokarma.org/2011/02/27/javascript-game-development-keyboard-input/index.html
class Key
  pressed: {}

  codes:
    "LEFT": 37
    "UP": 38
    "RIGHT": 39
    "DOWN": 40
    "SPACE": 32

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
    @drawY = (@canvas.height + 50 ) / 2

  width: 16
  height: 16
  speed: 1

  jump:
    isJumping: false
    goingUp: true
    height: 0
    maxHeight: 50
    stepHeight: ->
      if @height < @maxHeight && @goingUp
        @height = @height + 2
      else if @height > 0
        @height = @height - 2
        @goingUp = false
      else
        @height = 0
        @isJumping = false
        @goingUp   = true

  canMoveForward: ->
    myBounds = @getBounds()
    closeBuildings = @map.getCloseBuildings myBounds.y2, @speed
    for building in closeBuildings
      bounds   = building.getBounds()
      distance = myBounds.y2 - bounds.y2
      if distance <= @speed and
         distance > 0 and
         myBounds.x1 < bounds.x2 and
         myBounds.x2 > bounds.x1 and
         myBounds.y2 - @jump.height > bounds.y1
        return false
    return true

  canMoveBack: ->
    myBounds = @getBounds()
    closeBuildings = @map.getCloseBuildings myBounds.y2, @speed
    for building in closeBuildings
      bounds   = building.getBounds()
      distance = bounds.y2 - myBounds.y2
      if distance <= @speed and
         distance > 0 and
         myBounds.x1 < bounds.x2 and
         myBounds.x2 > bounds.x1 and
         myBounds.y2 - @jump.height > bounds.y1
        return false
    return true

  move: ->
    if @key.isDown(@key.codes.LEFT) and @x > 0
      @x = @x - 1
    if @key.isDown(@key.codes.RIGHT) and @x < @canvas.width - @width
      @x = @x + 1
    if @key.isDown(@key.codes.UP) && @canMoveForward()
      @y = @y - 1
    if @key.isDown(@key.codes.DOWN) && @canMoveBack()
      @y = @y + 1
    if @key.isDown(@key.codes.SPACE) && !@jump.isJumping
      @jump.isJumping = true

  draw: ->
    if @jump.isJumping
      @jump.stepHeight()
      @context.fillStyle = "black"
      @context.fillRect @x + 2, @drawY, @width - 4, @height - 4

    position = @drawY - @jump.height

    @context.fillStyle = "orange"
    @context.fillRect @x, position, @width, @height

    bounds = @getBounds()
    @context.fillStyle = "black"
    @context.font = "bold 12px sans-serif"
    @context.textAlign = "left"
    @context.textBaseline = "top"
    @context.fillText '(' + bounds.x2 + ',' + bounds.y1 + ')', 610, 22

window.onload = ->
  chase = new Chase window.document, window
  chase.drawFrame()
  chase.play()

