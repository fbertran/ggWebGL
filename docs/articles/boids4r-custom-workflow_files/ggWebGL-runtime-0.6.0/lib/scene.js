(function(global) {
  "use strict";

  var Scene = {};
  Scene.VERSION = 2;

  function coordinateSystemForDimension(dimension) {
    return String(dimension || "2d").toLowerCase() === "3d"
      ? "cartesian3d"
      : "cartesian2d";
  }

  function normalizeMessages(messages) {
    if (Array.isArray(messages)) {
      return messages.map(String).filter(function(value) { return value.length > 0; });
    }
    if (typeof messages === "string" && messages.length) {
      return [messages];
    }
    return [];
  }

  Scene.validateScene = function(scene) {
    if (!scene || typeof scene !== "object") {
      throw new Error("ggWebGL scene payload must be an object.");
    }
    if (!scene.render || typeof scene.render !== "object") {
      throw new Error("ggWebGL scene payload must include a render object.");
    }
    if (!Array.isArray(scene.render.panels)) {
      throw new Error("ggWebGL scene render object must include panel list.");
    }
    return scene;
  };

  Scene.finalizeScene = function(scene) {
    scene = Scene.validateScene(scene);
    scene.scene_version = Number(scene.scene_version) || Scene.VERSION;
    scene.render.dimension = String(scene.render.dimension || (scene.webgl && scene.webgl.dimension) || "2d").toLowerCase() === "3d"
      ? "3d"
      : "2d";
    scene.render.coordinate_system = scene.render.coordinate_system || coordinateSystemForDimension(scene.render.dimension);
    scene.render.messages = normalizeMessages(scene.render.messages);

    if (scene.render.panels.length === 1) {
      scene.render.panel = scene.render.panels[0].panel_id;
      scene.render.viewport = scene.render.panels[0].viewport;
      scene.render.layers = scene.render.panels[0].layers;
    }

    return scene;
  };

  Scene.coordinateSystemForDimension = coordinateSystemForDimension;
  global.ggWebGLScene = Scene;
}(window));
