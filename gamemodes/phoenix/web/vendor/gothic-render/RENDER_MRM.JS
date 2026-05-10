class MRMLoader extends BaseModelLoader {
    static VERSION_G1 = 0x305;
    static VERSION_G2 = 0x905;

    load(buffer) {
        const reader = new Stream(buffer);
        this.loadFromReader(reader);
        return this.createThreeJSGroup();
    }

    loadFromReader(reader) {
        this.readChunked(reader);
    }

    readChunked(reader) {
        while (!reader.eof()) {
            if (reader.tell() + 6 > reader.buffer.byteLength) break;

            const chunkType = reader.readUInt16();
            const chunkSize = reader.readUInt32();
            const chunkStart = reader.tell();

            switch (chunkType) {
                case BaseModelLoader.CHUNK_MESH:
                    this.loadFromSection(reader);
                    break;
                case BaseModelLoader.CHUNK_END:
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

    loadFromSection(reader) {
        const version = reader.readUInt16();
        const contentSize = reader.readUInt32();
        const contentOffset = reader.tell();

        reader.seek(contentSize, 'relative');

        if (reader.tell() + 1 > reader.buffer.byteLength) {
            throw new Error("Buffer underrun reading submesh count");
        }

        const submeshCount = reader.readUInt8();
        const verticesOffset = reader.readUInt32() + contentOffset;
        const verticesSize = reader.readUInt32();
        const normalsOffset = reader.readUInt32() + contentOffset;
        const normalsSize = reader.readUInt32();

        if (verticesOffset >= reader.buffer.byteLength || normalsOffset >= reader.buffer.byteLength) {
            throw new Error("Invalid vertex/normal offsets");
        }

        // Read submesh sections
        const submeshSections = [];
        for (let i = 0; i < submeshCount; i++) {
            if (reader.tell() + 40 > reader.buffer.byteLength) {
                throw new Error(`Buffer underrun reading submesh section ${i}`);
            }

            submeshSections.push({
                triangles: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                wedges: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                colors: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                trianglePlaneIndices: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                trianglePlanes: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                wedgeMap: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                vertexUpdates: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                triangleEdges: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                edges: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() },
                edgeScores: { offset: reader.readUInt32() + contentOffset, size: reader.readUInt32() }
            });
        }

        this.parseMaterialArchive(reader, submeshCount);

        if (version === MRMLoader.VERSION_G2) {
            this.alphaTest = reader.tell() + 1 > reader.buffer.byteLength ? true : reader.readInt8() !== 0;
        }

        this.skipBoundingBox(reader);
        if (reader.tell() + 0x10 <= reader.buffer.byteLength) {
            reader.seek(0x10, 'relative');
        }
        const endPos = reader.tell();

        // Read vertices
        reader.seek(verticesOffset);
        this.positions = [];
        for (let i = 0; i < verticesSize; i++) {
            this.positions.push(reader.readVec3());
        }

        // Read normals
        reader.seek(normalsOffset);
        this.normals = [];
        for (let i = 0; i < normalsSize; i++) {
            this.normals.push(reader.readVec3());
        }

        // Load submeshes
        this.subMeshes = [];
        for (let i = 0; i < submeshCount; i++) {
            try {
                const subMesh = this.loadSubMesh(reader, submeshSections[i]);
                this.subMeshes.push(subMesh);
            } catch (e) {
                console.warn(`Failed to load submesh ${i}:`, e);
            }
        }

        reader.seek(endPos);
        this.loadFromReader(reader);
        return this.createThreeJSGroup();
    }

    loadSubMesh(reader, section) {
        const subMesh = {
            triangles: [],
            wedges: [],
            colors: [],
            trianglePlaneIndices: [],
            trianglePlanes: [],
            triangleEdges: [],
            edges: [],
            edgeScores: [],
            wedgeMap: []
        };

        const validateSection = (sectionName, section, itemSize) => {
            return section.offset < reader.buffer.byteLength &&
                section.offset + section.size * itemSize <= reader.buffer.byteLength;
        };

        if (validateSection('triangles', section.triangles, 6)) {
            reader.seek(section.triangles.offset);
            for (let i = 0; i < section.triangles.size; i++) {
                subMesh.triangles.push({
                    wedges: [reader.readUInt16(), reader.readUInt16(), reader.readUInt16()]
                });
            }
        }

        if (validateSection('wedges', section.wedges, 20)) {
            reader.seek(section.wedges.offset);
            for (let i = 0; i < section.wedges.size; i++) {
                const wedge = {
                    normal: reader.readVec3(),
                    texture: reader.readVec2(),
                    index: reader.readUInt16()
                };
                reader.readUInt16(); // padding
                subMesh.wedges.push(wedge);
            }
        }

        // Load remaining sections with validation
        const sections = [
            { name: 'colors', size: 4, loader: () => reader.readFloat32() },
            { name: 'trianglePlaneIndices', size: 2, loader: () => reader.readUInt16() },
            { name: 'trianglePlanes', size: 16, loader: () => ({ distance: reader.readFloat32(), normal: reader.readVec3() }) },
            { name: 'triangleEdges', size: 6, loader: () => ({ edges: [reader.readUInt16(), reader.readUInt16(), reader.readUInt16()] }) },
            { name: 'edges', size: 4, loader: () => ({ edges: [reader.readUInt16(), reader.readUInt16()] }) },
            { name: 'edgeScores', size: 4, loader: () => reader.readFloat32() },
            { name: 'wedgeMap', size: 2, loader: () => reader.readUInt16() }
        ];

        sections.forEach(({ name, size, loader }) => {
            if (validateSection(name, section[name], size)) {
                reader.seek(section[name].offset);
                for (let i = 0; i < section[name].size; i++) {
                    subMesh[name].push(loader());
                }
            }
        });

        return subMesh;
    }

    parseMaterialArchive(reader, count) {
        this.materials = [];
        try {
            if (reader.tell() + 8 > reader.buffer.byteLength) {
                this.createDefaultMaterials(count);
                return;
            }

            if (this.hasZenKitArchiveHeader(reader)) {
                this.parseEmbeddedArchive(reader, count);
            } else {
                this.createDefaultMaterials(count);
            }
        } catch (e) {
            console.error('Error in parseMaterialArchive:', e);
            this.createDefaultMaterials(count);
        }
    }

    hasZenKitArchiveHeader(reader) {
        const startPos = reader.tell();
        try {
            const headerBytes = new Uint8Array(14);
            for (let i = 0; i < 14 && startPos + i < reader.buffer.byteLength; i++) {
                headerBytes[i] = reader.view.getUint8(startPos + i);
            }
            const headerText = new TextDecoder().decode(headerBytes);
            return headerText.startsWith("ZenGin Archive");
        } catch (e) {
            return false;
        } finally {
            reader.seek(startPos);
        }
    }

    parseEmbeddedArchive(reader, count) {
        this.skipArchiveHeader(reader);
        for (let i = 0; i < count && !reader.eof(); i++) {
            try {
                const material = this.parseSingleMaterial(reader, i);
                this.materials.push(material);
            } catch (e) {
                console.error(`Failed to parse material ${i}:`, e);
                this.materials.push(this.createDefaultMaterial(i));
            }
        }
        while (this.materials.length < count) {
            this.materials.push(this.createDefaultMaterial(this.materials.length));
        }
    }

    skipArchiveHeader(reader) {
        let objectsLineEncountered = false;
        while (!reader.eof() && reader.tell() + 4 < reader.buffer.byteLength) {
            const line = this.readArchiveLine(reader).trim();
            if (line.startsWith("objects")) {
                const objectCount = parseInt(line.split(' ')[1]);
                objectsLineEncountered = true;
            } else if (line === "END") {
                if (objectsLineEncountered) {
                    if (!reader.eof() && reader.tell() < reader.buffer.byteLength) {
                        const byte = reader.view.getUint8(reader.tell());
                        if (byte === 0x0A || byte === 0x0D) {
                            reader.readUInt8();
                        }
                    }
                    return;
                }
            }
        }
    }

    parseSingleMaterial(reader, index) {
        const materialName = this.readNullTerminatedString(reader);
        const objectSizePos = reader.tell();
        const objectSize = reader.readUInt32();
        const objectEnd = objectSizePos + objectSize;
        const objectVersion = reader.readUInt16();
        const objectIndex = reader.readUInt32();
        const objectName = this.readNullTerminatedString(reader);
        const className = this.readNullTerminatedString(reader);

        if (className !== "zCMaterial") {
            throw new Error(`Expected zCMaterial, got ${className}`);
        }

        const material = this.parseMaterialData(reader, objectVersion);
        material.name = materialName || objectName || material.name;

        reader.seek(objectEnd);
        return material;
    }

    parseMaterialData(reader, version) {
        const material = this.createDefaultMaterial(0);
        try {
            material.name = this.readNullTerminatedString(reader);
            material.group = reader.readUInt8();

            // Color (BGRA)
            const b = reader.readUInt8() / 255.0;
            const g = reader.readUInt8() / 255.0;
            const r = reader.readUInt8() / 255.0;
            const a = reader.readUInt8() / 255.0;
            material.color = { r, g, b, a };

            material.smoothAngle = reader.readFloat32();
            material.texture = this.readNullTerminatedString(reader);

            if (material.texture) {
                material.texture = material.texture.replace(/\.tga$/i, '').toUpperCase();
            }
        } catch (e) {
            console.warn(`Error parsing material data:`, e);
        }
        return material;
    }

    readArchiveLine(reader) {
        let line = '';
        while (!reader.eof() && reader.tell() < reader.buffer.byteLength) {
            const byte = reader.readUInt8();
            if (byte === 0x0A || byte === 0x0D) break;
            if (byte >= 32 && byte <= 126) {
                line += String.fromCharCode(byte);
            }
        }
        return line.trim();
    }

    createDefaultMaterials(count) {
        this.materials = [];
        for (let i = 0; i < count; i++) {
            this.materials.push(this.createDefaultMaterial(i));
        }
    }

    skipBoundingBox(reader) {
        if (reader.tell() + 24 <= reader.buffer.byteLength) {
            reader.seek(24, 'relative');
        }
    }
}