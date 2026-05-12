(function(global) {
  "use strict";

  function isArrayLike(value) {
    return Array.isArray(value) || ArrayBuffer.isView(value);
  }

  function decodeBase64ToUint8Array(data) {
    if (!data || typeof data !== "string") {
      return new Uint8Array(0);
    }
    var binary = global.atob(data);
    var out = new Uint8Array(binary.length);
    for (var i = 0; i < binary.length; i += 1) {
      out[i] = binary.charCodeAt(i) & 255;
    }
    return out;
  }

  function typedView(Ctor, data) {
    var bytes = decodeBase64ToUint8Array(data);
    if (!bytes.length) {
      return new Ctor(0);
    }
    var copied = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
    return new Ctor(copied);
  }

  function decodeFloat32(data) {
    return typedView(Float32Array, data);
  }

  function decodeUint16(data) {
    return typedView(Uint16Array, data);
  }

  function decodeUint32(data) {
    return typedView(Uint32Array, data);
  }

  function decodeUint8(data) {
    return decodeBase64ToUint8Array(data);
  }

  function rangePair(range, fallback) {
    if (!Array.isArray(range) || range.length < 2) {
      return fallback || [0, 1];
    }
    var lo = Number(range[0]);
    var hi = Number(range[1]);
    if (!isFinite(lo) || !isFinite(hi) || lo === hi) {
      return fallback || [0, 1];
    }
    return [lo, hi];
  }

  function splitInterleaved(values, rows, components) {
    var x = new Float32Array(rows);
    var y = new Float32Array(rows);
    var z = components === 3 ? new Float32Array(rows) : new Float32Array(0);
    for (var i = 0; i < rows; i += 1) {
      var offset = i * components;
      x[i] = Number(values[offset] || 0);
      y[i] = Number(values[offset + 1] || 0);
      if (components === 3) {
        z[i] = Number(values[offset + 2] || 0);
      }
    }
    return { x: x, y: y, z: z };
  }

  function decodePosition(position) {
    position = position && typeof position === "object" ? position : {};
    var rows = Math.max(0, Math.floor(Number(position.rows) || 0));
    var components = Math.max(2, Math.min(3, Math.floor(Number(position.components) || 2)));
    if (position.encoding === "uint16_base64") {
      var q = decodeUint16(position.data);
      var ranges = position.ranges || {};
      var xr = rangePair(ranges.x, [0, 1]);
      var yr = rangePair(ranges.y, [0, 1]);
      var zr = rangePair(ranges.z, [0, 1]);
      var x = new Float32Array(rows);
      var y = new Float32Array(rows);
      var z = components === 3 ? new Float32Array(rows) : new Float32Array(0);
      for (var i = 0; i < rows; i += 1) {
        var offset = i * components;
        x[i] = xr[0] + (xr[1] - xr[0]) * (Number(q[offset] || 0) / 65535);
        y[i] = yr[0] + (yr[1] - yr[0]) * (Number(q[offset + 1] || 0) / 65535);
        if (components === 3) {
          z[i] = zr[0] + (zr[1] - zr[0]) * (Number(q[offset + 2] || 0) / 65535);
        }
      }
      return { x: x, y: y, z: z };
    }
    return splitInterleaved(decodeFloat32(position.data), rows, components);
  }

  function decodeAttribute(attribute, rows, fallback) {
    attribute = attribute && typeof attribute === "object" ? attribute : {};
    if (attribute.encoding === "constant") {
      var constant = isFinite(Number(attribute.value)) ? Number(attribute.value) : fallback;
      var out = new Float32Array(rows);
      out.fill(constant);
      return out;
    }
    if (attribute.encoding === "float32_base64") {
      var values = decodeFloat32(attribute.data);
      if (values.length >= rows) {
        return values.slice(0, rows);
      }
    }
    var filled = new Float32Array(rows);
    filled.fill(fallback);
    return filled;
  }

  function decodeColor(color) {
    color = color && typeof color === "object" ? color : {};
    if (color.encoding === "palette_rgba_u8") {
      return {
        encoding: "palette_rgba_u8",
        palette: decodeUint8(color.palette),
        palette_size: Math.max(0, Math.floor(Number(color.palette_size) || 0)),
        index: color.index_encoding === "uint32_base64" ? decodeUint32(color.index) : decodeUint16(color.index)
      };
    }
    return {
      encoding: "rgba_u8",
      rgba: decodeUint8(color.data)
    };
  }

  function colorAt(color, index) {
    if (!color) {
      return [0, 0, 0, 1];
    }
    var offset;
    if (color.encoding === "palette_rgba_u8") {
      var paletteIndex = Number(color.index[index] || 0);
      offset = paletteIndex * 4;
      return [
        Number(color.palette[offset] || 0) / 255,
        Number(color.palette[offset + 1] || 0) / 255,
        Number(color.palette[offset + 2] || 0) / 255,
        Number(color.palette[offset + 3] === undefined ? 255 : color.palette[offset + 3]) / 255
      ];
    }
    offset = index * 4;
    return [
      Number(color.rgba[offset] || 0) / 255,
      Number(color.rgba[offset + 1] || 0) / 255,
      Number(color.rgba[offset + 2] || 0) / 255,
      Number(color.rgba[offset + 3] === undefined ? 255 : color.rgba[offset + 3]) / 255
    ];
  }

  function materializePointLayerCompact(compact) {
    compact = compact && typeof compact === "object" ? compact : null;
    if (!compact || !compact.position) {
      return null;
    }
    var rows = Math.max(0, Math.floor(Number(compact.rows) || Number(compact.position.rows) || 0));
    var position = decodePosition(compact.position);
    var attributes = compact.attributes || {};
    return {
      rows: rows,
      x: position.x,
      y: position.y,
      z: position.z,
      size: decodeAttribute(attributes.size, rows, 1),
      age: decodeAttribute(attributes.age, rows, 1),
      color: decodeColor(compact.color),
      decoded_bytes: Number(compact.decoded_bytes) || 0
    };
  }

  global.ggWebGLBuffers = {
    isArrayLike: isArrayLike,
    decodeBase64ToUint8Array: decodeBase64ToUint8Array,
    decodeFloat32: decodeFloat32,
    decodeUint16: decodeUint16,
    decodeUint32: decodeUint32,
    decodeUint8: decodeUint8,
    decodePosition: decodePosition,
    decodeAttribute: decodeAttribute,
    decodeColor: decodeColor,
    colorAt: colorAt,
    materializePointLayerCompact: materializePointLayerCompact
  };
}(window));
