(function() {
  var Building, Chase, Elle, Entity, Key, Map,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Chase = (function() {

    function Chase(doc, win) {
      var _this = this;
      this.doc = doc;
      this.win = win;
      this.pause = __bind(this.pause, this);
      this.play = __bind(this.play, this);
      this.canvas = this.doc.getElementById("game_canvas");
      this.context = this.canvas.getContext("2d");
      this.buttons = {
        start: this.doc.getElementById("start"),
        pause: this.doc.getElementById("pause")
      };
      this.buttons.start.onclick = this.play;
      this.buttons.pause.onclick = this.pause;
      this.key = new Key;
      this.win.onkeyup = function(e) {
        return _this.key.onKeyUp(e);
      };
      this.win.onkeydown = function(e) {
        return _this.key.onKeyDown(e);
      };
      this.map = new Map(this.context, this.canvas);
      this.elle = new Elle(this.context, this.canvas, this.map, this.key);
    }

    Chase.prototype.resetCanvas = function() {
      return this.canvas.width = this.canvas.width;
    };

    Chase.prototype.drawFrame = function() {
      var elleBounds;
      this.resetCanvas();
      this.elle.move();
      elleBounds = this.elle.getBounds();
      this.map.drawBG(this.elle.x, this.elle.y, this.elle.drawY);
      this.map.drawBuildings(this.elle.y, this.elle.drawY, elleBounds.y2 - this.elle.drawY, elleBounds.y2);
      this.map.drawHorizon();
      this.elle.draw();
      return this.map.drawBuildings(this.elle.y, this.elle.drawY, elleBounds.y2 + this.elle.drawY, elleBounds.y2);
    };

    Chase.prototype.play = function() {
      var _this = this;
      if (this.frameInterval) return;
      return this.frameInterval = setInterval(function() {
        return _this.drawFrame();
      }, 20);
    };

    Chase.prototype.pause = function() {
      if (this.frameInterval) {
        clearInterval(this.frameInterval);
        return this.frameInterval = null;
      } else {
        return this.play();
      }
    };

    return Chase;

  })();

  Entity = (function() {

    function Entity(x, y, width, height) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }

    Entity.prototype.getBounds = function() {
      return {
        x1: this.x,
        y1: this.y,
        x2: this.x + this.width,
        y2: this.y + this.height
      };
    };

    Entity.prototype.collidesWith = function(entity) {
      var myBounds, theirBounds;
      myBounds = this.getBounds();
      theirBounds = entity.getBounds();
      if (myBounds.x1 <= theirBounds.x2 && myBounds.x2 >= theirBounds.x1 && myBounds.y1 <= their.y2 && myBounds.y2 >= their.y1) {
        return true;
      }
      return false;
    };

    return Entity;

  })();

  Building = (function(_super) {

    __extends(Building, _super);

    function Building() {
      Building.__super__.constructor.apply(this, arguments);
    }

    Building.prototype.sizeMult = 1;

    Building.prototype.effectiveWidth = function() {
      return this.width * this.sizeMult;
    };

    Building.prototype.effectiveHeight = function() {
      return this.height * this.sizeMult;
    };

    Building.prototype.getBounds = function() {
      return {
        x1: this.x,
        y1: this.y - this.effectiveHeight(),
        x2: this.x + this.effectiveWidth(),
        y2: this.y
      };
    };

    Building.prototype.draw = function(context, drawX, drawY) {
      context.fillStyle = 'rgba(0,0,0,.9)';
      return context.fillRect(drawX, drawY, this.effectiveWidth(), this.effectiveHeight() * -1);
    };

    return Building;

  })(Entity);

  Map = (function() {

    function Map(context, canvas) {
      this.context = context;
      this.canvas = canvas;
    }

    Map.prototype.furthestY = 0;

    Map.prototype.lineGap = 20;

    Map.prototype.horizon = 100;

    Map.prototype.buildings = {};

    Map.prototype.getHorizonY = function(y, drawY) {
      var distanceToHorizon;
      distanceToHorizon = drawY - this.horizon;
      return y - distanceToHorizon;
    };

    Map.prototype.addNewBuildings = function(y) {
      var randX;
      if (Math.random() < 0.01) {
        randX = Math.ceil(Math.random() * this.canvas.width);
        console.log("new building at " + randX + ", " + y);
        return this.buildings[y] = new Building(randX, y, 100, 30);
      }
    };

    Map.prototype.getCloseBuildings = function(y2, speed) {
      var point, _ref, _ref2, _results;
      _results = [];
      for (point = _ref = y2 - speed, _ref2 = y2 + speed; _ref <= _ref2 ? point <= _ref2 : point >= _ref2; _ref <= _ref2 ? point++ : point--) {
        if (this.buildings[point] != null) _results.push(this.buildings[point]);
      }
      return _results;
    };

    Map.prototype.drawBG = function(x, y, drawY) {
      var count, horizonY, line, offset, _ref, _ref2;
      offset = (y % this.lineGap) * -1;
      offset += this.horizon;
      count = 0;
      for (line = offset, _ref = this.canvas.height, _ref2 = this.lineGap; offset <= _ref ? line <= _ref : line >= _ref; line += _ref2) {
        this.context.beginPath();
        this.context.lineWidth = ++count;
        this.context.moveTo(0, line);
        this.context.lineTo(this.canvas.width, line);
        this.context.closePath();
        this.context.stroke();
      }
      if (this.furthestY > y) {
        this.furthestY = y;
        horizonY = this.getHorizonY(y, drawY);
        return this.addNewBuildings(horizonY);
      }
    };

    Map.prototype.drawHorizon = function() {
      this.context.fillStyle = "red";
      return this.context.fillRect(0, 0, this.canvas.width, this.horizon);
    };

    Map.prototype.drawBuildings = function(y, drawY, lower, upper) {
      var building, currentY, distance, distanceToHorizon, point, sizeMult, _results;
      _results = [];
      for (point = lower; lower <= upper ? point <= upper : point >= upper; lower <= upper ? point++ : point--) {
        if (this.buildings[point] != null) {
          building = this.buildings[point];
          distance = building.y - y;
          currentY = drawY + distance;
          distanceToHorizon = drawY - this.horizon + 15;
          if (distance < 0) {
            sizeMult = 1 - (1 / distanceToHorizon) * Math.abs(distance);
          } else {
            sizeMult = 1;
          }
          building.sizeMult = sizeMult;
          _results.push(building.draw(this.context, building.x, currentY));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return Map;

  })();

  Key = (function() {

    function Key() {
      this.onKeyUp = __bind(this.onKeyUp, this);
      this.onKeyDown = __bind(this.onKeyDown, this);
      this.isDown = __bind(this.isDown, this);
    }

    Key.prototype.pressed = {};

    Key.prototype.codes = {
      "LEFT": 37,
      "UP": 38,
      "RIGHT": 39,
      "DOWN": 40,
      "SPACE": 32
    };

    Key.prototype.isDown = function(keyCode) {
      return this.pressed[keyCode];
    };

    Key.prototype.onKeyDown = function(event) {
      return this.pressed[event.keyCode] = true;
    };

    Key.prototype.onKeyUp = function(event) {
      return delete this.pressed[event.keyCode];
    };

    return Key;

  })();

  Elle = (function(_super) {

    __extends(Elle, _super);

    function Elle(context, canvas, map, key) {
      this.context = context;
      this.canvas = canvas;
      this.map = map;
      this.key = key;
      this.x = (this.canvas.width - this.width) / 2;
      this.y = 0;
      this.drawY = (this.canvas.height + 50) / 2;
    }

    Elle.prototype.width = 16;

    Elle.prototype.height = 16;

    Elle.prototype.speed = 1;

    Elle.prototype.jump = {
      isJumping: false,
      goingUp: true,
      height: 0,
      maxHeight: 50,
      stepHeight: function() {
        if (this.height < this.maxHeight && this.goingUp) {
          return this.height = this.height + 2;
        } else if (this.height > 0) {
          this.height = this.height - 2;
          return this.goingUp = false;
        } else {
          this.height = 0;
          this.isJumping = false;
          return this.goingUp = true;
        }
      }
    };

    Elle.prototype.canMove = function(direction) {
      var bounds, building, closeBuildings, distance, myBounds, _i, _len;
      myBounds = this.getBounds();
      closeBuildings = this.map.getCloseBuildings(myBounds.y2, this.speed);
      for (_i = 0, _len = closeBuildings.length; _i < _len; _i++) {
        building = closeBuildings[_i];
        bounds = building.getBounds();
        distance = (myBounds.y2 - bounds.y2) * direction;
        if (distance <= this.speed && distance > 0 && myBounds.x1 < bounds.x2 && myBounds.x2 > bounds.x1 && myBounds.y2 - this.jump.height > bounds.y1) {
          return false;
        }
      }
      return true;
    };

    Elle.prototype.canMoveForward = function() {
      return this.canMove(1);
    };

    Elle.prototype.canMoveBack = function() {
      return this.canMove(-1);
    };

    Elle.prototype.move = function() {
      if (this.key.isDown(this.key.codes.LEFT) && this.x > 0) this.x = this.x - 1;
      if (this.key.isDown(this.key.codes.RIGHT) && this.x < this.canvas.width - this.width) {
        this.x = this.x + 1;
      }
      if (this.key.isDown(this.key.codes.UP) && this.canMoveForward()) {
        this.y = this.y - 1;
      }
      if (this.key.isDown(this.key.codes.DOWN) && this.canMoveBack()) {
        this.y = this.y + 1;
      }
      if (this.key.isDown(this.key.codes.SPACE) && !this.jump.isJumping) {
        return this.jump.isJumping = true;
      }
    };

    Elle.prototype.draw = function() {
      var bounds, position;
      if (this.jump.isJumping) {
        this.jump.stepHeight();
        this.context.fillStyle = "black";
        this.context.fillRect(this.x + 2, this.drawY, this.width - 4, this.height - 4);
      }
      position = this.drawY - this.jump.height;
      this.context.fillStyle = "orange";
      this.context.fillRect(this.x, position, this.width, this.height);
      bounds = this.getBounds();
      this.context.fillStyle = "black";
      this.context.font = "bold 12px sans-serif";
      this.context.textAlign = "left";
      this.context.textBaseline = "top";
      return this.context.fillText('(' + bounds.x2 + ',' + bounds.y1 + ')', 610, 22);
    };

    return Elle;

  })(Entity);

  window.onload = function() {
    var chase;
    chase = new Chase(window.document, window);
    chase.drawFrame();
    return chase.play();
  };

}).call(this);
