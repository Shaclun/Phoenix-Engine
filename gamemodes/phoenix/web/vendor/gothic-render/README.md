# Gothic Render Library

A JavaScript/CEF library for rendering Gothic game assets (models and textures) in web browsers using Three.js library.

## Overview

This library provides a custom HTML element `<gothic-render>` and `<gothic-texture>` that can load and display 3D models from Gothic game files directly in web pages. It supports:

- **MRM mesh files** - Contains a mesh with [LOD][] information
- **MMB mesh files** - Contains a morph mesh with its mesh, skeleton and animation data  
- **MDM mesh files** - Contains the mesh of a model
- **MDL mesh files** - Contains a mesh and a hierarchy which make up a model   
- **TEX texture files** - Contains texture data in a variety of formats

## Quick Start

### CEF Setup Required

To use this library, you must first set up CEF (Chromium Embedded Framework) according to the instructions found on the project's page (https://g2o.gitlab.io/modules/cef/) and pack your website code according to the G2O Team's instructions (https://gothicmultiplayerteam.gitlab.io/docs/0.3.3/multiplayer/resources/#zip).

### Basic Usage

```html
<!DOCTYPE html>
<html>
<head>
    <script type="text/javascript" src="THREE.MIN.JS"></script>
    <script type="text/javascript" src="RENDER_STREAM.JS"></script>
    <script type="text/javascript" src="RENDER_TEX.JS"></script>
    <script type="text/javascript" src="RENDER_BASE.JS"></script>
    <script type="text/javascript" src="RENDER_MRM.JS"></script>
    <script type="text/javascript" src="RENDER_MDL.JS"></script>
    <script type="text/javascript" src="RENDER_MMB.JS"></script>
    <script type="text/javascript" src="RENDER_LOAD.JS"></script>
</head>
<body>
    <gothic-render 
        width="256" 
        height="256" 
        visual="ITAR_PAL_H.MRM"
        rot-x="0" 
        rot-y="0" 
        rot-z="0"
        scale="1">
    </gothic-render>
</body>
</html>
```

### Attributes - gothic-render

| Attribute | Type | Description | Default |
|-----------|------|-------------|---------|
| `width` | number | Canvas width in pixels | 256 |
| `height` | number | Canvas height in pixels | 256 |
| `visual` | string | Path to MRM file | required |
| `rot-x` | number | Initial X rotation in radians | 0 |
| `rot-y` | number | Initial Y rotation in radians | 0 |
| `rot-z` | number | Initial Z rotation in radians | 0 |
| `light-intensity` | number | Light intesity | 1 |
| `scale` | number | Scale | 1 |

### JavaScript API

```javascript
// Get reference to element
const render = document.querySelector('gothic-render');

// Set rotation programmatically
render.setRotation(0.5, 1.0, 0);

// Change model
render.setAttribute('visual', 'NEW_MODEL.MRM');
```

## File Structure

```
gothic-render-library/
├── THREE.MIN.JS       # Three.js library
├── RENDER_STREAM.JS   # Binary data stream utilities
├── RENDER_MRM.JS      # MRM mesh loader
├── RENDER_MMB.JS      # MMB mesh loader
├── RENDER_MDL.JS      # MDL mesh loader
├── RENDER_TEX.JS      # TEX texture loader
├── RENDER_LOAD.JS     # Main rendering component
└── index.html         # Usage example
```

## Technical Details

## Data Loading

The library supports data loading through a custom `fetch` function (modified by G2O Team to support VDF protocol) from three Gothic locations:
- `TEXTURES/_COMPILED` - for texture files
- `MESHES/_COMPILED` - for mesh files
- `ANIMS/_COMPILED` - for mesh files

These paths are hardcoded within the library.

## Examples

### Interactive Model Viewer
```html
<gothic-render 
    width="512" 
    height="512" 
    visual="WEAPON.MRM"
    style="cursor: pointer;">
</gothic-render>

<script>
    document.querySelector('gothic-render').addEventListener('click', function() {
        // Add rotation animation
        let rotation = 0;
        const animate = () => {
            rotation += 0.02;
            this.setRotation(0, rotation, 0);
            requestAnimationFrame(animate);
        };
        animate();
    });
</script>
```

### Multiple Models Grid
```html
<div class="model-grid">
    <gothic-render visual="HELMET.MRM"></gothic-render>
    <gothic-render visual="ARMOR.MRM"></gothic-render>
    <gothic-render visual="SWORD.MRM"></gothic-render>
</div>
```

### Custom Texture Processing
```html
<div class="texture-grid">
    <gothic-texture width="256" height="256" texture="MAP_ADDONWORLD"></gothic-texture>
</div>
```

### Limitations
- Keep in mind that rendering many different models simultaneously might create performance problems
- Performance varies with model complexity and texture resolution

### Acknowledgments
- **ZenKit** - Reference C++ implementation for Gothic file formats
- **G2O Team** - CEF integration and VDF protocol support
