(function(global) {
  "use strict";

  function hasPointLod(layer) {
    return !!(layer && layer.lod && layer.lod.strategy === "grid" && layer.lod.rows > 0);
  }

  function pointLodLayer(layer) {
    if (!hasPointLod(layer)) {
      return null;
    }
    var lod = layer.lod;
    return {
      type: "points",
      geom: layer.geom || "lod_points",
      rows: Number(lod.rows) || 0,
      x: Array.isArray(lod.x) ? lod.x.map(Number) : [],
      y: Array.isArray(lod.y) ? lod.y.map(Number) : [],
      z: Array.isArray(lod.z) ? lod.z.map(Number) : [],
      size: Array.isArray(lod.size) ? lod.size.map(Number) : [],
      age: Array.isArray(lod.age) ? lod.age.map(Number) : [],
      rgba: Array.isArray(lod.rgba) ? lod.rgba.map(Number) : []
    };
  }

  function transportStatus(layer, uploaded) {
    var rows = Number(layer && layer.rows) || 0;
    uploaded = Math.max(0, Math.min(rows, Number(uploaded) || 0));
    return {
      rows: rows,
      uploaded: uploaded,
      complete: rows === 0 || uploaded >= rows
    };
  }

  global.ggWebGLLod = {
    hasPointLod: hasPointLod,
    pointLodLayer: pointLodLayer,
    transportStatus: transportStatus
  };
}(window));
