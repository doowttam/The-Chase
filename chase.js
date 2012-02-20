(function() {
  var Building, Chase, Elle, Key, Map,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

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
      this.resetCanvas();
      this.elle.move();
      return this.elle.draw();
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

  Building = (function() {

    function Building(x, y, width, height) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }

    Building.prototype.draw = function(context, drawX, drawY, sizeMult) {
      var h, w;
      w = this.width * sizeMult;
      h = this.height * sizeMult * -1;
      context.fillStyle = "black";
      return context.fillRect(drawX, drawY, w, h);
    };

    return Building;

  })();

  Map = (function() {

    function Map(context, canvas) {
      this.context = context;
      this.canvas = canvas;
    }

    Map.prototype.furthestY = 0;

    Map.prototype.lineGap = 20;

    Map.prototype.horizon = 100;

    Map.prototype.buildings = [];

    Map.prototype.getHorizonY = function(y) {
      var distanceToHorizon;
      distanceToHorizon = this.canvas.height / 2 - this.horizon;
      return y - distanceToHorizon;
    };

    Map.prototype.addNewBuildings = function(y) {
      var randX;
      if (Math.random() < 0.01) {
        randX = Math.ceil(Math.random() * this.canvas.width);
        console.info("new building at " + randX + ", " + y);
        return this.buildings.push(new Building(randX, y, 100, 30));
      }
    };

    Map.prototype.draw = function(x, y) {
      var building, count, currentY, distance, horizonY, line, offset, sizeMult, _i, _len, _ref, _ref2, _ref3;
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
        horizonY = this.getHorizonY(y);
        this.addNewBuildings(horizonY);
      }
      _ref3 = this.buildings;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        building = _ref3[_i];
        distance = building.y - y;
        if (Math.abs(distance - this.horizon) <= (this.canvas.height / 2) + building.height) {
          currentY = (this.canvas.height / 2) + distance;
          if (distance > -this.horizon) {
            sizeMult = (distance + this.horizon) / 200;
          } else {
            sizeMult = 0;
          }
          building.draw(this.context, building.x, currentY, sizeMult);
        }
      }
      this.context.fillStyle = "red";
      return this.context.fillRect(0, 0, this.canvas.width, this.horizon);
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
      "DOWN": 40
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

  Elle = (function() {

    function Elle(context, canvas, map, key) {
      this.context = context;
      this.canvas = canvas;
      this.map = map;
      this.key = key;
      this.x = (this.canvas.width - this.size) / 2;
      this.y = 0;
    }

    Elle.prototype.size = 16;

    Elle.prototype.move = function() {
      var topLeftX, topLeftY;
      topLeftX = (this.canvas.width - this.size) / 2;
      topLeftY = (this.canvas.height - this.size) / 2;
      if (this.key.isDown(this.key.codes.LEFT) && this.x > 0) this.x = this.x - 1;
      if (this.key.isDown(this.key.codes.RIGHT) && this.x < this.canvas.width - this.size) {
        this.x = this.x + 1;
      }
      if (this.key.isDown(this.key.codes.UP)) this.y = this.y - 1;
      if (this.key.isDown(this.key.codes.DOWN)) return this.y = this.y + 1;
    };

    Elle.prototype.draw = function() {
      this.map.draw(this.x, this.y);
      this.context.fillStyle = "orange";
      return this.context.fillRect(this.x, (this.canvas.height - this.size) / 2, this.size, this.size);
    };

    return Elle;

  })();

  window.onload = function() {
    var chase;
    chase = new Chase(window.document, window);
    chase.drawFrame();
    return chase.play();
  };

}).call(this);
