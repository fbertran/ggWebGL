(function(global) {
  "use strict";

  function decorateSelectionPayload(payload) {
    return payload || {};
  }

  global.ggWebGLPicking = {
    decorateSelectionPayload: decorateSelectionPayload
  };
}(window));
