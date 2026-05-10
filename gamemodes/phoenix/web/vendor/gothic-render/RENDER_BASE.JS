class BaseModelLoader {
    static CHUNK_MESH = 0xB100;
    static CHUNK_END = 0xB1FF;

    constructor() {
        this.positions = [];
        this.normals = [];
        this.subMeshes = [];
        this.materials = [];
        this.loadedTextures = new Map();
    }

    setTextures(textureMap) {
        this.loadedTextures = textureMap;
    }

    createDefaultMaterial(index) {
        return {
            name: `Material_${index}`,
            texture: '',
            color: {
                r: 0.5 + Math.random() * 0.5,
                g: 0.5 + Math.random() * 0.5,
                b: 0.5 + Math.random() * 0.5,
                a: 1.0
            },
            group: 0,
            smoothAngle: 0.0
        };
    }

    createThreeJSMaterial(materialData) {
        const textureName = materialData.texture ? materialData.texture.toUpperCase() : '';
        let material;

        if (textureName && this.loadedTextures.has(textureName)) {
            const texture = this.loadedTextures.get(textureName);
            material = new THREE.MeshLambertMaterial({
                map: texture,
                side: THREE.BackSide,
                transparent: true
            });
        } else {
            const color = materialData.color || { r: 0.7, g: 0.7, b: 0.7, a: 1.0 };
            material = new THREE.MeshLambertMaterial({
                color: new THREE.Color(color.r, color.g, color.b),
                side: THREE.BackSide,
                transparent: color.a < 1.0,
                opacity: color.a
            });
        }

        material.userData = {
            textureName: textureName || 'NO_TEXTURE',
            materialName: materialData.name || 'UNNAMED_MATERIAL',
            originalMaterialData: materialData
        };

        return material;
    }

    readNullTerminatedString(reader) {
        let result = '';
        while (reader.tell() < reader.buffer.byteLength) {
            const byte = reader.readUInt8();
            if (byte === 0) break;
            if (byte >= 32 && byte <= 126) {
                result += String.fromCharCode(byte);
            } else if (byte > 126) {
                break;
            }
        }
        return result.trim();
    }

    createThreeJSGroup() {
        const group = new THREE.Group();
        for (let i = 0; i < this.subMeshes.length; i++) {
            const subMesh = this.subMeshes[i];
            const mesh = this.createThreeJSMesh(subMesh, i);
            group.add(mesh);
        }
        return group;
    }

    createThreeJSMesh(subMesh, materialIndex) {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        const normals = [];
        const uvs = [];
        const indices = [];
        const wedgeToVertex = new Map();
        let vertexIndex = 0;

        for (const wedge of subMesh.wedges) {
            if (wedge.index < this.positions.length) {
                const pos = this.positions[wedge.index];
                vertices.push(pos.x, pos.y, pos.z);
                normals.push(wedge.normal.x, wedge.normal.y, wedge.normal.z);
                uvs.push(wedge.texture.x, wedge.texture.y);
                wedgeToVertex.set(subMesh.wedges.indexOf(wedge), vertexIndex);
                vertexIndex++;
            }
        }

        for (const triangle of subMesh.triangles) {
            for (const wedgeIdx of triangle.wedges) {
                if (wedgeToVertex.has(wedgeIdx)) {
                    indices.push(wedgeToVertex.get(wedgeIdx));
                }
            }
        }

        geometry.setIndex(indices);
        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('normal', new THREE.Float32BufferAttribute(normals, 3));
        geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));

        const materialData = this.materials[materialIndex] || this.createDefaultMaterial(materialIndex);
        const material = this.createThreeJSMaterial(materialData);

        return new THREE.Mesh(geometry, material);
    }
}