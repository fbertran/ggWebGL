(function(global) {
  "use strict";

  var interactions = global.ggWebGLInteractions || {};

  interactions.hoverKey = function(target) {
    if (!target) {
      return "none";
    }
    return [
      target.type || "unknown",
      target.panel_id === undefined ? "" : target.panel_id,
      target.layer_index === undefined ? "" : target.layer_index,
      target.index === undefined ? "" : target.index,
      target.id || ""
    ].join(":");
  };

  global.ggWebGLInteractions = interactions;
}(window));
