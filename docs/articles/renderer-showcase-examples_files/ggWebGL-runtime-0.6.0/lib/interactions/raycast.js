(function(global) {
  "use strict";

  var interactions = global.ggWebGLInteractions || {};

  interactions.pointInTriangle = function(px, py, a, b, c) {
    var v0x = c.x - a.x;
    var v0y = c.y - a.y;
    var v1x = b.x - a.x;
    var v1y = b.y - a.y;
    var v2x = px - a.x;
    var v2y = py - a.y;
    var dot00 = v0x * v0x + v0y * v0y;
    var dot01 = v0x * v1x + v0y * v1y;
    var dot02 = v0x * v2x + v0y * v2y;
    var dot11 = v1x * v1x + v1y * v1y;
    var dot12 = v1x * v2x + v1y * v2y;
    var denom = dot00 * dot11 - dot01 * dot01;
    if (Math.abs(denom) < 1e-9) {
      return false;
    }
    var inv = 1 / denom;
    var u = (dot11 * dot02 - dot01 * dot12) * inv;
    var v = (dot00 * dot12 - dot01 * dot02) * inv;
    return u >= -0.001 && v >= -0.001 && (u + v) <= 1.001;
  };

  global.ggWebGLInteractions = interactions;
}(window));
