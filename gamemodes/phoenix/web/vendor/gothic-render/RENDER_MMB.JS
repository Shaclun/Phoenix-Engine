class MMBLoader extends BaseModelLoader {
    static CHUNK_SOURCES = 0xE010;
    static CHUNK_HEADER = 0xE020;
    static CHUNK_ANIMATIONS = 0xE030;
    static CHUNK_PROTO = 0xB100;
    static CHUNK_MORPH = 0xB1FF;

    constructor() {
        super();
        this.name = '';
        this.sources = [];
        this.morphPositions = [];
        this.animations = [];
    }

    load(buffer) {
        const reader = new Stream(buffer);
        this.loadFromReader(reader);
        return this.createThreeJSGroup();
    }

    loadFromReader(reader) {
        while (!reader.eof()) {
            if (reader.tell() + 6 > reader.buffer.byteLength) break;

            const chunkType = reader.readUInt16();
            const chunkSize = reader.readUInt32();
            const chunkStart = reader.tell();

            switch (chunkType) {
                case MMBLoader.CHUNK_SOURCES:
                    this.loadSources(reader);
                    break;
                case MMBLoader.CHUNK_HEADER:
                    this.loadHeader(reader);
                    break;
                case MMBLoader.CHUNK_PROTO:
                    this.loadProtoMesh(reader);
                    break;
                case MMBLoader.CHUNK_MORPH:
                    this.loadMorphPositions(reader);
                    break;
                case MMBLoader.CHUNK_ANIMATIONS:
                    this.loadAnimations(reader);
                    break;
                default:
                    if (chunkStart + chunkSize <= reader.buffer.byteLength) {
                        reader.seek(chunkStart + chunkSize);
                    } else {
                        return;
                    }
                    break;
            }
        }
    }

    loadSources(reader) {
        try {
            const count = reader.readUInt16();
            this.sources = [];
            for (let i = 0; i < count; i++) {
                // Skip file date (placeholder)
                reader.seek(8, 'relative'); // Date structure
                const fileName = reader.readLine(true);
                this.sources.push({ fileName });
            }
        } catch (e) {
            console.warn("Error loading sources:", e);
        }
    }

    loadHeader(reader) {
        try {
            const version = reader.readUInt32();
            this.name = reader.readLine(true);
        } catch (e) {
            console.warn("Error loading header:", e);
        }
    }

    loadProtoMesh(reader) {
        try {
            const mrmLoader = new MRMLoader();
            mrmLoader.setTextures(this.loadedTextures);

            // Load the embedded MultiResolutionMesh
            const mesh = mrmLoader.loadFromSection(reader);
            if (mesh) {
                // Copy mesh data to this loader
                this.positions = mrmLoader.positions || [];
                this.normals = mrmLoader.normals || [];
                this.subMeshes = mrmLoader.subMeshes || [];
                this.materials = mrmLoader.materials || [];

                // Initialize morph positions array
                this.morphPositions = new Array(this.positions.length);
                for (let i = 0; i < this.morphPositions.length; i++) {
                    this.morphPositions[i] = { x: 0, y: 0, z: 0 };
                }
            }
        } catch (e) {
            console.error("Error loading proto mesh:", e);
        }
    }

    loadMorphPositions(reader) {
        try {
            for (let i = 0; i < this.morphPositions.length && !reader.eof(); i++) {
                this.morphPositions[i] = reader.readVec3();
            }
        } catch (e) {
            console.warn("Error loading morph positions:", e);
        }
    }

    loadAnimations(reader) {
        try {
            const animationCount = reader.readUInt16();
            this.animations = [];

            for (let i = 0; i < animationCount && !reader.eof(); i++) {
                const animation = {
                    name: reader.readLine(false),
                    blendIn: reader.readFloat32(),
                    blendOut: reader.readFloat32(),
                    duration: reader.readFloat32(),
                    layer: reader.readInt32(),
                    speed: reader.readFloat32(),
                    flags: reader.readUInt8(),
                    vertices: [],
                    samples: []
                };

                const vertexCount = reader.readUInt32();
                animation.frameCount = reader.readUInt32();

                // Read vertex indices
                for (let j = 0; j < vertexCount; j++) {
                    animation.vertices.push(reader.readUInt32());
                }

                // Read sample data (placeholder - skip for now)
                const sampleCount = vertexCount * animation.frameCount;
                for (let j = 0; j < sampleCount; j++) {
                    animation.samples.push(reader.readVec3());
                }

                this.animations.push(animation);
            }
        } catch (e) {
            console.warn("Error loading animations:", e);
        }
    }

    createThreeJSGroup() {
        const group = new THREE.Group();

        // Create meshes from submeshes (static rendering for now)
        for (let i = 0; i < this.subMeshes.length; i++) {
            const subMesh = this.subMeshes[i];
            const mesh = this.createThreeJSMesh(subMesh, i);

            // TODO: In future it might be possible to add morph targets support here...
            group.add(mesh);
        }

        // If no meshes, create placeholder
        if (group.children.length === 0) {
            const geometry = new THREE.BoxGeometry(1, 1, 1);
            const material = new THREE.MeshLambertMaterial({ color: 0x00ff00 }); // Green for MMB ie your special power is... greeen
            const placeholder = new THREE.Mesh(geometry, material);
            group.add(placeholder);
        }

        return group;
    }
}