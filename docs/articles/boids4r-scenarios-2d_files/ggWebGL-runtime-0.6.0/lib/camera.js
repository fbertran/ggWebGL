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

  function rotateByQuaternion(point, quaternion) {
    var q = normalizeQuaternion(quaternion);
    var x = point[0], y = point[1], z = point[2];
    var qx = q[0], qy = q[1], qz = q[2], qw = q[3];
    var ix = qw * x + qy * z - qz * y;
    var iy = qw * y + qz * x - qx * z;
    var iz = qw * z + qx * y - qy * x;
    var iw = -qx * x - qy * y - qz * z;
    return [
      ix * qw + iw * -qx + iy * -qz - iz * -qy,
      iy * qw + iw * -qy + iz * -qx - ix * -qz,
      iz * qw + iw * -qz + ix * -qy - iy * -qx
    ];
  }

  function cameraMatrices(camera, projection, aspect) {
    var mat4 = global.ggWebGLMat4;
    var state = camera || {};
    var rotation = normalizeQuaternion(state.rotation);
    var distance = Math.max(0.1, Number(state.distance) || 2.8);
    var target = Array.isArray(state.target) ? state.target : [0, 0, 0];
    var up = Array.isArray(state.up) ? state.up : [0, 1, 0];
    var eyeOffset = rotateByQuaternion([0, 0, distance], rotation);
    var eye = [
      Number(target[0] || 0) + eyeOffset[0],
      Number(target[1] || 0) + eyeOffset[1],
      Number(target[2] || 0) + eyeOffset[2]
    ];
    var view = mat4.lookAt(eye, target, up);
    var fov = (Number(state.fov) || 45) * Math.PI / 180;
    var near = Math.max(1e-5, Number(state.near) || 0.01);
    var far = Math.max(near + 1e-5, Number(state.far) || 1000);
    var proj = projection === "perspective"
      ? mat4.perspective(fov, Math.max(1e-6, aspect || 1), near, far)
      : mat4.orthographic(-1.25 * Math.max(1, aspect || 1), 1.25 * Math.max(1, aspect || 1), -1.25, 1.25, near, far);
    return {
      model: mat4.identity(),
      view: view,
      projection: proj,
      viewProjection: mat4.multiply(proj, view),
      eye: eye,
      target: target.slice ? target.slice() : [0, 0, 0]
    };
  }

  global.ggWebGLCamera = {
    normalizeQuaternion: normalizeQuaternion,
    axisAngleQuaternion: axisAngleQuaternion,
    rotateByQuaternion: rotateByQuaternion,
    cameraMatrices: cameraMatrices
  };
}(window));
