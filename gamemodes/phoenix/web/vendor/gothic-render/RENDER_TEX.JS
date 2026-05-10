class TEXLoader {
    static ZTEX_SIGNATURE = "ZTEX";

    constructor() {
        this.format = null;
        this.width = 0;
        this.height = 0;
        this.mipmapCount = 0;
        this.referenceWidth = 0;
        this.referenceHeight = 0;
        this.averageColor = 0;
        this.palette = [];
        this.textures = [];
    }

    load(buffer) {
        const reader = new Stream(buffer);

        if (buffer.byteLength < 32) {
            throw new Error(`TEX file too small: ${buffer.byteLength} bytes`);
        }

        const signature = reader.readString(4);
        if (signature !== TEXLoader.ZTEX_SIGNATURE) {
            throw new Error(`Invalid TEX signature: ${signature}`);
        }

        const version = reader.readUInt32();
        if (version !== 0) {
            throw new Error(`Invalid TEX version: ${version}`);
        }

        this.format = reader.readUInt32();
        this.width = reader.readUInt32();
        this.height = reader.readUInt32();
        this.mipmapCount = Math.max(1, reader.readUInt32());
        this.referenceWidth = reader.readUInt32();
        this.referenceHeight = reader.readUInt32();
        this.averageColor = reader.readUInt32();

        // Load P8 palette if needed
        if (this.format === 9) {
            if (reader.tell() + 1024 > reader.buffer.byteLength) {
                throw new Error("Insufficient data for P8 palette");
            }
            this.palette = [];
            for (let i = 0; i < 256; i++) {
                this.palette.push({
                    b: reader.readUInt8(),
                    g: reader.readUInt8(),
                    r: reader.readUInt8(),
                    a: reader.readUInt8()
                });
            }
        }

        // Load texture mipmaps (lowest level first)
        this.textures = [];
        for (let level = this.mipmapCount - 1; level >= 0; level--) {
            const size = this.calculateMipmapSize(this.format, this.width, this.height, level);

            if (reader.tell() + size > reader.buffer.byteLength) {
                console.warn(`Insufficient data for mipmap level ${level}, truncating`);
                break;
            }

            const mipmapData = new Uint8Array(size);
            for (let i = 0; i < size; i++) {
                mipmapData[i] = reader.readUInt8();
            }
            this.textures.push(mipmapData);
        }

        if (this.textures.length === 0) {
            throw new Error("No texture data found");
        }

        return this.createThreeJSTexture();
    }

    calculateMipmapSize(format, width, height, level) {
        let x = Math.max(1, width);
        let y = Math.max(1, height);

        for (let i = 0; i < level; i++) {
            if (x > 1) x >>= 1;
            if (y > 1) y >>= 1;
        }

        const formatSizes = {
            0: 4, // B8G8R8A8
            1: 4, // R8G8B8A8  
            2: 4, // A8B8G8R8
            3: 4, // A8R8G8B8
            4: 3, // B8G8R8
            5: 3, // R8G8B8
            6: 2, // A4R4G4B4
            7: 2, // A1R5G5B5
            8: 2, // R5G6B5
            9: 1, // P8
            10: () => Math.max(1, Math.floor(x / 4)) * Math.max(1, Math.floor(y / 4)) * 8,  // DXT1
            11: () => Math.max(1, Math.floor(x / 4)) * Math.max(1, Math.floor(y / 4)) * 16, // DXT2
            12: () => Math.max(1, Math.floor(x / 4)) * Math.max(1, Math.floor(y / 4)) * 16, // DXT3
            13: () => Math.max(1, Math.floor(x / 4)) * Math.max(1, Math.floor(y / 4)) * 16, // DXT4
            14: () => Math.max(1, Math.floor(x / 4)) * Math.max(1, Math.floor(y / 4)) * 16  // DXT5
        };

        const sizeCalc = formatSizes[format];
        if (typeof sizeCalc === 'function') {
            return sizeCalc();
        } else if (sizeCalc !== undefined) {
            return sizeCalc * x * y;
        } else {
            throw new Error(`Unsupported texture format: ${format}`);
        }
    }

    createThreeJSTexture() {
        const mipmaps = this.loadMipmapsFromFile();
        if (mipmaps.length === 0) return this.createFallbackTexture();

        this.generateMissingMipmaps(mipmaps);
        return this.createDataTexture(mipmaps);
    }

    loadMipmapsFromFile() {
        const mipmaps = [];

        for (let i = this.textures.length - 1; i >= 0; i--) {
            const level = this.textures.length - 1 - i;
            const mipWidth = Math.max(1, this.width >> level);
            const mipHeight = Math.max(1, this.height >> level);
            const rgbaData = this.convertToRGBA(this.textures[i], mipWidth, mipHeight, this.format);
            mipmaps.push({ data: rgbaData, width: mipWidth, height: mipHeight });
        }
        return mipmaps;
    }

    generateMissingMipmaps(mipmaps) {
        let lastMip = mipmaps[mipmaps.length - 1];
        while (lastMip.width > 1 || lastMip.height > 1) {
            const newWidth = Math.max(1, Math.floor(lastMip.width / 2));
            const newHeight = Math.max(1, Math.floor(lastMip.height / 2));
            const newData = this.downsampleMipmap(lastMip, newWidth, newHeight);
            lastMip = { data: newData, width: newWidth, height: newHeight };
            mipmaps.push(lastMip);
        }
    }

    downsampleMipmap(sourceMip, newWidth, newHeight) {
        const newData = new Uint8Array(newWidth * newHeight * 4);
        for (let y = 0; y < newHeight; y++) {
            for (let x = 0; x < newWidth; x++) {
                const srcX = x * 2;
                const srcY = y * 2;
                const dstIdx = (y * newWidth + x) * 4;
                const samples = this.getSampleIndices(sourceMip, srcX, srcY);

                for (let c = 0; c < 3; c++) {
                    newData[dstIdx + c] = Math.floor(
                        (sourceMip.data[samples[0] + c] + sourceMip.data[samples[1] + c] +
                            sourceMip.data[samples[2] + c] + sourceMip.data[samples[3] + c]) / 4
                    );
                }
                newData[dstIdx + 3] = 255;
            }
        }
        return newData;
    }

    getSampleIndices(mip, srcX, srcY) {
        const w = mip.width;
        const h = mip.height;
        return [
            (srcY * w + srcX) * 4,
            (srcY * w + Math.min(srcX + 1, w - 1)) * 4,
            (Math.min(srcY + 1, h - 1) * w + srcX) * 4,
            (Math.min(srcY + 1, h - 1) * w + Math.min(srcX + 1, w - 1)) * 4
        ];
    }

    createDataTexture(mipmaps) {
        const texture = new THREE.DataTexture(
            mipmaps[0].data, this.width, this.height,
            THREE.RGBAFormat, THREE.UnsignedByteType
        );
        texture.mipmaps = mipmaps;
        texture.generateMipmaps = false;
        texture.minFilter = THREE.NearestMipmapLinearFilter;
        texture.magFilter = THREE.LinearFilter;
        texture.flipY = false;
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        texture.needsUpdate = true;
        return texture;
    }

    createFallbackTexture() {
        const texture = new THREE.DataTexture(
            new Uint8Array([255, 0, 255, 255]), 1, 1,
            THREE.RGBAFormat, THREE.UnsignedByteType
        );
        texture.generateMipmaps = true;
        texture.minFilter = THREE.LinearFilter;
        texture.needsUpdate = true;
        return texture;
    }

    convertToRGBA(data, width, height, format) {
        const rgba = new Uint8Array(width * height * 4);

        const converters = {
            0: () => this.convertBGRA(data, rgba),           // B8G8R8A8
            1: () => this.convertRGBA(data, rgba),           // R8G8B8A8
            2: () => this.convertABGR(data, rgba),           // A8B8G8R8
            3: () => this.convertARGB(data, rgba),           // A8R8G8B8
            4: () => this.convertBGR(data, rgba, width, height),  // B8G8R8
            5: () => this.convertRGB(data, rgba, width, height),  // R8G8B8
            6: () => this.convertA4R4G4B4(data, rgba, width, height), // A4R4G4B4
            7: () => this.convertA1R5G5B5(data, rgba, width, height), // A1R5G5B5
            8: () => this.convertR5G6B5(data, rgba, width, height),   // R5G6B5
            9: () => this.convertP8(data, rgba, width, height),       // P8
            10: () => this.decodeDXT1(data, width, height),           // DXT1
            11: () => this.decodeDXT3(data, width, height),           // DXT2 (treated as DXT3)
            12: () => this.decodeDXT3(data, width, height),           // DXT3
            13: () => this.decodeDXT5(data, width, height),           // DXT4 (treated as DXT5)
            14: () => this.decodeDXT5(data, width, height)            // DXT5
        };

        const converter = converters[format];
        if (converter) {
            const result = converter();
            return result || rgba; // Some converters modify rgba in place, others return new data
        } else {
            // Default fallback - magenta
            for (let i = 0; i < width * height; i++) {
                rgba[i * 4] = 255;     // R
                rgba[i * 4 + 1] = 0;   // G
                rgba[i * 4 + 2] = 255; // B
                rgba[i * 4 + 3] = 255; // A
            }
            return rgba;
        }
    }

    // Format converters
    convertBGRA(data, rgba) {
        for (let i = 0; i < data.length; i += 4) {
            rgba[i] = data[i + 2];     // R from B
            rgba[i + 1] = data[i + 1]; // G
            rgba[i + 2] = data[i];     // B from R
            rgba[i + 3] = data[i + 3]; // A
        }
    }

    convertRGBA(data, rgba) {
        rgba.set(data);
    }

    convertABGR(data, rgba) {
        for (let i = 0; i < data.length; i += 4) {
            rgba[i] = data[i + 3];     // R from A
            rgba[i + 1] = data[i + 2]; // G from B
            rgba[i + 2] = data[i + 1]; // B from G
            rgba[i + 3] = data[i];     // A from R
        }
    }

    convertARGB(data, rgba) {
        for (let i = 0; i < data.length; i += 4) {
            rgba[i] = data[i + 1];     // R
            rgba[i + 1] = data[i + 2]; // G
            rgba[i + 2] = data[i + 3]; // B
            rgba[i + 3] = data[i];     // A
        }
    }

    convertBGR(data, rgba, width, height) {
        for (let i = 0; i < width * height; i++) {
            rgba[i * 4] = data[i * 3 + 2];     // R from B
            rgba[i * 4 + 1] = data[i * 3 + 1]; // G
            rgba[i * 4 + 2] = data[i * 3];     // B from R
            rgba[i * 4 + 3] = 255;             // A
        }
    }

    convertRGB(data, rgba, width, height) {
        for (let i = 0; i < width * height; i++) {
            rgba[i * 4] = data[i * 3];         // R
            rgba[i * 4 + 1] = data[i * 3 + 1]; // G
            rgba[i * 4 + 2] = data[i * 3 + 2]; // B
            rgba[i * 4 + 3] = 255;             // A
        }
    }

    convertA4R4G4B4(data, rgba, width, height) {
        for (let i = 0; i < width * height; i++) {
            const pixel = data[i * 2] | (data[i * 2 + 1] << 8);

            rgba[i * 4 + 2] = ((pixel >> 0) & 0x0F) * 17;  // B
            rgba[i * 4 + 1] = ((pixel >> 4) & 0x0F) * 17;  // G
            rgba[i * 4] = ((pixel >> 8) & 0x0F) * 17;      // R
            rgba[i * 4 + 3] = ((pixel >> 12) & 0x0F) * 17; // A
        }
    }

    convertA1R5G5B5(data, rgba, width, height) {
        for (let i = 0; i < width * height; i++) {
            const pixel = data[i * 2] | (data[i * 2 + 1] << 8);

            rgba[i * 4 + 2] = ((pixel >> 0) & 0x1F) * 8;   // B (5 bits -> 8 bits)
            rgba[i * 4 + 1] = ((pixel >> 5) & 0x1F) * 8;   // G (5 bits -> 8 bits)
            rgba[i * 4] = ((pixel >> 10) & 0x1F) * 8;      // R (5 bits -> 8 bits)
            rgba[i * 4 + 3] = ((pixel >> 15) & 0x01) * 255; // A (1 bit -> 8 bits)
        }
    }

    convertR5G6B5(data, rgba, width, height) {
        for (let i = 0; i < width * height; i++) {
            const pixel = data[i * 2] | (data[i * 2 + 1] << 8);

            rgba[i * 4] = Math.floor(((pixel >> 11) & 0x1F) * 8.225806452);     // R (5->8)
            rgba[i * 4 + 1] = Math.floor(((pixel >> 5) & 0x3F) * 4.047619048);  // G (6->8)
            rgba[i * 4 + 2] = Math.floor((pixel & 0x1F) * 8.225806452);         // B (5->8)
            rgba[i * 4 + 3] = 255;                                               // A
        }
    }

    convertP8(data, rgba, width, height) {
        for (let i = 0; i < width * height; i++) {
            const palIndex = data[i];
            const palEntry = this.palette[palIndex] || { r: 0, g: 0, b: 0, a: 255 };
            rgba[i * 4] = palEntry.r;
            rgba[i * 4 + 1] = palEntry.g;
            rgba[i * 4 + 2] = palEntry.b;
            rgba[i * 4 + 3] = palEntry.a;
        }
    }

    // https://github.com/lmichaelis/phoenix-libsquish/blob/master/squish.cpp

    decodeDXT1(data, width, height) {
        const rgba = new Uint8Array(width * height * 4);
        const blocksX = Math.max(1, Math.floor((width + 3) / 4));
        const blocksY = Math.max(1, Math.floor((height + 3) / 4));

        for (let by = 0; by < blocksY; by++) {
            for (let bx = 0; bx < blocksX; bx++) {
                const blockOffset = (by * blocksX + bx) * 8;
                if (blockOffset + 7 >= data.length) continue;

                const color0 = (data[blockOffset + 1] << 8) | data[blockOffset];
                const color1 = (data[blockOffset + 3] << 8) | data[blockOffset + 2];
                const colors = this.getDXT1Colors(color0, color1);
                const indices = (data[blockOffset + 7] << 24) | (data[blockOffset + 6] << 16) |
                    (data[blockOffset + 5] << 8) | data[blockOffset + 4];

                for (let py = 0; py < 4; py++) {
                    for (let px = 0; px < 4; px++) {
                        const x = bx * 4 + px;
                        const y = by * 4 + py;
                        if (x >= width || y >= height) continue;

                        const bitIndex = (py * 4 + px) * 2;
                        const colorIndex = (indices >> bitIndex) & 0x3;
                        const color = colors[colorIndex];
                        const pixelIndex = (y * width + x) * 4;

                        rgba[pixelIndex] = color.r;
                        rgba[pixelIndex + 1] = color.g;
                        rgba[pixelIndex + 2] = color.b;
                        rgba[pixelIndex + 3] = color.a;
                    }
                }
            }
        }
        return rgba;
    }

    decodeDXT3(data, width, height) {
        const rgba = new Uint8Array(width * height * 4);
        const blocksX = Math.max(1, Math.floor((width + 3) / 4));
        const blocksY = Math.max(1, Math.floor((height + 3) / 4));

        for (let by = 0; by < blocksY; by++) {
            for (let bx = 0; bx < blocksX; bx++) {
                const blockOffset = (by * blocksX + bx) * 16;
                if (blockOffset + 15 >= data.length) continue;

                // Read alpha block (first 8 bytes)
                const alphaBlock = [];
                for (let i = 0; i < 8; i++) {
                    alphaBlock.push(data[blockOffset + i]);
                }

                // Read color block (last 8 bytes) 
                const color0 = (data[blockOffset + 9] << 8) | data[blockOffset + 8];
                const color1 = (data[blockOffset + 11] << 8) | data[blockOffset + 10];
                const colors = this.getDXT1Colors(color0, color1);
                const indices = (data[blockOffset + 15] << 24) | (data[blockOffset + 14] << 16) |
                    (data[blockOffset + 13] << 8) | data[blockOffset + 12];

                for (let py = 0; py < 4; py++) {
                    for (let px = 0; px < 4; px++) {
                        const x = bx * 4 + px;
                        const y = by * 4 + py;
                        if (x >= width || y >= height) continue;

                        // Get color
                        const bitIndex = (py * 4 + px) * 2;
                        const colorIndex = (indices >> bitIndex) & 0x3;
                        const color = colors[colorIndex];

                        // Get alpha (4 bits per pixel)
                        const alphaIndex = py * 4 + px;
                        const alphaByte = alphaBlock[Math.floor(alphaIndex / 2)];
                        const alpha4 = (alphaIndex % 2 === 0) ?
                            (alphaByte & 0x0F) : ((alphaByte >> 4) & 0x0F);
                        const alpha = alpha4 * 17; // 4-bit to 8-bit

                        const pixelIndex = (y * width + x) * 4;
                        rgba[pixelIndex] = color.r;
                        rgba[pixelIndex + 1] = color.g;
                        rgba[pixelIndex + 2] = color.b;
                        rgba[pixelIndex + 3] = alpha;
                    }
                }
            }
        }
        return rgba;
    }

    decodeDXT5(data, width, height) {
        const rgba = new Uint8Array(width * height * 4);
        const blocksX = Math.max(1, Math.floor((width + 3) / 4));
        const blocksY = Math.max(1, Math.floor((height + 3) / 4));

        for (let by = 0; by < blocksY; by++) {
            for (let bx = 0; bx < blocksX; bx++) {
                const blockOffset = (by * blocksX + bx) * 16;
                if (blockOffset + 15 >= data.length) continue;

                // Read alpha block
                const alpha0 = data[blockOffset];
                const alpha1 = data[blockOffset + 1];
                const alphas = this.getDXT5Alphas(alpha0, alpha1);

                // Read alpha indices (6 bytes, 48 bits total, 3 bits per pixel)
                let alphaIndices = 0;
                for (let i = 0; i < 6; i++) {
                    alphaIndices |= (data[blockOffset + 2 + i] << (i * 8));
                }

                // Read color block
                const color0 = (data[blockOffset + 9] << 8) | data[blockOffset + 8];
                const color1 = (data[blockOffset + 11] << 8) | data[blockOffset + 10];
                const colors = this.getDXT1Colors(color0, color1);
                const indices = (data[blockOffset + 15] << 24) | (data[blockOffset + 14] << 16) |
                    (data[blockOffset + 13] << 8) | data[blockOffset + 12];

                for (let py = 0; py < 4; py++) {
                    for (let px = 0; px < 4; px++) {
                        const x = bx * 4 + px;
                        const y = by * 4 + py;
                        if (x >= width || y >= height) continue;

                        // Get color
                        const bitIndex = (py * 4 + px) * 2;
                        const colorIndex = (indices >> bitIndex) & 0x3;
                        const color = colors[colorIndex];

                        // Get alpha (3 bits per pixel)
                        const alphaPixelIndex = py * 4 + px;
                        const alphaBitIndex = alphaPixelIndex * 3;
                        const alphaIndex = (alphaIndices >> alphaBitIndex) & 0x7;
                        const alpha = alphas[alphaIndex];

                        const pixelIndex = (y * width + x) * 4;
                        rgba[pixelIndex] = color.r;
                        rgba[pixelIndex + 1] = color.g;
                        rgba[pixelIndex + 2] = color.b;
                        rgba[pixelIndex + 3] = alpha;
                    }
                }
            }
        }
        return rgba;
    }

    getDXT1Colors(color0, color1) {
        const colors = [];
        colors[0] = {
            r: Math.floor(((color0 >> 11) & 0x1F) * 255 / 31),
            g: Math.floor(((color0 >> 5) & 0x3F) * 255 / 63),
            b: Math.floor((color0 & 0x1F) * 255 / 31),
            a: 255
        };
        colors[1] = {
            r: Math.floor(((color1 >> 11) & 0x1F) * 255 / 31),
            g: Math.floor(((color1 >> 5) & 0x3F) * 255 / 63),
            b: Math.floor((color1 & 0x1F) * 255 / 31),
            a: 255
        };

        if (color0 > color1) {
            colors[2] = {
                r: Math.floor((2 * colors[0].r + colors[1].r) / 3),
                g: Math.floor((2 * colors[0].g + colors[1].g) / 3),
                b: Math.floor((2 * colors[0].b + colors[1].b) / 3),
                a: 255
            };
            colors[3] = {
                r: Math.floor((colors[0].r + 2 * colors[1].r) / 3),
                g: Math.floor((colors[0].g + 2 * colors[1].g) / 3),
                b: Math.floor((colors[0].b + 2 * colors[1].b) / 3),
                a: 255
            };
        } else {
            colors[2] = {
                r: Math.floor((colors[0].r + colors[1].r) / 2),
                g: Math.floor((colors[0].g + colors[1].g) / 2),
                b: Math.floor((colors[0].b + colors[1].b) / 2),
                a: 255
            };
            colors[3] = { r: 0, g: 0, b: 0, a: 0 };
        }
        return colors;
    }

    getDXT5Alphas(alpha0, alpha1) {
        const alphas = [];
        alphas[0] = alpha0;
        alphas[1] = alpha1;

        if (alpha0 > alpha1) {
            // 6 interpolated alpha values
            for (let i = 1; i <= 6; i++) {
                alphas[i + 1] = Math.floor(((6 - i) * alpha0 + i * alpha1) / 6);
            }
        } else {
            // 4 interpolated alpha values + 0 and 255
            for (let i = 1; i <= 4; i++) {
                alphas[i + 1] = Math.floor(((4 - i) * alpha0 + i * alpha1) / 4);
            }
            alphas[6] = 0;
            alphas[7] = 255;
        }

        return alphas;
    }
}