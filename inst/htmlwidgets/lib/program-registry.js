(function(global) {
  "use strict";

  function getProgramForLayer(programs, layer) {
    if (!programs || !layer) {
      return null;
    }
    return layer.type === "raster" ? programs.raster : programs.primitive;
  }

  global.ggWebGLProgramRegistry = {
    getProgramForLayer: getProgramForLayer
  };
}(window));
