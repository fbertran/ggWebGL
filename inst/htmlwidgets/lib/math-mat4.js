(function(global) {
  "use strict";

  function identity() {
    return [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    ];
  }

  function multiply(a, b) {
    var out = new Array(16);
    for (var col = 0; col < 4; col += 1) {
      for (var row = 0; row < 4; row += 1) {
        out[col * 4 + row] =
          a[0 * 4 + row] * b[col * 4 + 0] +
          a[1 * 4 + row] * b[col * 4 + 1] +
          a[2 * 4 + row] * b[col * 4 + 2] +
          a[3 * 4 + row] * b[col * 4 + 3];
      }
    }
    return out;
  }

  function perspective(fovRadians, aspect, near, far) {
    var f = 1 / Math.tan(Math.max(1e-6, fovRadians) * 0.5);
    var nf = 1 / (near - far);
    return [
      f / Math.max(1e-6, aspect), 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far + near) * nf, -1,
      0, 0, (2 * far * near) * nf, 0
    ];
  }

  function orthographic(left, right, bottom, top, near, far) {
    var lr = 1 / (left - right);
    var bt = 1 / (bottom - top);
    var nf = 1 / (near - far);
    return [
      -2 * lr, 0, 0, 0,
      0, -2 * bt, 0, 0,
      0, 0, 2 * nf, 0,
      (left + right) * lr, (top + bottom) * bt, (far + near) * nf, 1
    ];
  }

  function normalize3(v, fallback) {
    var x = Number(v && v[0]);
    var y = Number(v && v[1]);
    var z = Number(v && v[2]);
    if (!isFinite(x) || !isFinite(y) || !isFinite(z)) {
      return fallback ? fallback.slice() : [0, 0, 0];
    }
    var len = Math.sqrt(x * x + y * y + z * z);
    if (!(len > 0)) {
      return fallback ? fallback.slice() : [0, 0, 0];
    }
    return [x / len, y / len, z / len];
  }

  function subtract3(a, b) {
    return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
  }

  function cross3(a, b) {
    return [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0]
    ];
  }

  function dot3(a, b) {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
  }

  function lookAt(eye, target, up) {
    var zAxis = normalize3(subtract3(eye, target), [0, 0, 1]);
    var xAxis = normalize3(cross3(up, zAxis), [1, 0, 0]);
    var yAxis = cross3(zAxis, xAxis);
    return [
      xAxis[0], yAxis[0], zAxis[0], 0,
      xAxis[1], yAxis[1], zAxis[1], 0,
      xAxis[2], yAxis[2], zAxis[2], 0,
      -dot3(xAxis, eye), -dot3(yAxis, eye), -dot3(zAxis, eye), 1
    ];
  }

  function transformPoint(m, p) {
    var x = Number(p && p[0]) || 0;
    var y = Number(p && p[1]) || 0;
    var z = Number(p && p[2]) || 0;
    var w = Number(p && p[3]);
    if (!isFinite(w)) {
      w = 1;
    }
    return [
      m[0] * x + m[4] * y + m[8] * z + m[12] * w,
      m[1] * x + m[5] * y + m[9] * z + m[13] * w,
      m[2] * x + m[6] * y + m[10] * z + m[14] * w,
      m[3] * x + m[7] * y + m[11] * z + m[15] * w
    ];
  }

  global.ggWebGLMat4 = {
    identity: identity,
    multiply: multiply,
    perspective: perspective,
    orthographic: orthographic,
    lookAt: lookAt,
    transformPoint: transformPoint,
    normalize3: normalize3,
    cross3: cross3,
    dot3: dot3
  };
}(window));
