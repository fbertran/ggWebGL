(function(global) {
  "use strict";

  var interactions = global.ggWebGLInteractions || {};

  interactions.brushPayload = function(payload) {
    payload = payload || {};
    payload.mode = payload.mode || "brush";
    return payload;
  };

  global.ggWebGLInteractions = interactions;
}(window));
