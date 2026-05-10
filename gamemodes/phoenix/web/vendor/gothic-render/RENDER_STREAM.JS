class Stream {
    constructor(buffer) {
        this.buffer = buffer;
        this.view = new DataView(buffer);
        this.position = 0;
    }

    readLine(skipws = false) {
        const whitespace = skipws ? new Set([32, 9, 13, 10, 11, 12]) : new Set();
        let result = '';
        let skipped = false;

        while (this.tell() < this.buffer.byteLength) {
            const byte = this.view.getUint8(this.tell());
            this.seek(1, 'relative');

            if (!skipped && skipws && whitespace.has(byte)) continue;
            skipped = true;

            if (byte === 10 || byte === 13) break;
            if (byte >= 32 && byte <= 126) result += String.fromCharCode(byte);
        }
        return result.trim();
    }

    readUInt8() {
        if (this.position >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position} >= ${this.buffer.byteLength}`);
        }
        return this.view.getUint8(this.position++);
    }

    readInt8() {
        if (this.position >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position} >= ${this.buffer.byteLength}`);
        }
        return this.view.getInt8(this.position++);
    }

    readUInt16() {
        if (this.position + 1 >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position + 1} >= ${this.buffer.byteLength}`);
        }
        const value = this.view.getUint16(this.position, true);
        this.position += 2;
        return value;
    }

    readInt16() {
        if (this.position + 1 >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position + 1} >= ${this.buffer.byteLength}`);
        }
        const value = this.view.getInt16(this.position, true);
        this.position += 2;
        return value;
    }

    readUInt32() {
        if (this.position + 3 >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position + 3} >= ${this.buffer.byteLength}`);
        }
        const value = this.view.getUint32(this.position, true);
        this.position += 4;
        return value;
    }

    readInt32() {
        if (this.position + 3 >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position + 3} >= ${this.buffer.byteLength}`);
        }
        const value = this.view.getInt32(this.position, true);
        this.position += 4;
        return value;
    }

    readFloat32() {
        if (this.position + 3 >= this.buffer.byteLength) {
            throw new RangeError(`Buffer underrun: ${this.position + 3} >= ${this.buffer.byteLength}`);
        }
        const value = this.view.getFloat32(this.position, true);
        this.position += 4;
        return value;
    }

    readVec2() {
        return { x: this.readFloat32(), y: this.readFloat32() };
    }

    readVec3() {
        return { x: this.readFloat32(), y: this.readFloat32(), z: this.readFloat32() };
    }

    readString(length) {
        const bytes = new Uint8Array(this.buffer, this.position, length);
        this.position += length;
        return new TextDecoder().decode(bytes);
    }

    seek(offset, whence = 'absolute') {
        switch (whence) {
            case 'absolute': this.position = offset; break;
            case 'relative': this.position += offset; break;
            case 'end': this.position = this.buffer.byteLength + offset; break;
        }
    }

    tell() { return this.position; }
    eof() { return this.position >= this.buffer.byteLength; }
}