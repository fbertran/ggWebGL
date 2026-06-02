(function(global) {
  "use strict";

  var interactions = global.ggWebGLInteractions || {};

  interactions.lassoPayload = function(payload) {
    payload = payload || {};
    payload.mode = payload.mode || "lasso";
    return payload;
  };

  global.ggWebGLInteractions = interactions;
}(window));
