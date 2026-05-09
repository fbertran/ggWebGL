(function(global) {
  "use strict";

  function getProgramForLayer(programs, layer, material, scene) {
    if (!programs || !layer) {
      return null;
    }
    if (layer.type === "raster") {
      return programs.raster;
    }
    if (layer.type === "surface") {
      return programs.surface;
    }
    if (scene && scene.render &&
        (scene.render.dimension === "3d" || scene.render.coordinate_system === "cartesian3d")) {
      return programs.primitive3d || programs.primitive;
    }
    return programs.primitive;
  }

  global.ggWebGLProgramRegistry = {
    getProgramForLayer: getProgramForLayer
  };
}(window));
