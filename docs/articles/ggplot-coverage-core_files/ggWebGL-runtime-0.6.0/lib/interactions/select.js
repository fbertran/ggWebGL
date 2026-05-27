(function(global) {
  "use strict";

  var interactions = global.ggWebGLInteractions || {};

  interactions.pickPayload = function(target, reason) {
    if (!target) {
      return null;
    }
    var payload = {};
    Object.keys(target).forEach(function(key) {
      var value = target[key];
      if (value !== undefined && typeof value !== "function") {
        payload[key] = value;
      }
    });
    payload.reason = reason || "click";
    return payload;
  };

  global.ggWebGLInteractions = interactions;
}(window));
