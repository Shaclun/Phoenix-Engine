const clamp = (value, min, max) => Math.max(min, Math.min(value, max));

class GothicRenderSystem {
    constructor() {
        this.renderer = null;
        this.scene = null;
        this.camera = null;
        this.modelCache = new Map();
        this.textureCache = new Map();
        this.isInitialized = false;
        this.sharedRenderTarget = null;
        this.ambientLight = null;
        this.directionalLight = null;
    }

    initialize() {
        if (this.isInitialized) return;

        const canvas = document.createElement('canvas');
        canvas.width = 256;
        canvas.height = 256;
        canvas.style.display = 'none';
        document.body.appendChild(canvas);

        this.renderer = new THREE.WebGLRenderer({
            canvas: canvas,
            antialias: true,
            alpha: true,
            preserveDrawingBuffer: true
        });

        this.renderer.setSize(256, 256);
        this.renderer.setClearColor(0x000000, 0);

        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(45, 1, 0.1, 1000);

        this.ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        this.scene.add(this.ambientLight);

        this.directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        this.directionalLight.position.set(5, 5, 5);
        this.scene.add(this.directionalLight);

        this.isInitialized = true;

        this.sharedRenderTarget = new THREE.WebGLRenderTarget(256, 256, {
            minFilter: THREE.LinearFilter,
            magFilter: THREE.LinearFilter,
            format: THREE.RGBAFormat
        });
    }

    async loadTexture(url) {
        if (this.textureCache.has(url)) {
            return this.textureCache.get(url);
        }

        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`Failed to load texture: ${response.status}`);
            const buffer = await response.arrayBuffer();
            const texLoader = new TEXLoader();
            const texture = texLoader.load(buffer);
            this.textureCache.set(url, texture);
            return texture;
        } catch (error) {
            // Cache the miss too — stops the inventory from spamming
            // identical failing fetches every time a cell re-renders.
            this.textureCache.set(url, null);
            return null;
        }
    }

    async loadModel(url) {
        if (this.modelCache.has(url)) {
            return this.modelCache.get(url);
        }

        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`Failed to load model: ${response.status}`);
            const buffer = await response.arrayBuffer();

            const fileExtension = url.split('.').pop().toUpperCase();
            let loader;

            // Create appropriate loader
            switch (fileExtension) {
                case 'MDL':
                    loader = new MDLLoader();
                    break;
                case 'MDM':
                    loader = new MDMLoader();
                    break;
                case 'MMB':
                    loader = new MMBLoader();
                    break;
                default:
                    loader = new MRMLoader();
                    break;
            }

            // Pre-load textures
            const textureMap = await this.preloadTexturesForModel(loader, buffer, fileExtension);
            loader.setTextures(textureMap);

            const model = loader.load(buffer);
            this.modelCache.set(url, model);
            return model;
        } catch (error) {
            // Cache the miss — prevents repeated fetch storms when the
            // same .MRM/.MDM is referenced by many cells.
            this.modelCache.set(url, null);
            return null;
        }
    }

    async preloadTexturesForModel(loader, buffer, fileExtension) {
        const textureMap = new Map();

        // Probe-parse the mesh once so we can read the material list,
        // fetch each texture from `vdfs://.../TEXTURES/_COMPILED/`, then
        // hand the resolved map back to the loader before the real
        // load() builds final Three.js materials. We trust that meshes
        // resolved through the data.xml-derived visual map ship with
        // their textures — if a player VDF is missing a particular
        // `*-C.TEX` the engine will pop a blocking modal which JS can
        // not catch (the fetch Promise rejection happens AFTER the
        // modal). In that case extend `phoenix.item.visuals` rather
        // than working around it here.
        let probe = null;
        try { probe = loader.load(buffer); } catch (_) { probe = null; }
        const names = this.extractMaterialsFromModel(probe, loader);

        const texBase = 'vdfs://_WORK/DATA/TEXTURES/_COMPILED/';
        const promises = [];
        for (const raw of names) {
            if (!raw) continue;
            const upper = String(raw).toUpperCase();
            const base = upper.endsWith('.TGA') ? upper.slice(0, -4)
                       : upper.endsWith('.TEX') ? upper.slice(0, -4)
                       :                          upper;
            const url = texBase + base + '-C.TEX';
            promises.push(this.loadTexture(url).then((tex) => {
                if (tex) textureMap.set(upper, tex);
            }));
        }
        await Promise.all(promises);
        return textureMap;
    }

    extractMaterialsFromModel(model, loader) {
        const allMaterials = new Set();

        if (model) {
            model.traverse((child) => {
                if (child.isMesh && child.material && child.material.userData && child.material.userData.textureName) {
                    allMaterials.add(child.material.userData.textureName.toUpperCase());
                }
            });
        }

        if (loader.mesh) {
            this.extractMaterialsFromMesh(loader.mesh, allMaterials);
        }

        return allMaterials;
    }

    extractMaterialsFromMesh(mesh, allMaterials) {
        if (mesh.meshes) {
            for (const softSkin of mesh.meshes) {
                if (softSkin.mesh) {
                    softSkin.mesh.traverse((child) => {
                        if (child.isMesh && child.material && child.material.userData && child.material.userData.textureName) {
                            allMaterials.add(child.material.userData.textureName.toUpperCase());
                        }
                    });
                }
            }
        }

        if (mesh.attachments) {
            for (const [name, attachment] of mesh.attachments) {
                if (attachment) {
                    attachment.traverse((child) => {
                        if (child.isMesh && child.material && child.material.userData && child.material.userData.textureName) {
                            allMaterials.add(child.material.userData.textureName.toUpperCase());
                        }
                    });
                }
            }
        }
    }

    renderToCanvas(model, width, height, rotX = 0, rotY = 0, rotZ = 0, lightIntensity = 1.0, scale = 1.0) {
        if (!this.isInitialized) this.initialize();

        const renderTarget = this.sharedRenderTarget;
        if (renderTarget.width !== width || renderTarget.height !== height) {
            renderTarget.setSize(width, height);
        }

        this.scene.clear();
        this.ambientLight.intensity = 0.6 * lightIntensity;
        this.directionalLight.intensity = 0.8 * lightIntensity;
        this.scene.add(this.ambientLight);
        this.scene.add(this.directionalLight);

        const modelClone = model.clone();
        modelClone.rotation.set(rotX, rotY, rotZ);
        this.scene.add(modelClone);

        // Calculate camera position
        const box = new THREE.Box3().setFromObject(modelClone);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        const maxDim = Math.max(size.x, size.y, size.z);
        const baseDistance = Math.max(maxDim * 2.5, 0.1);

        this.camera.position.set(center.x, center.y, center.z + baseDistance);
        this.camera.lookAt(center);
        this.camera.aspect = width / height;

        const baseFov = 45;
        const rawFov = baseFov / scale;
        this.camera.fov = clamp(rawFov, 10, 75);
        this.camera.near = Math.max(0.001, baseDistance * 0.01);
        this.camera.far = baseDistance * 10;
        this.camera.updateProjectionMatrix();

        // Render to target
        this.renderer.setRenderTarget(renderTarget);
        this.renderer.setSize(width, height);
        this.renderer.render(this.scene, this.camera);

        // Read pixels and create canvas
        const pixels = new Uint8Array(width * height * 4);
        this.renderer.readRenderTargetPixels(renderTarget, 0, 0, width, height, pixels);

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        const imageData = ctx.createImageData(width, height);

        // Flip Y axis
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                const srcIndex = ((height - 1 - y) * width + x) * 4;
                const dstIndex = (y * width + x) * 4;
                imageData.data[dstIndex] = pixels[srcIndex];
                imageData.data[dstIndex + 1] = pixels[srcIndex + 1];
                imageData.data[dstIndex + 2] = pixels[srcIndex + 2];
                imageData.data[dstIndex + 3] = pixels[srcIndex + 3];
            }
        }

        ctx.putImageData(imageData, 0, 0);
        this.renderer.setRenderTarget(null);
        return canvas;
    }
}

class GothicItemRender extends HTMLElement {
    constructor() {
        super();
        this.materialOverrides = new Map();
        this.model = null;
        this.canvas = null;
        this._width = 64;
        this._height = 64;
        this._rotX = 0;
        this._rotY = 0;
        this._rotZ = 0;
        this._lightIntensity = 1.0;
        this._scale = 1.0;
        this._visual = '';
    }

    static get observedAttributes() {
        return ['width', 'height', 'visual', 'rot-x', 'rot-y', 'rot-z', 'light-intensity', 'scale'];
    }

    connectedCallback() {
        this.style.display = 'inline-block';
        this.style.width = `${this._width}px`;
        this.style.height = `${this._height}px`;
        this.style.overflow = 'hidden';
        this.updateFromAttributes();
        this.loadAndRender();
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue) return;

        const updates = {
            'width': () => {
                this._width = parseInt(newValue) || 64;
                this.style.width = `${this._width}px`;
            },
            'height': () => {
                this._height = parseInt(newValue) || 64;
                this.style.height = `${this._height}px`;
            },
            'visual': () => {
                this._visual = newValue ? newValue.toUpperCase() : '';
            },
            'rot-x': () => { this._rotX = parseFloat(newValue) || 0.0; },
            'rot-y': () => { this._rotY = parseFloat(newValue) || 0.0; },
            'rot-z': () => { this._rotZ = parseFloat(newValue) || 0.0; },
            'light-intensity': () => { this._lightIntensity = clamp(parseFloat(newValue) || 1.0, 0.0, 10.0); },
            'scale': () => { this._scale = clamp(parseFloat(newValue) || 1.0, 0.01, 10.0); }
        };

        if (updates[name]) {
            updates[name]();
            if (['width', 'height', 'rot-x', 'rot-y', 'rot-z', 'light-intensity', 'scale'].includes(name) && this.model) {
                this.renderModel();
            } else if (name === 'visual') {
                this.loadAndRender();
            }
        }
    }

    updateFromAttributes() {
        this._width = parseInt(this.getAttribute('width')) || 64;
        this._height = parseInt(this.getAttribute('height')) || 64;
        this._visual = this.getAttribute('visual') ? this.getAttribute('visual').toUpperCase() : '';
        this._rotX = parseFloat(this.getAttribute('rot-x')) || 0.0;
        this._rotY = parseFloat(this.getAttribute('rot-y')) || 0.0;
        this._rotZ = parseFloat(this.getAttribute('rot-z')) || 0.0;
        this._lightIntensity = clamp(parseFloat(this.getAttribute('light-intensity')) || 1.0, 0.0, 10.0);
        this._scale = clamp(parseFloat(this.getAttribute('scale')) || 1.0, 0.01, 10.0);
    }

    // FF
    deepCloneModel(model) {
        const clonedModel = model.clone();

        clonedModel.traverse((child) => {
            if (child.isMesh && child.material) {
                child.material = child.material.clone();
                child.material.userData = { ...child.material.userData };
            }
        });

        return clonedModel;
    }

    async loadAndRender() {
        if (!this._visual) {
            this.showPlaceholder();
            return;
        }

        try {
            let modelUrl;
            const visualUpper = this._visual.toUpperCase();

            if (visualUpper.endsWith('.MDL')) {
                modelUrl = `vdfs://_WORK/DATA/ANIMS/_COMPILED/${this._visual}`;
            } else if (visualUpper.endsWith('.MDM')) {
                modelUrl = `vdfs://_WORK/DATA/ANIMS/_COMPILED/${this._visual}`;
            } else if (visualUpper.endsWith('.MRM')) {
                modelUrl = `vdfs://_WORK/DATA/MESHES/_COMPILED/${this._visual}`;
            } else if (visualUpper.endsWith('.MMB')) {
                modelUrl = `vdfs://_WORK/DATA/ANIMS/_COMPILED/${this._visual}`;
            }

            const originalModel = await gothicRenderSystem.loadModel(modelUrl);
            if (originalModel) {
                this.model = this.deepCloneModel(originalModel);
                this.renderModel();
            } else {
                this.showError();
            }
        } catch (error) {
            console.error(`Error loading model ${this._visual}:`, error);
            this.showError();
        }
    }

    async renderModel() {
        if (!this.model) return;

        try {
            await this.applyMaterialOverrides();

            this.canvas = gothicRenderSystem.renderToCanvas(
                this.model, this._width, this._height,
                this._rotX, this._rotY, this._rotZ,
                this._lightIntensity, this._scale
            );
            this.innerHTML = '';
            this.appendChild(this.canvas);
        } catch (error) {
            console.error('Error rendering model:', error);
            this.showError();
        }
    }

    async applyMaterialOverrides() {
        //console.log("Overides to apply:", Array.from(this.materialOverrides.entries()));
        if (this.materialOverrides.size === 0) return;

        for (const [materialName, textureName] of this.materialOverrides) {
            //console.log(`Looking for material: "${materialName}" to apply tex: "${textureName}"`);

            const texUrl = `vdfs://_WORK/DATA/TEXTURES/_COMPILED/${textureName}-C.TEX`;
            const texture = await gothicRenderSystem.loadTexture(texUrl);

            let foundMaterials = 0;
            this.model.traverse((child) => {
                if (child.isMesh && child.material && child.material.userData) {
                    //console.log(`Found mesh with material: "${child.material.userData.materialName}"`);

                    if (child.material.userData.materialName === materialName) {
                        //console.log(`MATCH! Applying tex to: ${materialName}`);
                        child.material.map = texture;
                        child.material.needsUpdate = true;
                        foundMaterials++;
                    }
                }
            });

            //console.log(`Applied to ${foundMaterials} materials`);
        }
    }

    showPlaceholder() {
        // Phoenix UI renders a category-glyph fallback BEHIND the
        // gothic-render element, so missing models stay transparent
        // and let the glyph show through instead of a grey "No Model"
        // box.
        this.innerHTML = '';
        this.style.background = 'transparent';
    }

    showError() {
        // Same reasoning as showPlaceholder — keep the element
        // transparent so the fallback glyph stays visible.
        this.innerHTML = '';
        this.style.background = 'transparent';
    }

    // Public API
    async setMaterialTexture(materialName, textureName) {
        this.materialOverrides.set(materialName.toUpperCase(), textureName.toUpperCase());
        if (this.model) {
            await this.renderModel();
        }
    }

    getMaterialList() {
        if (!this.model) return [];

        const materials = new Map();

        this.model.traverse((child) => {
            if (child.isMesh && child.material && child.material.userData) {
                const materialName = child.material.userData.materialName || 'UNKNOWN';
                const textureName = child.material.userData.textureName || 'NO_TEXTURE';
                materials.set(materialName, textureName);
            }
        });

        return Array.from(materials.entries()).map(([name, texture]) => ({
            materialName: name,
            currentTexture: texture
        }));
    }

    clearMaterialOverrides() {
        this.materialOverrides.clear();
        if (this.model) {
            this.renderModel();
        }
    }

    setPosition(x, y) {
        this.style.left = `${x}px`;
        this.style.top = `${y}px`;
        this.style.position = 'absolute';
    }

    setSize(width, height) {
        this.setAttribute('width', width.toString());
        this.setAttribute('height', height.toString());
    }

    setRotation(x, y, z) {
        this.setAttribute('rot-x', (typeof x === 'number' ? x : parseFloat(x) || 0).toString());
        this.setAttribute('rot-y', (typeof y === 'number' ? y : parseFloat(y) || 0).toString());
        this.setAttribute('rot-z', (typeof z === 'number' ? z : parseFloat(z) || 0).toString());
    }

    setLightIntensity(intensity) {
        this.setAttribute('light-intensity', (typeof intensity === 'number' ? intensity : parseFloat(intensity) || 1.0).toString());
    }

    setScale(scale) {
        this.setAttribute('scale', (typeof scale === 'number' ? scale : parseFloat(scale) || 1.0).toString());
    }

    // Getters/Setters
    get rotX() { return this._rotX; }
    set rotX(value) { this.setAttribute('rot-x', (typeof value === 'number' ? value : parseFloat(value) || 0).toString()); }

    get rotY() { return this._rotY; }
    set rotY(value) { this.setAttribute('rot-y', (typeof value === 'number' ? value : parseFloat(value) || 0).toString()); }

    get rotZ() { return this._rotZ; }
    set rotZ(value) { this.setAttribute('rot-z', (typeof value === 'number' ? value : parseFloat(value) || 0).toString()); }

    get lightIntensity() { return this._lightIntensity; }
    set lightIntensity(value) { this.setAttribute('light-intensity', (typeof value === 'number' ? value : parseFloat(value) || 1.0).toString()); }

    get scale() { return this._scale; }
    set scale(value) { this.setAttribute('scale', (typeof value === 'number' ? value : parseFloat(value) || 1.0).toString()); }

    get visual() { return this._visual; }
    set visual(value) { this.setAttribute('visual', value ? value.toString() : ''); }

    isReady() { return this.model !== null; }

    getInfo() {
        return {
            visual: this._visual,
            width: this._width,
            height: this._height,
            rotX: this._rotX,
            rotY: this._rotY,
            rotZ: this._rotZ,
            lightIntensity: this._lightIntensity,
            scale: this._scale,
            isModelLoaded: this.model !== null
        };
    }
}

const gothicRenderSystem = new GothicRenderSystem();
customElements.define('gothic-render', GothicItemRender);

class GothicTextureElement extends HTMLElement {
    constructor() {
        super();
        this.canvas = null;
        this.ctx = null;
        this.imageData = null;
        this._width = 256;
        this._height = 256;
        this._textureName = '';
        this._filter = 'linear';
    }

    static get observedAttributes() {
        return ['width', 'height', 'texture', 'filter'];
    }

    connectedCallback() {
        this.style.display = 'inline-block';
        this.style.overflow = 'hidden';
        this.createCanvas();
        this.updateFromAttributes();
        this.loadAndRender();
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue) return;

        const updates = {
            'width': () => {
                this._width = parseInt(newValue) || 256;
                if (this.canvas) {
                    this.canvas.width = this._width;
                    this.style.width = `${this._width}px`;
                }
            },
            'height': () => {
                this._height = parseInt(newValue) || 256;
                if (this.canvas) {
                    this.canvas.height = this._height;
                    this.style.height = `${this._height}px`;
                }
            },
            'texture': () => {
                this._textureName = newValue ? newValue.toUpperCase() : '';
                this.loadAndRender();
            },
            'filter': () => {
                this._filter = newValue || 'linear';
                if (this.ctx) {
                    this.ctx.imageSmoothingEnabled = ['nearest', 'pixelated'].includes(this._filter) ? false : true;
                }
                this.render();
            }
        };

        if (updates[name]) {
            updates[name]();
            if (['width', 'height'].includes(name) && this.canvas) {
                this.render();
            } else if (name === 'texture') {
                this.loadAndRender();
            }
        }
    }

    updateFromAttributes() {
        this._width = parseInt(this.getAttribute('width')) || 256;
        this._height = parseInt(this.getAttribute('height')) || 256;
        this._textureName = this.getAttribute('texture') ? this.getAttribute('texture').toUpperCase() : '';
        this._filter = this.getAttribute('filter') || 'linear';
    }

    createCanvas() {
        this.canvas = document.createElement('canvas');
        this.canvas.width = this._width;
        this.canvas.height = this._height;
        this.canvas.style.width = `${this._width}px`;
        this.canvas.style.height = `${this._height}px`;
        this.canvas.style.display = 'block';

        this.ctx = this.canvas.getContext('2d');
        this.ctx.imageSmoothingEnabled = this._filter === 'linear';

        this.innerHTML = '';
        this.appendChild(this.canvas);

        this.style.width = `${this._width}px`;
        this.style.height = `${this._height}px`;
    }

    async loadAndRender() {
        if (!this._textureName) {
            this.showPlaceholder();
            return;
        }

        try {
            const texUrl = `vdfs://_WORK/DATA/TEXTURES/_COMPILED/${this._textureName}-C.TEX`;
            const threeTexture = await gothicRenderSystem.loadTexture(texUrl);

            if (!threeTexture) {
                throw new Error('Failed to load texture');
            }

            this.convertThreeTextureToImageData(threeTexture);
            this.render();
        } catch (error) {
            console.error(`Error loading texture ${this._textureName}:`, error);
            this.showError();
        }
    }

    convertThreeTextureToImageData(threeTexture) {
        if (threeTexture.image && threeTexture.image.data) {
            this.imageData = {
                data: new Uint8Array(threeTexture.image.data),
                width: threeTexture.image.width,
                height: threeTexture.image.height
            };
        } else {
            // Fallback
            const size = 64;
            const data = new Uint8Array(size * size * 4);
            for (let i = 0; i < size * size; i++) {
                const x = i % size;
                const y = Math.floor(i / size);
                const checker = ((x >> 3) + (y >> 3)) % 2;
                data[i * 4] = checker ? 255 : 128;     // R
                data[i * 4 + 1] = checker ? 255 : 128; // G
                data[i * 4 + 2] = checker ? 255 : 128; // B
                data[i * 4 + 3] = 255;                 // A
            }
            this.imageData = { data, width: size, height: size };
        }
    }

    render() {
        if (!this.imageData || !this.ctx) return;

        try {
            this.ctx.clearRect(0, 0, this._width, this._height);
            this.ctx.imageSmoothingEnabled = this._filter === 'linear';

            const canvasImageData = new ImageData(
                new Uint8ClampedArray(this.imageData.data),
                this.imageData.width,
                this.imageData.height
            );

            const tempCanvas = document.createElement('canvas');
            tempCanvas.width = this.imageData.width;
            tempCanvas.height = this.imageData.height;
            const tempCtx = tempCanvas.getContext('2d');

            tempCtx.putImageData(canvasImageData, 0, 0);
            this.ctx.drawImage(tempCanvas, 0, 0, this._width, this._height);

        } catch (error) {
            console.error('Error rendering texture:', error);
            this.showError();
        }
    }

    showPlaceholder() {
        if (!this.ctx) return;
        this.ctx.fillStyle = '#333333';
        this.ctx.fillRect(0, 0, this._width, this._height);
        this.ctx.fillStyle = '#666666';
        this.ctx.font = '14px monospace';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('No Texture', this._width / 2, this._height / 2);
    }

    showError() {
        if (!this.ctx) return;
        this.ctx.fillStyle = '#660000';
        this.ctx.fillRect(0, 0, this._width, this._height);
        this.ctx.fillStyle = '#ff6666';
        this.ctx.font = '14px monospace';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('Error', this._width / 2, this._height / 2);
    }

    // Canvas-like API
    getContext() { return this.ctx; }

    getImageData(sx = 0, sy = 0, sw = this._width, sh = this._height) {
        if (!this.ctx) return null;
        return this.ctx.getImageData(sx, sy, sw, sh);
    }

    putImageData(imageData, dx = 0, dy = 0) {
        if (!this.ctx) return;
        this.ctx.putImageData(imageData, dx, dy);
    }

    drawImage(image, ...args) {
        if (!this.ctx) return;
        this.ctx.drawImage(image, ...args);
    }

    fillRect(x, y, width, height) {
        if (!this.ctx) return;
        this.ctx.fillRect(x, y, width, height);
    }

    clearRect(x, y, width, height) {
        if (!this.ctx) return;
        this.ctx.clearRect(x, y, width, height);
    }

    // Getters/Setters
    get width() { return this._width; }
    set width(value) { this.setAttribute('width', value.toString()); }

    get height() { return this._height; }
    set height(value) { this.setAttribute('height', value.toString()); }

    get textureName() { return this._textureName; }
    set textureName(value) { this.setAttribute('texture', value); }

    get filter() { return this._filter; }
    set filter(value) { this.setAttribute('filter', value); }

    // Utility
    isReady() { return this.imageData !== null; }

    toDataURL(type = 'image/png', quality = 0.92) {
        if (!this.canvas) return null;
        return this.canvas.toDataURL(type, quality);
    }

    toBlob(callback, type = 'image/png', quality = 0.92) {
        if (!this.canvas) return;
        this.canvas.toBlob(callback, type, quality);
    }
}

customElements.define('gothic-texture', GothicTextureElement);