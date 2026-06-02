(function(global) {
  "use strict";

  function entry(family, name, program, mode, vertex, fragment, attributes, uniforms, fallback, layerTypes) {
    return {
      family: family,
      material_type: family,
      shader: name,
      program: program,
      mode: mode,
      vertex: vertex,
      fragment: fragment,
      attributes: attributes || [],
      uniforms: uniforms || [],
      fallback: fallback || null,
      layerTypes: layerTypes || []
    };
  }

  var commonPrimitiveAttributes = ["a_position", "a_size", "a_color", "a_age", "a_metric"];
  var commonPrimitiveUniforms = [
    "u_domain",
    "u_view_projection",
    "u_shader_mode",
    "u_is_point_layer",
    "u_point_scale",
    "u_min_point_size",
    "u_density_alpha_boost",
    "u_density_alpha_ceiling"
  ];

  var registry = {
    points: {
      default: entry(
        "points",
        "default",
        "primitive",
        0,
        "points/default.vert.glsl",
        "points/default.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        null,
        ["points"]
      ),
      density_splat: entry(
        "points",
        "density_splat",
        "primitive",
        1,
        "points/density_splat.vert.glsl",
        "points/density_splat.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "default",
        ["points"]
      ),
      uncertainty_alpha: entry(
        "points",
        "uncertainty_alpha",
        "primitive",
        6,
        "points/uncertainty_alpha.vert.glsl",
        "points/uncertainty_alpha.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "default",
        ["points"]
      ),
      point_sprite_glow: entry(
        "points",
        "point_sprite_glow",
        "primitive",
        7,
        "points/point_sprite_glow.vert.glsl",
        "points/point_sprite_glow.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "default",
        ["points"]
      )
    },
    lines: {
      default: entry(
        "lines",
        "default",
        "primitive",
        0,
        "lines/default.vert.glsl",
        "lines/default.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        null,
        ["lines"]
      ),
      trajectory_age: entry(
        "lines",
        "trajectory_age",
        "primitive",
        2,
        "lines/trajectory_age.vert.glsl",
        "lines/trajectory_age.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "default",
        ["lines"]
      ),
      trajectory_age_glow: entry(
        "lines",
        "trajectory_age_glow",
        "primitive",
        3,
        "lines/trajectory_age_glow.vert.glsl",
        "lines/trajectory_age_glow.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "trajectory_age",
        ["lines"]
      ),
      trajectory_velocity: entry(
        "lines",
        "trajectory_velocity",
        "primitive",
        4,
        "lines/trajectory_velocity.vert.glsl",
        "lines/trajectory_velocity.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "trajectory_age",
        ["lines"]
      ),
      trajectory_direction: entry(
        "lines",
        "trajectory_direction",
        "primitive",
        5,
        "lines/trajectory_direction.vert.glsl",
        "lines/trajectory_direction.frag.glsl",
        commonPrimitiveAttributes,
        commonPrimitiveUniforms,
        "trajectory_age",
        ["lines"]
      )
    },
    raster: {
      raster_texture: entry(
        "raster",
        "raster_texture",
        "raster",
        0,
        "raster/raster_texture.vert.glsl",
        "raster/raster_texture.frag.glsl",
        ["a_position", "a_texcoord"],
        ["u_domain", "u_texture", "u_shader_mode"],
        null,
        ["raster"]
      ),
      raster_threshold: entry(
        "raster",
        "raster_threshold",
        "raster",
        1,
        "raster/raster_threshold.vert.glsl",
        "raster/raster_threshold.frag.glsl",
        ["a_position", "a_texcoord"],
        ["u_domain", "u_texture", "u_shader_mode"],
        "raster_texture",
        ["raster"]
      ),
      raster_contour_overlay: entry(
        "raster",
        "raster_contour_overlay",
        "raster",
        2,
        "raster/raster_contour_overlay.vert.glsl",
        "raster/raster_contour_overlay.frag.glsl",
        ["a_position", "a_texcoord"],
        ["u_domain", "u_texture", "u_shader_mode"],
        "raster_texture",
        ["raster"]
      )
    },
    surface: {
      surface_flat: entry(
        "surface",
        "surface_flat",
        "surface",
        0,
        "surface/surface_flat.vert.glsl",
        "surface/surface_flat.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_uncertainty"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_z_range"],
        null,
        ["surface"]
      ),
      surface_lambert: entry(
        "surface",
        "surface_lambert",
        "surface",
        1,
        "surface/surface_lambert.vert.glsl",
        "surface/surface_lambert.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_uncertainty"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_z_range"],
        "surface_flat",
        ["surface"]
      ),
      surface_height_colormap: entry(
        "surface",
        "surface_height_colormap",
        "surface",
        2,
        "surface/surface_height_colormap.vert.glsl",
        "surface/surface_height_colormap.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_uncertainty"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_z_range"],
        "surface_lambert",
        ["surface"]
      ),
      surface_uncertainty_alpha: entry(
        "surface",
        "surface_uncertainty_alpha",
        "surface",
        3,
        "surface/surface_uncertainty_alpha.vert.glsl",
        "surface/surface_uncertainty_alpha.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_uncertainty"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_z_range"],
        "surface_lambert",
        ["surface"]
      )
    },
    mesh: {
      mesh_flat: entry(
        "mesh",
        "mesh_flat",
        "mesh",
        0,
        "mesh/mesh_flat.vert.glsl",
        "mesh/mesh_flat.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_scalar"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_scalar_range", "u_ambient", "u_diffuse", "u_specular"],
        null,
        ["mesh"]
      ),
      mesh_lambert: entry(
        "mesh",
        "mesh_lambert",
        "mesh",
        1,
        "mesh/mesh_lambert.vert.glsl",
        "mesh/mesh_lambert.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_scalar"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_scalar_range", "u_ambient", "u_diffuse", "u_specular"],
        "mesh_flat",
        ["mesh"]
      ),
      mesh_phong_simple: entry(
        "mesh",
        "mesh_phong_simple",
        "mesh",
        2,
        "mesh/mesh_phong_simple.vert.glsl",
        "mesh/mesh_phong_simple.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_scalar"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_scalar_range", "u_ambient", "u_diffuse", "u_specular"],
        "mesh_lambert",
        ["mesh"]
      ),
      mesh_scalar_colormap: entry(
        "mesh",
        "mesh_scalar_colormap",
        "mesh",
        3,
        "mesh/mesh_scalar_colormap.vert.glsl",
        "mesh/mesh_scalar_colormap.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_scalar"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_scalar_range", "u_ambient", "u_diffuse", "u_specular"],
        "mesh_lambert",
        ["mesh"]
      ),
      mesh_selection_highlight: entry(
        "mesh",
        "mesh_selection_highlight",
        "mesh",
        4,
        "mesh/mesh_selection_highlight.vert.glsl",
        "mesh/mesh_selection_highlight.frag.glsl",
        ["a_position3", "a_normal", "a_color", "a_scalar"],
        ["u_view_projection", "u_shading_mode", "u_light_dir", "u_scalar_range", "u_ambient", "u_diffuse", "u_specular"],
        "mesh_lambert",
        ["mesh"]
      )
    }
  };

  var aliases = {
    density: "density_splat",
    splat: "density_splat",
    density_splat: "density_splat",
    uncertainty: "uncertainty_alpha",
    "uncertainty-alpha": "uncertainty_alpha",
    uncertainty_alpha: "uncertainty_alpha",
    glow: "trajectory_age_glow",
    point_glow: "point_sprite_glow",
    point_sprite: "point_sprite_glow",
    point_sprite_glow: "point_sprite_glow",
    "point-sprite-glow": "point_sprite_glow",
    trajectory: "trajectory_age",
    age: "trajectory_age",
    trajectory_age: "trajectory_age",
    trajectory_age_glow: "trajectory_age_glow",
    "trajectory-glow": "trajectory_age_glow",
    velocity: "trajectory_velocity",
    trajectory_velocity: "trajectory_velocity",
    "trajectory-velocity": "trajectory_velocity",
    direction: "trajectory_direction",
    trajectory_direction: "trajectory_direction",
    "trajectory-direction": "trajectory_direction",
    raster: "raster_texture",
    raster_texture: "raster_texture",
    texture: "raster_texture",
    threshold: "raster_threshold",
    raster_threshold: "raster_threshold",
    "raster-threshold": "raster_threshold",
    contour: "raster_contour_overlay",
    raster_contour_overlay: "raster_contour_overlay",
    "raster-contour": "raster_contour_overlay",
    flat: "mesh_flat",
    lambert: "mesh_lambert",
    phong: "mesh_phong_simple",
    scalar: "mesh_scalar_colormap",
    selected: "mesh_selection_highlight",
    mesh_flat: "mesh_flat",
    mesh_lambert: "mesh_lambert",
    mesh_phong_simple: "mesh_phong_simple",
    mesh_scalar_colormap: "mesh_scalar_colormap",
    mesh_selection_highlight: "mesh_selection_highlight",
    surface_flat: "surface_flat",
    surface_lambert: "surface_lambert",
    surface_height_colormap: "surface_height_colormap",
    surface_uncertainty_alpha: "surface_uncertainty_alpha",
    height: "surface_height_colormap",
    "height-colormap": "surface_height_colormap"
  };

  function resolveShaderName(name) {
    var shader = String(name || "default").toLowerCase();
    return aliases[shader] || shader;
  }

  function familyForLayer(layer, layerType) {
    var type = String(layerType || (layer && layer.type) || "").toLowerCase();
    if (type === "points" || type === "point") {
      return "points";
    }
    if (type === "lines" || type === "line" || type === "path" || type === "path3d") {
      return "lines";
    }
    if (type === "raster") {
      return "raster";
    }
    if (type === "surface") {
      return "surface";
    }
    if (type === "mesh") {
      return "mesh";
    }
    return "points";
  }

  function requestedShader(scene) {
    return scene && scene.webgl ? resolveShaderName(scene.webgl.shader || "default") : "default";
  }

  function requestedMaterialShader(layer, material, family) {
    var source = material || (layer && layer.material) || {};
    var raw = source && source.shading ? String(source.shading).toLowerCase() : null;
    var shading = raw ? resolveShaderName(raw) : null;
    if (family === "surface" && layer && layer.surface_meta && layer.surface_meta.shading) {
      raw = String(layer.surface_meta.shading).toLowerCase();
      shading = resolveShaderName(raw);
    }
    if (family === "surface") {
      if (raw === "flat") {
        return "surface_flat";
      }
      if (raw === "lambert") {
        return "surface_lambert";
      }
      if (raw === "height") {
        return "surface_height_colormap";
      }
      if (raw === "uncertainty") {
        return "surface_uncertainty_alpha";
      }
    }
    if (family === "mesh") {
      if (raw === "flat") {
        return "mesh_flat";
      }
      if (raw === "lambert") {
        return "mesh_lambert";
      }
    }
    return shading;
  }

  function defaultShaderForFamily(family) {
    if (family === "raster") {
      return "raster_texture";
    }
    if (family === "surface") {
      return "surface_lambert";
    }
    if (family === "mesh") {
      return "mesh_lambert";
    }
    return "default";
  }

  function findEntry(family, shader) {
    var familyRegistry = registry[family] || {};
    var name = resolveShaderName(shader);
    return familyRegistry[name] || familyRegistry[defaultShaderForFamily(family)] || null;
  }

  function shaderNameForLayer(scene, layer, material, layerType) {
    var family = familyForLayer(layer, layerType);
    if (family === "surface" || family === "mesh") {
      return requestedMaterialShader(layer, material, family) || defaultShaderForFamily(family);
    }
    return requestedShader(scene);
  }

  function getShaderEntry(scene, layer, material, layerType) {
    var family = familyForLayer(layer, layerType);
    var shader = shaderNameForLayer(scene, layer, material, layerType);
    var entry = findEntry(family, shader);
    if (!entry) {
      entry = findEntry(family, defaultShaderForFamily(family));
    }
    return entry;
  }

  function shaderModeForLayer(scene, layer, layerType) {
    var entry = getShaderEntry(scene, layer, layer && layer.material, layerType);
    return entry && isFinite(Number(entry.mode)) ? Number(entry.mode) : 0;
  }

  function programKeyForEntry(entry, scene) {
    if (!entry) {
      return "primitive";
    }
    if (entry.program === "primitive" &&
        scene && scene.render &&
        (scene.render.dimension === "3d" || scene.render.coordinate_system === "cartesian3d")) {
      return "primitive3d";
    }
    return entry.program || "primitive";
  }

  function getProgramForLayer(programs, layer, material, scene) {
    if (!programs || !layer) {
      return null;
    }
    var entry = getShaderEntry(scene, layer, material, layer.type);
    var key = programKeyForEntry(entry, scene);
    return programs[key] || programs.primitive;
  }

  global.ggWebGLProgramRegistry = {
    registry: registry,
    aliases: aliases,
    families: registry,
    defaultShaderForFamily: defaultShaderForFamily,
    resolveShaderName: resolveShaderName,
    getShaderEntry: getShaderEntry,
    shaderModeForLayer: shaderModeForLayer,
    getProgramForLayer: getProgramForLayer
  };
}(window));
