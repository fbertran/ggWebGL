(function(global) {
  "use strict";

  function normalizeQuaternion(values) {
    values = Array.isArray(values) ? values : [0, 0, 0, 1];
    var x = Number(values[0]) || 0;
    var y = Number(values[1]) || 0;
    var z = Number(values[2]) || 0;
    var w = Number(values[3]);
    if (!isFinite(w)) {
      w = 1;
    }
    var norm = Math.sqrt(x * x + y * y + z * z + w * w);
    if (!(norm > 0)) {
      return [0, 0, 0, 1];
    }
    return [x / norm, y / norm, z / norm, w / norm];
  }

  function axisAngleQuaternion(axis, angle) {
    var len = Math.sqrt(axis[0] * axis[0] + axis[1] * axis[1] + axis[2] * axis[2]);
    if (!(len > 0) || !isFinite(angle)) {
      return [0, 0, 0, 1];
    }
    var half = angle * 0.5;
    var s = Math.sin(half) / len;
    return normalizeQuaternion([axis[0] * s, axis[1] * s, axis[2] * s, Math.cos(half)]);
  }

  global.ggWebGLCamera = {
    normalizeQuaternion: normalizeQuaternion,
    axisAngleQuaternion: axisAngleQuaternion
  };
}(window));
