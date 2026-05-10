class MDLLoader extends BaseModelLoader {
    static CHUNK_HIERARCHY = 0xD100;
    static CHUNK_SOURCE = 0xD110;
    static CHUNK_HIERARCHY_END = 0xD120;
    static CHUNK_MESH_HEADER = 0xD000;
    static CHUNK_MESH_SOURCE = 0xD010;
    static CHUNK_MESH_NODES = 0xD020;
    static CHUNK_SOFTSKINS = 0xD030;
    static CHUNK_MESH_END = 0xD040;
    static CHUNK_PROTO = 0xB100;
    static CHUNK_PROTO_END = 0xB1FF;

    constructor() {
        super();
        this.hierarchy = null;
        this.mesh = null;
    }

    load(buffer) {
        const reader = new Stream(buffer);
        this.loadFromReader(reader);
        return this.createThreeJSGroup();
    }

    loadFromReader(reader) {
        this.mesh = {
            meshes: [],
            attachments: new Map(),
            checksum: 0
        };

        let attachmentNames = [];
        while (!reader.eof()) {
            if (reader.tell() + 6 > reader.buffer.byteLength) break;

            const chunkType = reader.readUInt16();
            const chunkSize = reader.readUInt32();
            const chunkStart = reader.tell();

            switch (chunkType) {
                case MDLLoader.CHUNK_HIERARCHY:
                    this.loadModelHierarchy(reader, chunkSize);
                    break;
                case MDLLoader.CHUNK_SOURCE:
                case MDLLoader.CHUNK_MESH_SOURCE:
                    reader.seek(chunkStart + chunkSize);
                    break;
                case MDLLoader.CHUNK_MESH_HEADER:
                    this.loadMeshHeader(reader);
                    break;
                case MDLLoader.CHUNK_MESH_NODES:
                    attachmentNames = this.loadMeshNodes(reader);
                    break;
                case MDLLoader.CHUNK_SOFTSKINS:
                    this.loadSoftSkins(reader);
                    break;
                case MDLLoader.CHUNK_PROTO:
                    const attachmentName = attachmentNames.length > this.mesh.attachments.size
                        ? attachmentNames[this.mesh.attachments.size]
                        : `attachment_${this.mesh.attachments.size}`;
                    this.loadProtoMesh(reader, chunkSize, attachmentName);
                    break;
                case MDLLoader.CHUNK_MESH_END:
                    return;
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

    loadModelHierarchy(reader, chunkSize) {
        const startPos = reader.tell();
        try {
            if (reader.tell() + 4 <= reader.buffer.byteLength) {
                const version = reader.readUInt32();
            }
            reader.seek(startPos + chunkSize);
        } catch (e) {
            reader.seek(startPos + chunkSize);
        }
    }

    loadMeshHeader(reader) {
        try {
            const version = reader.readUInt32();
        } catch (e) {
            console.warn("Error reading mesh header:", e);
        }
    }

    loadMeshNodes(reader) {
        try {
            const nodeCount = reader.readUInt16();
            const attachmentNames = [];
            for (let i = 0; i < nodeCount && !reader.eof(); i++) {
                const name = reader.readLine(true);
                attachmentNames.push(name);
            }
            return attachmentNames;
        } catch (e) {
            return [];
        }
    }

    loadSoftSkins(reader) {
        try {
            const checksum = reader.readUInt32();
            const meshCount = reader.readUInt16();

            if (!this.mesh) {
                this.mesh = {
                    meshes: [],
                    attachments: new Map(),
                    checksum: checksum
                };
            }

            for (let i = 0; i < meshCount && !reader.eof(); i++) {
                const softSkin = this.loadSingleSoftSkinChunked(reader, i);
                if (softSkin) {
                    this.mesh.meshes.push(softSkin);
                }
            }
        } catch (e) {
            console.error("Error loading soft skins:", e);
        }
    }

    loadSingleSoftSkinChunked(reader, index) {
        try {
            const softSkin = {
                mesh: null,
                bboxes: [],
                wedge_normals: [],
                weights: [],
                nodes: []
            };

            while (!reader.eof()) {
                if (reader.tell() + 6 > reader.buffer.byteLength) break;

                const chunkType = reader.readUInt16();
                const chunkSize = reader.readUInt32();
                const chunkStart = reader.tell();
                const objectEnd = chunkStart + chunkSize;

                switch (chunkType) {
                    case 0xE100: // HEADER - SOFT SKIN
                        const version = reader.readUInt32();
                        break;
                    case MDLLoader.CHUNK_PROTO: // PROTO (embedded MRM)
                        const mrmLoader = new MRMLoader();
                        mrmLoader.setTextures(this.loadedTextures);
                        softSkin.mesh = mrmLoader.loadFromSection(reader);
                        break;
                    case MDLLoader.CHUNK_PROTO_END: // NODES
                        this.loadSoftSkinNodes(reader, softSkin);
                        break;
                    case 0xE110: // END - SOFT SKIN
                        return softSkin;
                    default:
                        reader.seek(chunkStart + chunkSize);
                        break;
                }
                reader.seek(objectEnd);
            }
            return softSkin;
        } catch (e) {
            console.error(`Error loading SoftSkin ${index}:`, e);
            return null;
        }
    }

    loadSoftSkinNodes(reader, softSkin) {
        try {
            const weightBufferSize = reader.readUInt32();
            const weightBufferEnd = reader.tell() + weightBufferSize;

            if (softSkin.mesh && softSkin.mesh.positions) {
                softSkin.weights = [];
                for (let i = 0; i < softSkin.mesh.positions.length; i++) {
                    const count = reader.readUInt32();
                    const vertexWeights = [];
                    for (let j = 0; j < count; j++) {
                        vertexWeights.push({
                            weight: reader.readFloat32(),
                            position: reader.readVec3(),
                            node_index: reader.readUInt8()
                        });
                    }
                    softSkin.weights.push(vertexWeights);
                }
            }

            reader.seek(weightBufferEnd);

            const wedgeNormalCount = reader.readUInt32();
            softSkin.wedge_normals = [];
            for (let i = 0; i < wedgeNormalCount; i++) {
                softSkin.wedge_normals.push({
                    normal: reader.readVec3(),
                    index: reader.readUInt32()
                });
            }

            const nodeCount = reader.readUInt16();
            softSkin.nodes = [];
            for (let i = 0; i < nodeCount; i++) {
                softSkin.nodes.push(reader.readInt32());
            }

            softSkin.bboxes = [];
            for (let i = 0; i < nodeCount; i++) {
                const bbox = {
                    center: reader.readVec3(),
                    axes: [reader.readVec3(), reader.readVec3(), reader.readVec3()],
                    half_width: reader.readVec3()
                };
                const childCount = reader.readUInt16();
                for (let j = 0; j < childCount; j++) {
                    reader.seek(48, 'relative');
                }
                softSkin.bboxes.push(bbox);
            }
        } catch (e) {
            console.error("Error loading SoftSkin nodes:", e);
        }
    }

    loadProtoMesh(reader, chunkSize, attachmentName) {
        const startPos = reader.tell();
        try {
            const mrmLoader = new MRMLoader();
            mrmLoader.setTextures(this.loadedTextures);
            const mesh = mrmLoader.loadFromSection(reader);
            if (mesh) {
                this.mesh.attachments.set(attachmentName, mesh);
            }
        } catch (e) {
            console.error(`Error loading proto mesh ${attachmentName}:`, e);
            reader.seek(startPos + chunkSize);
        }
    }

    createThreeJSGroup() {
        const group = new THREE.Group();

        if (!this.mesh) {
            return group;
        }

        if (this.mesh.meshes && this.mesh.meshes.length > 0) {
            for (let i = 0; i < this.mesh.meshes.length; i++) {
                const softSkin = this.mesh.meshes[i];
                if (softSkin && softSkin.mesh) {
                    group.add(softSkin.mesh);
                }
            }
        }

        if (this.mesh.attachments) {
            for (const [name, mesh] of this.mesh.attachments) {
                if (mesh) {
                    group.add(mesh);
                }
            }
        }

        if (group.children.length === 0) {
            const geometry = new THREE.BoxGeometry(1, 1, 1);
            const material = new THREE.MeshLambertMaterial({ color: 0xff0000 });
            const placeholder = new THREE.Mesh(geometry, material);
            group.add(placeholder);
        }

        return group;
    }
}

// MDM LOADER 
class MDMLoader extends MDLLoader {
    loadFromReader(reader) {
        this.mesh = {
            meshes: [],
            attachments: new Map(),
            checksum: 0
        };

        let attachmentNames = [];
        while (!reader.eof()) {
            if (reader.tell() + 6 > reader.buffer.byteLength) break;

            const chunkType = reader.readUInt16();
            const chunkSize = reader.readUInt32();
            const chunkStart = reader.tell();
            const objEnd = chunkStart + chunkSize;

            switch (chunkType) {
                case MDLLoader.CHUNK_MESH_HEADER: // HEADER
                    this.loadMeshHeader(reader);
                    break;
                case MDLLoader.CHUNK_MESH_SOURCE: // SOURCE
                    reader.seek(chunkStart + chunkSize);
                    break;
                case MDLLoader.CHUNK_MESH_NODES: // NODES
                    attachmentNames = this.loadMeshNodes(reader);
                    break;
                case MDLLoader.CHUNK_SOFTSKINS: // SOFTSKINS
                    this.loadSoftSkins(reader);
                    break;
                case MDLLoader.CHUNK_PROTO: // PROTO
                    const attachmentName = attachmentNames.length > this.mesh.attachments.size
                        ? attachmentNames[this.mesh.attachments.size]
                        : `attachment_${this.mesh.attachments.size}`;
                    this.loadProtoMesh(reader, chunkSize, attachmentName);
                    break;
                case MDLLoader.CHUNK_MESH_END: // END
                    return;
                default:
                    reader.seek(chunkStart + chunkSize);
                    break;
            }
            reader.seek(objEnd);
        }
    }
}
